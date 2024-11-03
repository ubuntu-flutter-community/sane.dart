import 'dart:isolate';
import 'dart:typed_data';

import 'package:sane/sane.dart';

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
        ));
    print('Spawn SaneIsolate');
    _sendPort = await receivePort.first as SendPort;
  }

  void kill() {
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<dynamic> _sendMessage(_SaneIsolateMessage message) async {
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
    final response =
        await _sendMessage(_SaneInitMessage()) as _SaneInitResponse;
    return response.versionCode;
  }

  @override
  Future<void> exit() async {
    await _sendMessage(_SaneExitMessage());
  }

  @override
  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) async {
    final response = await _sendMessage(
      _SaneGetDevicesMessage(
        localOnly: localOnly,
      ),
    ) as _SaneGetDevicesResponse;

    return response.devices;
  }

  @override
  Future<SaneHandle> open(String deviceName) async {
    final response = await _sendMessage(
      _SaneOpenMessage(
        deviceName: deviceName,
      ),
    ) as _SaneOpenResponse;

    return response.handle;
  }

  @override
  Future<SaneHandle> openDevice(SaneDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SaneHandle handle) async {
    await _sendMessage(
      _SaneCloseMessage(
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
      _SaneGetOptionDescriptorMessage(
        handle: handle,
        index: index,
      ),
    ) as _SaneGetOptionDescriptorResponse;

    return response.optionDescriptor;
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) async {
    final response = await _sendMessage(
      _SaneGetAllOptionDescriptorsMessage(
        handle: handle,
      ),
    ) as _SaneGetAllOptionDescriptorsResponse;

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
      _SaneControlOptionMessage<bool>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as _SaneControlOptionResponse<bool>;

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
      _SaneControlOptionMessage<int>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as _SaneControlOptionResponse<int>;

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
      _SaneControlOptionMessage<double>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as _SaneControlOptionResponse<double>;

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
      _SaneControlOptionMessage<String>(
        handle: handle,
        index: index,
        action: action,
        value: value,
      ),
    ) as _SaneControlOptionResponse<String>;

    return response.result;
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    final response = await _sendMessage(
      _SaneControlButtonOptionMessage(
        handle: handle,
        index: index,
      ),
    ) as _SaneControlButtonOptionResponse;

    return response.result;
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final response = await _sendMessage(
      _SaneGetParametersMessage(
        handle: handle,
      ),
    ) as _SaneGetParametersResponse;

    return response.parameters;
  }

  @override
  Future<void> start(SaneHandle handle) async {
    await _sendMessage(
      _SaneStartMessage(
        handle: handle,
      ),
    );
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final response = await _sendMessage(
      _SaneReadMessage(
        handle: handle,
        bufferSize: bufferSize,
      ),
    ) as _SaneReadResponse;

    return response.bytes;
  }

  @override
  Future<void> cancel(SaneHandle handle) async {
    await _sendMessage(
      _SaneCancelMessage(
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
      _SaneSetIOModeMessage(handle: handle, ioMode: ioMode),
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

  final messageHandler = _SaneMessageHandler(sane: args.sane);
  isolateReceivePort.listen((envellope) async {
    envellope = envellope as _IsolateMessageEnveloppe;

    envellope.replyPort.send(
      await messageHandler.handleMessage(envellope.message),
    );
  });
}

interface class _SaneIsolateMessage {}

interface class _SaneIsolateResponse {}

class _IsolateMessageEnveloppe {
  _IsolateMessageEnveloppe({
    required this.replyPort,
    required this.message,
  });

  final SendPort replyPort;
  final _SaneIsolateMessage message;
}

class _SaneMessageHandler {
  _SaneMessageHandler({required Sane sane}) : _sane = sane;

  final Sane _sane;

  Future<_SaneIsolateResponse> handleMessage(
      _SaneIsolateMessage message) async {
    switch (message) {
      case _SaneInitMessage _:
        return await _handleSaneInitMessage();

      case _SaneExitMessage _:
        return await _handleSaneExitMessage();

      case _SaneGetDevicesMessage message:
        return await _handleSaneGetDevicesMessages(message);

      case _SaneOpenMessage message:
        return await _handleSaneOpenMessage(message);

      case _SaneCloseMessage message:
        return await _handleSaneCloseMessage(message);

      case _SaneGetOptionDescriptorMessage message:
        return await _handleSaneGetOptionDescriptorMessage(message);

      case _SaneGetAllOptionDescriptorsMessage message:
        return await _handleSaneGetAllOptionDescriptorsMessage(message);

      case _SaneControlOptionMessage<bool> message:
        return await _handleSaneControlBoolOptionMessage(message);

      case _SaneControlOptionMessage<int> message:
        return await _handleSaneControlIntOptionMessage(message);

      case _SaneControlOptionMessage<double> message:
        return await _handleSaneControlFixedOptionMessage(message);

      case _SaneControlOptionMessage<String> message:
        return await _handleSaneControlStringOptionMessage(message);

      case _SaneControlButtonOptionMessage message:
        return await _handleSaneControlButtonOptionMessage(message);

      case _SaneGetParametersMessage message:
        return await _handleSaneGetParametersMessage(message);

      case _SaneStartMessage message:
        return await _handleSaneStartMessage(message);

      case _SaneReadMessage message:
        return await _handleSaneReadMessage(message);

      case _SaneCancelMessage message:
        return await _handleSaneCancelMessage(message);

      case _SaneSetIOModeMessage message:
        return await _handleSaneSetIOModeMessage(message);

      default:
        throw Exception('No handler for this message.');
    }
  }

  Future<_SaneInitResponse> _handleSaneInitMessage() async {
    return _SaneInitResponse(
      versionCode: await _sane.init(),
    );
  }

  Future<_SaneExitResponse> _handleSaneExitMessage() async {
    await _sane.exit();
    return _SaneExitResponse();
  }

  Future<_SaneGetDevicesResponse> _handleSaneGetDevicesMessages(
    _SaneGetDevicesMessage message,
  ) async {
    return _SaneGetDevicesResponse(
      devices: await _sane.getDevices(
        localOnly: message.localOnly,
      ),
    );
  }

  Future<_SaneOpenResponse> _handleSaneOpenMessage(
    _SaneOpenMessage message,
  ) async {
    return _SaneOpenResponse(
      handle: await _sane.open(
        message.deviceName,
      ),
    );
  }

  Future<_SaneCloseResponse> _handleSaneCloseMessage(
    _SaneCloseMessage message,
  ) async {
    await _sane.close(message.handle);
    return _SaneCloseResponse();
  }

  Future<_SaneGetOptionDescriptorResponse>
      _handleSaneGetOptionDescriptorMessage(
    _SaneGetOptionDescriptorMessage message,
  ) async {
    return _SaneGetOptionDescriptorResponse(
      optionDescriptor: await _sane.getOptionDescriptor(
        message.handle,
        message.index,
      ),
    );
  }

  Future<_SaneGetAllOptionDescriptorsResponse>
      _handleSaneGetAllOptionDescriptorsMessage(
    _SaneGetAllOptionDescriptorsMessage message,
  ) async {
    return _SaneGetAllOptionDescriptorsResponse(
      optionDescriptors: await _sane.getAllOptionDescriptors(
        message.handle,
      ),
    );
  }

  Future<_SaneControlOptionResponse<bool>> _handleSaneControlBoolOptionMessage(
    _SaneControlOptionMessage<bool> message,
  ) async {
    return _SaneControlOptionResponse<bool>(
      result: await _sane.controlBoolOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<_SaneControlOptionResponse<int>> _handleSaneControlIntOptionMessage(
    _SaneControlOptionMessage<int> message,
  ) async {
    return _SaneControlOptionResponse<int>(
      result: await _sane.controlIntOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<_SaneControlOptionResponse<double>>
      _handleSaneControlFixedOptionMessage(
    _SaneControlOptionMessage<double> message,
  ) async {
    return _SaneControlOptionResponse<double>(
      result: await _sane.controlFixedOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<_SaneControlOptionResponse<String>>
      _handleSaneControlStringOptionMessage(
    _SaneControlOptionMessage<String> message,
  ) async {
    return _SaneControlOptionResponse<String>(
      result: await _sane.controlStringOption(
        handle: message.handle,
        index: message.index,
        action: message.action,
        value: message.value,
      ),
    );
  }

  Future<_SaneControlButtonOptionResponse>
      _handleSaneControlButtonOptionMessage(
    _SaneControlButtonOptionMessage message,
  ) async {
    return _SaneControlButtonOptionResponse(
      result: await _sane.controlButtonOption(
        handle: message.handle,
        index: message.index,
      ),
    );
  }

  Future<_SaneGetParametersResponse> _handleSaneGetParametersMessage(
    _SaneGetParametersMessage message,
  ) async {
    return _SaneGetParametersResponse(
      parameters: await _sane.getParameters(
        message.handle,
      ),
    );
  }

  Future<_SaneStartResponse> _handleSaneStartMessage(
    _SaneStartMessage message,
  ) async {
    await _sane.start(message.handle);
    return _SaneStartResponse();
  }

  Future<_SaneReadResponse> _handleSaneReadMessage(
    _SaneReadMessage message,
  ) async {
    return _SaneReadResponse(
      bytes: await _sane.read(
        message.handle,
        message.bufferSize,
      ),
    );
  }

  Future<_SaneCancelResponse> _handleSaneCancelMessage(
    _SaneCancelMessage message,
  ) async {
    await _sane.cancel(message.handle);
    return _SaneCancelResponse();
  }

  Future<_SaneSetIOModeResponse> _handleSaneSetIOModeMessage(
    _SaneSetIOModeMessage message,
  ) async {
    await _sane.setIOMode(
      message.handle,
      message.ioMode,
    );
    return _SaneSetIOModeResponse();
  }
}

// INIT

class _SaneInitMessage implements _SaneIsolateMessage {}

class _SaneInitResponse implements _SaneIsolateResponse {
  _SaneInitResponse({required this.versionCode});
  final int versionCode;
}

// EXIT

class _SaneExitMessage implements _SaneIsolateMessage {}

class _SaneExitResponse implements _SaneIsolateResponse {}

// GET DEVICES

class _SaneGetDevicesMessage implements _SaneIsolateMessage {
  _SaneGetDevicesMessage({required this.localOnly});
  final bool localOnly;
}

class _SaneGetDevicesResponse implements _SaneIsolateResponse {
  _SaneGetDevicesResponse({required this.devices});
  final List<SaneDevice> devices;
}

// OPEN

class _SaneOpenMessage implements _SaneIsolateMessage {
  _SaneOpenMessage({required this.deviceName});
  final String deviceName;
}

class _SaneOpenResponse implements _SaneIsolateResponse {
  _SaneOpenResponse({required this.handle});
  final SaneHandle handle;
}

// CLOSE

class _SaneCloseMessage implements _SaneIsolateMessage {
  _SaneCloseMessage({required this.handle});
  final SaneHandle handle;
}

class _SaneCloseResponse implements _SaneIsolateResponse {}

// GET OPTION DESCRIPTOR

class _SaneGetOptionDescriptorMessage implements _SaneIsolateMessage {
  _SaneGetOptionDescriptorMessage({
    required this.handle,
    required this.index,
  });
  final SaneHandle handle;
  final int index;
}

class _SaneGetOptionDescriptorResponse implements _SaneIsolateResponse {
  _SaneGetOptionDescriptorResponse({required this.optionDescriptor});
  final SaneOptionDescriptor optionDescriptor;
}

// GET ALL OPTION DESCRIPTOR

class _SaneGetAllOptionDescriptorsMessage implements _SaneIsolateMessage {
  _SaneGetAllOptionDescriptorsMessage({required this.handle});
  final SaneHandle handle;
}

class _SaneGetAllOptionDescriptorsResponse implements _SaneIsolateResponse {
  _SaneGetAllOptionDescriptorsResponse({required this.optionDescriptors});
  final List<SaneOptionDescriptor> optionDescriptors;
}

// CONTROL OPTION

class _SaneControlOptionMessage<T> implements _SaneIsolateMessage {
  _SaneControlOptionMessage({
    required this.handle,
    required this.index,
    required this.action,
    this.value,
  });
  final SaneHandle handle;
  final int index;
  final SaneAction action;
  final T? value;
}

class _SaneControlOptionResponse<T> implements _SaneIsolateResponse {
  _SaneControlOptionResponse({required this.result});
  final SaneOptionResult<T> result;
}

// CONTROL BUTTON OPTION

class _SaneControlButtonOptionMessage implements _SaneIsolateMessage {
  _SaneControlButtonOptionMessage({
    required this.handle,
    required this.index,
  });
  final SaneHandle handle;
  final int index;
}

class _SaneControlButtonOptionResponse implements _SaneIsolateResponse {
  _SaneControlButtonOptionResponse({required this.result});
  final SaneOptionResult<Null> result;
}

// GET PARAMETERS

class _SaneGetParametersMessage implements _SaneIsolateMessage {
  _SaneGetParametersMessage({required this.handle});
  final SaneHandle handle;
}

class _SaneGetParametersResponse implements _SaneIsolateResponse {
  _SaneGetParametersResponse({required this.parameters});
  final SaneParameters parameters;
}

// START

class _SaneStartMessage implements _SaneIsolateMessage {
  _SaneStartMessage({required this.handle});
  final SaneHandle handle;
}

class _SaneStartResponse implements _SaneIsolateResponse {}

// READ

class _SaneReadMessage implements _SaneIsolateMessage {
  _SaneReadMessage({
    required this.handle,
    required this.bufferSize,
  });
  final SaneHandle handle;
  final int bufferSize;
}

class _SaneReadResponse implements _SaneIsolateResponse {
  _SaneReadResponse({
    required this.bytes,
  });
  final Uint8List bytes;
}

// CANCEL

class _SaneCancelMessage implements _SaneIsolateMessage {
  _SaneCancelMessage({required this.handle});
  final SaneHandle handle;
}

class _SaneCancelResponse implements _SaneIsolateResponse {}

// SET IO MODE

class _SaneSetIOModeMessage implements _SaneIsolateMessage {
  _SaneSetIOModeMessage({
    required this.handle,
    required this.ioMode,
  });
  final SaneHandle handle;
  final SaneIOMode ioMode;
}

class _SaneSetIOModeResponse implements _SaneIsolateResponse {}
