import 'dart:async';
import 'dart:isolate';

import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate_messages/exception.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class SaneIsolate {
  SaneIsolate._(
    this._isolate,
    this._sendPort,
    this._exitReceivePort,
  ) : _exited = false {
    _exitReceivePort.listen((message) {
      assert(message == null);
      _exited = true;
    });
  }

  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _exitReceivePort;

  bool _exited;

  bool get exited => _exited;

  static Future<SaneIsolate> spawn(Sane sane) async {
    final receivePort = ReceivePort();
    final exitReceivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _entryPoint,
      (receivePort.sendPort, sane),
      onExit: exitReceivePort.sendPort,
    );

    final sendPort = await receivePort.first as SendPort;
    return SaneIsolate._(isolate, sendPort, exitReceivePort);
  }

  void kill() {
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<T> sendMessage<T extends IsolateResponse>(
    IsolateMessage<T> message,
  ) async {
    final replyPort = ReceivePort();

    _sendPort.send(
      _IsolateMessageEnvelope(
        replyPort: replyPort.sendPort,
        message: message,
      ),
    );

    final response = await replyPort.first;
    replyPort.close();

    if (response is ExceptionResponse) {
      Error.throwWithStackTrace(
        response.exception,
        response.stackTrace,
      );
    }

    return response as T;
  }
}

typedef _EntryPointArgs = (SendPort sendPort, Sane sane);

void _entryPoint(_EntryPointArgs args) {
  final (sendPort, sane) = args;

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.cast<_IsolateMessageEnvelope>().listen((envelope) async {
    final _IsolateMessageEnvelope(:message, :replyPort) = envelope;

    IsolateResponse response;

    try {
      response = await message.handle(sane);
    } on SaneException catch (exception, stackTrace) {
      response = ExceptionResponse(
        exception: exception,
        stackTrace: stackTrace,
      );
    }

    replyPort.send(response);
  });
}

class _IsolateMessageEnvelope {
  _IsolateMessageEnvelope({
    required this.replyPort,
    required this.message,
  });

  final SendPort replyPort;
  final IsolateMessage message;
}

late Map<String, SaneDevice> _devices;

SaneDevice getDevice(String name) => _devices[name]!;

void setDevices(Iterable<SaneDevice> devices) {
  _devices = {
    for (final device in devices) device.name: device,
  };
}
