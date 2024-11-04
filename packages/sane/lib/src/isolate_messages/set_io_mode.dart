import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class SetIOModeMessage implements IsolateMessage {
  SetIOModeMessage({
    required this.saneHandle,
    required this.ioMode,
  });

  final SaneHandle saneHandle;
  final SaneIOMode ioMode;

  @override
  Future<SetIOModeResponse> handle(Sane sane) async {
    await sane.setIOMode(saneHandle, ioMode);
    return SetIOModeResponse();
  }
}

class SetIOModeResponse implements IsolateResponse {}
