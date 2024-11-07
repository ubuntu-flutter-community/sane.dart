import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetParametersMessage implements IsolateMessage<GetParametersResponse> {
  const GetParametersMessage(this.deviceName);

  final String deviceName;

  @override
  Future<GetParametersResponse> handle(Sane sane) async {
    final device = getDevice(deviceName);
    final parameters = await device.getParameters();
    return GetParametersResponse(parameters);
  }
}

class GetParametersResponse implements IsolateResponse {
  GetParametersResponse(this.parameters);

  final SaneParameters parameters;
}
