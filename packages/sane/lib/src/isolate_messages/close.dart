import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class CloseMessage implements IsolateMessage {
  CloseMessage({required this.handle});

  final SaneHandle handle;
}

class CloseResponse implements IsolateResponse {}
