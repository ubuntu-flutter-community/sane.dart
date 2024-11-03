import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class ControlButtonOptionMessage implements IsolateMessage {
  ControlButtonOptionMessage({
    required this.handle,
    required this.index,
  });

  final SaneHandle handle;
  final int index;
}

class ControlButtonOptionResponse implements IsolateResponse {
  ControlButtonOptionResponse({required this.result});

  final SaneOptionResult<Null> result;
}
