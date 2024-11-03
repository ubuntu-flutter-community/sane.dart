import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class ControlOptionMessage<T> implements IsolateMessage {
  ControlOptionMessage({
    required this.handle,
    required this.index,
    required this.action,
    this.value,
  });

  final SaneHandle handle;
  final int index;
  final SaneAction action;
  final T? value;
}

class ControlOptionResponse<T> implements IsolateResponse {
  ControlOptionResponse({required this.result});

  final SaneOptionResult<T> result;
}
