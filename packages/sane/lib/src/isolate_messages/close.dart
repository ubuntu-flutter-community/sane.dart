import 'package:sane/sane.dart';
import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class CloseMessage implements IsolateMessage {
  const CloseMessage(this.deviceName);

  final String deviceName;

  @override
  Future<CloseResponse> handle(Sane sane) async {
    await getDevice(deviceName).close();
    return CloseResponse();
  }
}

class CloseResponse implements IsolateResponse {}
