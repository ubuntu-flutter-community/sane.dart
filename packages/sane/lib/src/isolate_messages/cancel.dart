import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class CancelMessage implements IsolateMessage {
  CancelMessage(this.deviceName);

  final String deviceName;

  @override
  Future<CancelResponse> handle(Sane sane) async {
    await getDevice(deviceName).cancel();
    return CancelResponse();
  }
}

class CancelResponse implements IsolateResponse {}
