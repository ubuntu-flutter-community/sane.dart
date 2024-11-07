import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class ControlButtonOptionMessage
    implements IsolateMessage<ControlButtonOptionResponse> {
  const ControlButtonOptionMessage({
    required this.deviceName,
    required this.index,
  });

  final String deviceName;
  final int index;

  @override
  Future<ControlButtonOptionResponse> handle(Sane sane) async {
    final device = getDevice(deviceName);
    final result = await device.controlButtonOption(index);
    return ControlButtonOptionResponse(result);
  }
}

class ControlButtonOptionResponse implements IsolateResponse {
  ControlButtonOptionResponse(this.result);

  final SaneOptionResult<Null> result;
}
