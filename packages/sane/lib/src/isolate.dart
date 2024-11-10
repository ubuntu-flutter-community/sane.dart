import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/isolate_messages/exception.dart';
import 'package:sane/src/isolate_messages/exit.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

final _logger = Logger('sane.isolate');

@internal
class SaneIsolate {
  SaneIsolate._(
    this._isolate,
    this._sendPort,
  );

  final Isolate _isolate;
  final SendPort _sendPort;

  static Future<SaneIsolate> spawn(Sane sane) async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _entryPoint,
      (receivePort.sendPort, sane),
      onExit: receivePort.sendPort,
    );

    final sendPortCompleter = Completer<SendPort>();
    receivePort.listen((message) {
      switch (message) {
        case SendPort():
          sendPortCompleter.complete(message);
        case LogRecord():
          _logger.redirect(message);
        case null:
          receivePort.close();
      }
    });

    final sendPort = await sendPortCompleter.future;
    return SaneIsolate._(isolate, sendPort);
  }

  void kill() => _isolate.kill(priority: Isolate.immediate);

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

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.forEach(sendPort.send);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  late StreamSubscription<_IsolateMessageEnvelope> subscription;

  subscription =
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

    if (message is ExitMessage) {
      await subscription.cancel();
    }
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

@internal
SaneDevice getDevice(String name) => _devices[name]!;

@internal
void setDevices(Iterable<SaneDevice> devices) {
  _devices = {
    for (final device in devices) device.name: device,
  };
}
