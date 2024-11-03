import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class StartMessage implements IsolateMessage {
  StartMessage({required this.handle});

  final SaneHandle handle;
}

class StartResponse implements IsolateResponse {}
