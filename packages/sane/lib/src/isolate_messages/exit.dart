import 'package:sane/src/impl/sane_sync.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class ExitMessage implements IsolateMessage {
  @override
  Future<ExitResponse> handle(Sane sane) async {
    await sane.exit();
    return ExitResponse();
  }
}

class ExitResponse implements IsolateResponse {}
