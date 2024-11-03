import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class SetIOModeMessage implements IsolateMessage {
  SetIOModeMessage({
    required this.handle,
    required this.ioMode,
  });

  final SaneHandle handle;
  final SaneIOMode ioMode;
}

class SetIOModeResponse implements IsolateResponse {}
