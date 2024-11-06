import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetAllOptionDescriptorsMessage
    implements IsolateMessage<GetAllOptionDescriptorsResponse> {
  GetAllOptionDescriptorsMessage({required this.saneHandle});

  final SaneHandle saneHandle;

  @override
  Future<GetAllOptionDescriptorsResponse> handle(Sane sane) async {
    return GetAllOptionDescriptorsResponse(
      optionDescriptors: await sane.getAllOptionDescriptors(saneHandle),
    );
  }
}

class GetAllOptionDescriptorsResponse implements IsolateResponse {
  GetAllOptionDescriptorsResponse({required this.optionDescriptors});

  final List<SaneOptionDescriptor> optionDescriptors;
}
