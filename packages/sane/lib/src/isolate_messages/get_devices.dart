import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class GetDevicesMessage implements IsolateMessage<GetDevicesResponse> {
  GetDevicesMessage({required this.localOnly});

  final bool localOnly;

  @override
  Future<GetDevicesResponse> handle(Sane sane) async {
    final devices = await sane.getDevices(localOnly: localOnly);
    setDevices(devices);
    return GetDevicesResponse(devices);
  }
}

class GetDevicesResponse implements IsolateResponse {
  GetDevicesResponse(this.devices);

  final List<SaneDevice> devices;
}
