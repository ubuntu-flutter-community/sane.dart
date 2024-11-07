import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class ControlValueOptionMessage<T>
    implements IsolateMessage<ControlValueOptionResponse<T>> {
  const ControlValueOptionMessage({
    required this.deviceName,
    required this.index,
    required this.action,
    this.value,
  });

  final String deviceName;
  final int index;
  final SaneAction action;
  final T? value;

  @override
  Future<ControlValueOptionResponse<T>> handle(Sane sane) async {
    final device = getDevice(deviceName);

    switch (value) {
      case final bool value:
        final result = await device.controlBoolOption(index, action, value);
        return ControlValueOptionResponse<bool>(result)
            as ControlValueOptionResponse<T>;

      case final int value:
        final result = await device.controlIntOption(index, action, value);
        return ControlValueOptionResponse<int>(result)
            as ControlValueOptionResponse<T>;

      case final double value:
        final result = await device.controlFixedOption(index, action, value);
        return ControlValueOptionResponse<double>(result)
            as ControlValueOptionResponse<T>;

      case final String value:
        final result = await device.controlStringOption(index, action, value);
        return ControlValueOptionResponse<String>(result)
            as ControlValueOptionResponse<T>;

      default:
        throw Exception('Invalid value type.');
    }
  }
}

class ControlValueOptionResponse<T> implements IsolateResponse {
  ControlValueOptionResponse(this.result);

  final SaneOptionResult<T> result;
}
