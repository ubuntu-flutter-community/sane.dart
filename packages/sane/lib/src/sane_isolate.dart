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
        handle: handle,
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
        handle: handle,
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
        handle: handle,
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
      ControlOptionMessage<bool>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as ControlOptionResponse<bool>;

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
      ControlOptionMessage<int>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as ControlOptionResponse<int>;

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
      ControlOptionMessage<double>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as ControlOptionResponse<double>;

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
      ControlOptionMessage<String>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as ControlOptionResponse<String>;

    return response.result;
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    final response = await _sendMessage(
      ControlButtonOptionMessage(
        handle: handle,
        index: index,
      ),
    ) as ControlButtonOptionResponse;

    return response.result;
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final response = await _sendMessage(
      GetParametersMessage(
        handle: handle,
      ),
    ) as GetParametersResponse;

    return response.parameters;
  }

  @override
  Future<void> start(SaneHandle handle) async {
    await _sendMessage(
      StartMessage(
        handle: handle,
      ),
    );
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final response = await _sendMessage(
      ReadMessage(
        handle: handle,
        bufferSize: bufferSize,
      ),
    ) as ReadResponse;

    return response.bytes;
  }

  @override
  Future<void> cancel(SaneHandle handle) async {
    await _sendMessage(
      CancelMessage(
        handle: handle,
      ),
    );
  }

  @override
  Future<void> setIOMode(
    SaneHandle handle,
    SaneIOMode ioMode,
  ) async {
    await _sendMessage(
      SetIOModeMessage(handle: handle, ioMode: ioMode),
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

  final messageHandler = MessageHandler(sane: args.sane);
  isolateReceivePort.listen((envellope) async {
    envellope = envellope as _IsolateMessageEnveloppe;

    envellope.replyPort.send(
      await messageHandler.handleMessage(envellope.message),
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

class MessageHandler {
  MessageHandler({required Sane sane}) : _sane = sane;

  final Sane _sane;

  Future<IsolateResponse> handleMessage(IsolateMessage message,
  ) async {
    switch (message) {
      case InitMessage _:
        return await _handleSaneInitMessage();

      case ExitMessage _:
        return await _handleSaneExitMessage();

      case final GetDevicesMessage message:
        return await _handleSaneGetDevicesMessages(message);

      case final OpenMessage message:
        return await _handleSaneOpenMessage(message);

      case final CloseMessage message:
        return await _handleSaneCloseMessage(message);

      case final GetOptionDescriptorMessage message:
        return await _handleSaneGetOptionDescriptorMessage(message);

      case final GetAllOptionDescriptorsMessage message:
        return await _handleSaneGetAllOptionDescriptorsMessage(message);

      case final ControlOptionMessage<bool> message:
        return await _handleSaneControlBoolOptionMessage(message);

      case final ControlOptionMessage<int> message:
        return await _handleSaneControlIntOptionMessage(message);

      case final ControlOptionMessage<double> message:
        return await _handleSaneControlFixedOptionMessage(message);

      case final ControlOptionMessage<String> message:
        return await _handleSaneControlStringOptionMessage(message);

      case final ControlButtonOptionMessage message:
        return await _handleSaneControlButtonOptionMessage(message);

      case final GetParametersMessage message:
        return await _handleSaneGetParametersMessage(message);

      case final StartMessage message:
        return await _handleSaneStartMessage(message);

      case final ReadMessage message:
        return await _handleSaneReadMessage(message);

      case final CancelMessage message:
        return await _handleSaneCancelMessage(message);

      case final SetIOModeMessage message:
        return await _handleSaneSetIOModeMessage(message);

      default:
        throw Exception('No handler for this message.');
    }
  }

  Future<InitResponse> _handleSaneInitMessage() async {
    return InitResponse(
      versionCode: await _sane.init(),
    );
  }

  Future<ExitResponse> _handleSaneExitMessage() async {
    await _sane.exit();
    return ExitResponse();
  }

  Future<GetDevicesResponse> _handleSaneGetDevicesMessages(
    GetDevicesMessage message,
  ) async {
    return GetDevicesResponse(
      devices: await _sane.getDevices(
        localOnly: message.localOnly,
      ),
    );
  }

  Future<OpenResponse> _handleSaneOpenMessage(
    OpenMessage message,
  ) async {
    return OpenResponse(
      handle: await _sane.open(
        message.deviceName,
      ),
    );
  }

  Future<CloseResponse> _handleSaneCloseMessage(
    CloseMessage message,
  ) async {
    await _sane.close(message.handle);
    return CloseResponse();
  }

  Future<GetOptionDescriptorResponse> _handleSaneGetOptionDescriptorMessage(
    GetOptionDescriptorMessage message,
  ) async {
    return GetOptionDescriptorResponse(
      optionDescriptor: await _sane.getOptionDescriptor(
        message.handle,
        message.index,
      ),
    );
  }

  Future<GetAllOptionDescriptorsResponse>
      _handleSaneGetAllOptionDescriptorsMessage(
    GetAllOptionDescriptorsMessage message,
  ) async {
    return GetAllOptionDescriptorsResponse(
      optionDescriptors: await _sane.getAllOptionDescriptors(
        message.handle,
      ),
    );
  }

  Future<ControlOptionResponse<bool>> _handleSaneControlBoolOptionMessage(
    ControlOptionMessage<bool> message,
  ) async {
    return ControlOptionResponse<bool>(
      result: await _sane.controlBoolOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<ControlOptionResponse<int>> _handleSaneControlIntOptionMessage(
    ControlOptionMessage<int> message,
  ) async {
    return ControlOptionResponse<int>(
      result: await _sane.controlIntOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<ControlOptionResponse<double>> _handleSaneControlFixedOptionMessage(
    ControlOptionMessage<double> message,
  ) async {
    return ControlOptionResponse<double>(
      result: await _sane.controlFixedOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<ControlOptionResponse<String>> _handleSaneControlStringOptionMessage(
    ControlOptionMessage<String> message,
  ) async {
    return ControlOptionResponse<String>(
      result: await _sane.controlStringOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<ControlButtonOptionResponse> _handleSaneControlButtonOptionMessage(
    ControlButtonOptionMessage message,
  ) async {
    return ControlButtonOptionResponse(
      result: await _sane.controlButtonOption(
        handle: message.handle,
        index: message.index,
      ),
    );
  }

  Future<GetParametersResponse> _handleSaneGetParametersMessage(
    GetParametersMessage message,
  ) async {
    return GetParametersResponse(
      parameters: await _sane.getParameters(
        message.handle,
      ),
    );
  }

  Future<StartResponse> _handleSaneStartMessage(
    StartMessage message,
  ) async {
    await _sane.start(message.handle);
    return StartResponse();
  }

  Future<ReadResponse> _handleSaneReadMessage(
    ReadMessage message,
  ) async {
    return ReadResponse(
      bytes: await _sane.read(
        message.handle,
        message.bufferSize,
      ),
    );
  }

  Future<CancelResponse> _handleSaneCancelMessage(
    CancelMessage message,
  ) async {
    await _sane.cancel(message.handle);
    return CancelResponse();
  }

  Future<SetIOModeResponse> _handleSaneSetIOModeMessage(
    SetIOModeMessage message,
  ) async {
    await _sane.setIOMode(
      message.handle,
      message.ioMode,
    );
    return SetIOModeResponse();
  }
}
