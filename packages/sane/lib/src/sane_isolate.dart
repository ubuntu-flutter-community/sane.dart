import 'dart:isolate';
import 'dart:typed_data';

import 'package:sane/sane.dart';
import 'package:sane/src/isolate_messages/cancel.dart';
import 'package:sane/src/isolate_messages/close.dart';
import 'package:sane/src/isolate_messages/control_button_option.dart';
import 'package:sane/src/isolate_messages/control_option.dart';
import 'package:sane/src/isolate_messages/exception.dart';
import 'package:sane/src/isolate_messages/exit.dart';
import 'package:sane/src/isolate_messages/get_all_option_descriptors.dart';
import 'package:sane/src/isolate_messages/get_devices.dart';
import 'package:sane/src/isolate_messages/get_option_descriptor.dart';
import 'package:sane/src/isolate_messages/get_parameters.dart';
import 'package:sane/src/isolate_messages/init.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/isolate_messages/open.dart';
import 'package:sane/src/isolate_messages/read.dart';
import 'package:sane/src/isolate_messages/set_io_mode.dart';
import 'package:sane/src/isolate_messages/start.dart';

class SaneIsolate implements Sane {
  SaneIsolate({
    required Sane sane,
  }) : _sane = sane;

  final Sane _sane;

  late final Isolate _isolate;
  late final SendPort _sendPort;

  Future<void> spawn() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _IsolateEntryPointArgs(
        mainSendPort: receivePort.sendPort,
        sane: _sane,
      ),
    );
    _sendPort = await receivePort.first as SendPort;
  }

  void kill() {
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<T> _sendMessage<T extends IsolateResponse>(
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

  @override
  Future<int> init({
    AuthCallback? authCallback,
  }) async {
    final response = await _sendMessage(InitMessage());
    return response.versionCode;
  }

  @override
  Future<void> exit() async {
    await _sendMessage(ExitMessage());
  }

  @override
  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) async {
    final response = await _sendMessage(
      GetDevicesMessage(localOnly: localOnly),
    );

    return response.devices;
  }

  @override
  Future<SaneHandle> open(String deviceName) async {
    final response = await _sendMessage(
      OpenMessage(deviceName: deviceName),
    );

    return response.handle;
  }

  @override
  Future<SaneHandle> openDevice(SaneDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SaneHandle handle) async {
    await _sendMessage(
      CloseMessage(saneHandle: handle),
    );
  }

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) async {
    final response = await _sendMessage(
      GetOptionDescriptorMessage(
        saneHandle: handle,
        index: index,
      ),
    );

    return response.optionDescriptor;
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) async {
    final response = await _sendMessage(
      GetAllOptionDescriptorsMessage(saneHandle: handle),
    );

    return response.optionDescriptors;
  }

  @override
  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) async {
    final response = await _sendMessage(
      ControlValueOptionMessage<bool>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) async {
    final response = await _sendMessage(
      ControlValueOptionMessage<int>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) async {
    final response = await _sendMessage(
      ControlValueOptionMessage<double>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) async {
    final response = await _sendMessage(
      ControlValueOptionMessage<String>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    final response = await _sendMessage(
      ControlButtonOptionMessage(
        saneHandle: handle,
        index: index,
      ),
    );

    return response.result;
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final response = await _sendMessage(
      GetParametersMessage(
        saneHandle: handle,
      ),
    );

    return response.parameters;
  }

  @override
  Future<void> start(SaneHandle handle) async {
    await _sendMessage(
      StartMessage(saneHandle: handle),
    );
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final response = await _sendMessage(
      ReadMessage(
        saneHandle: handle,
        bufferSize: bufferSize,
      ),
    );

    return response.bytes;
  }

  @override
  Future<void> cancel(SaneHandle handle) async {
    await _sendMessage(
      CancelMessage(saneHandle: handle),
    );
  }

  @override
  Future<void> setIOMode(
    SaneHandle handle,
    SaneIOMode ioMode,
  ) async {
    await _sendMessage(
      SetIOModeMessage(saneHandle: handle, ioMode: ioMode),
    );
  }
}

class _IsolateEntryPointArgs {
  _IsolateEntryPointArgs({
    required this.mainSendPort,
    required this.sane,
  });

  final SendPort mainSendPort;
  final Sane sane;
}

void _isolateEntryPoint(_IsolateEntryPointArgs args) {
  final isolateReceivePort = ReceivePort();
  args.mainSendPort.send(isolateReceivePort.sendPort);

  final sane = args.sane;
  isolateReceivePort.cast<_IsolateMessageEnvelope>().listen((envelope) async {
    late IsolateResponse response;

    try {
      response = await envelope.message.handle(sane);
    } on SaneException catch (exception, stackTrace) {
      response = ExceptionResponse(
        exception: exception,
        stackTrace: stackTrace,
      );
    }

    envelope.replyPort.send(response);
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
