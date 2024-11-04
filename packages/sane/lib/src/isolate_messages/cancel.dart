import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class CancelMessage implements IsolateMessage {
  CancelMessage({required this.saneHandle});

  final SaneHandle saneHandle;

  @override
  Future<CancelResponse> handle(Sane sane) async {
    await sane.cancel(saneHandle);
    return CancelResponse();
  }
}

class CancelResponse implements IsolateResponse {}
