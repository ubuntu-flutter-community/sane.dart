import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class GetOptionDescriptorMessage implements IsolateMessage {
  GetOptionDescriptorMessage({
    required this.handle,
    required this.index,
  });

  final SaneHandle handle;
  final int index;
}

class GetOptionDescriptorResponse implements IsolateResponse {
  GetOptionDescriptorResponse({required this.optionDescriptor});

  final SaneOptionDescriptor optionDescriptor;
}
