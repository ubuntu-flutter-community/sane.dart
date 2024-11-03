import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class CancelMessage implements IsolateMessage {
  CancelMessage({required this.handle});

  final SaneHandle handle;
}

class CancelResponse implements IsolateResponse {}
