import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetOptionDescriptorMessage
    implements IsolateMessage<GetOptionDescriptorResponse> {
  GetOptionDescriptorMessage({
    required this.deviceName,
    required this.index,
  });

  final String deviceName;
  final int index;

  @override
  Future<GetOptionDescriptorResponse> handle(Sane sane) async {
    final device = getDevice(deviceName);
    final optionDescriptor = await device.getOptionDescriptor(index);
    return GetOptionDescriptorResponse(optionDescriptor: optionDescriptor);
  }
}

class GetOptionDescriptorResponse implements IsolateResponse {
  GetOptionDescriptorResponse({required this.optionDescriptor});

  final SaneOptionDescriptor optionDescriptor;
}
