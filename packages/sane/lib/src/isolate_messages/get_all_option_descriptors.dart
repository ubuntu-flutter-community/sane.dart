import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class GetAllOptionDescriptorsMessage implements IsolateMessage {
  GetAllOptionDescriptorsMessage({required this.handle});

  final SaneHandle handle;
}

class GetAllOptionDescriptorsResponse implements IsolateResponse {
  GetAllOptionDescriptorsResponse({required this.optionDescriptors});

  final List<SaneOptionDescriptor> optionDescriptors;
}
