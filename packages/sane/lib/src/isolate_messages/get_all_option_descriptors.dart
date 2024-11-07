import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetAllOptionDescriptorsMessage
    implements IsolateMessage<GetAllOptionDescriptorsResponse> {
  GetAllOptionDescriptorsMessage(this.deviceName);

  final String deviceName;

  @override
  Future<GetAllOptionDescriptorsResponse> handle(Sane sane) async {
    final device = getDevice(deviceName);
    final optionDescriptors = await device.getAllOptionDescriptors();
    return GetAllOptionDescriptorsResponse(optionDescriptors);
  }
}

class GetAllOptionDescriptorsResponse implements IsolateResponse {
  GetAllOptionDescriptorsResponse(this.optionDescriptors);

  final List<SaneOptionDescriptor> optionDescriptors;
}
