import 'package:sane/sane.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class CloseMessage implements IsolateMessage {
  CloseMessage({required this.saneHandle});

  final SaneHandle saneHandle;

  @override
  Future<CloseResponse> handle(Sane sane) async {
    await sane.close(saneHandle);
    return CloseResponse();
  }
}

class CloseResponse implements IsolateResponse {}
