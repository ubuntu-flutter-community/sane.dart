import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class GetParametersMessage implements IsolateMessage {
  GetParametersMessage({required this.handle});

  final SaneHandle handle;
}

class GetParametersResponse implements IsolateResponse {
  GetParametersResponse({required this.parameters});

  final SaneParameters parameters;
}
