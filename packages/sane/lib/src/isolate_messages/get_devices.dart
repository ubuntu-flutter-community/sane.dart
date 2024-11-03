import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class GetDevicesMessage implements IsolateMessage {
  GetDevicesMessage({required this.localOnly});

  final bool localOnly;
}

class GetDevicesResponse implements IsolateResponse {
  GetDevicesResponse({required this.devices});

  final List<SaneDevice> devices;
}
