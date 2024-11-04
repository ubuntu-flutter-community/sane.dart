import 'dart:isolate';
import 'dart:typed_data';

import 'package:sane/sane.dart';
import 'package:sane/src/isolate_messages/cancel.dart';
import 'package:sane/src/isolate_messages/close.dart';
import 'package:sane/src/isolate_messages/control_button_option.dart';
import 'package:sane/src/isolate_messages/control_option.dart';
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

  Future<dynamic> _sendMessage(IsolateMessage message) async {
    final replyPort = ReceivePort();

    _sendPort.send(
      _IsolateMessageEnveloppe(
        replyPort: replyPort.sendPort,
        message: message,
      ),
    );

    final response = await replyPort.first;
    replyPort.close();

    return response;
  }

  @override
  Future<int> init({
    AuthCallback? authCallback,
  }) async {
    final response = await _sendMessage(InitMessage()) as InitResponse;
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
      GetDevicesMessage(
        localOnly: localOnly,
      ),
    ) as GetDevicesResponse;

    return response.devices;
  }

  @override
  Future<SaneHandle> open(String deviceName) async {
    final response = await _sendMessage(
      OpenMessage(
        deviceName: deviceName,
      ),
    ) as OpenResponse;

    return response.handle;
  }

  @override
  Future<SaneHandle> openDevice(SaneDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SaneHandle handle) async {
    await _sendMessage(
      CloseMessage(
        saneHandle: handle,
      ),
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
    ) as GetOptionDescriptorResponse;

    return response.optionDescriptor;
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) async {
    final response = await _sendMessage(
      GetAllOptionDescriptorsMessage(
        saneHandle: handle,
      ),
    ) as GetAllOptionDescriptorsResponse;

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
    ) as ControlValueOptionResponse<bool>;

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
    ) as ControlValueOptionResponse<int>;

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
    ) as ControlValueOptionResponse<double>;

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
    ) as ControlValueOptionResponse<String>;

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
    ) as ControlButtonOptionResponse;

    return response.result;
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final response = await _sendMessage(
      GetParametersMessage(
        saneHandle: handle,
      ),
    ) as GetParametersResponse;

    return response.parameters;
  }

  @override
  Future<void> start(SaneHandle handle) async {
    await _sendMessage(
      StartMessage(
        saneHandle: handle,
      ),
    );
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final response = await _sendMessage(
      ReadMessage(
        saneHandle: handle,
        bufferSize: bufferSize,
      ),
    ) as ReadResponse;

    return response.bytes;
  }

  @override
  Future<void> cancel(SaneHandle handle) async {
    await _sendMessage(
      CancelMessage(
        saneHandle: handle,
      ),
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
  isolateReceivePort.listen((envellope) async {
    envellope = envellope as _IsolateMessageEnveloppe;

    envellope.replyPort.send(
      await envellope.message.handle(sane),
    );
  });
}

class _IsolateMessageEnveloppe {
  _IsolateMessageEnveloppe({
    required this.replyPort,
    required this.message,
  });

  final SendPort replyPort;
  final IsolateMessage message;
}
