import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class StartMessage implements IsolateMessage {
  const StartMessage(this.deviceName);

  final String deviceName;

  @override
  Future<StartResponse> handle(Sane sane) async {
    getDevice(deviceName).start();
    return StartResponse();
  }
}

class StartResponse implements IsolateResponse {}
