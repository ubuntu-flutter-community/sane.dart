import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class StartMessage implements IsolateMessage {
  StartMessage({required this.saneHandle});

  final SaneHandle saneHandle;

  @override
  Future<StartResponse> handle(Sane sane) async {
    await sane.start(saneHandle);
    return StartResponse();
  }
}

class StartResponse implements IsolateResponse {}
