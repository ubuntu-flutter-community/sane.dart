import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class OpenMessage implements IsolateMessage {
  OpenMessage({required this.deviceName});

  final String deviceName;

  @override
  Future<OpenResponse> handle(Sane sane) async {
    return OpenResponse(
      handle: await sane.open(deviceName),
    );
  }
}

class OpenResponse implements IsolateResponse {
  OpenResponse({required this.handle});

  final SaneHandle handle;
}
