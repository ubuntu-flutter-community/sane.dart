import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class ControlValueOptionMessage<T>
    implements IsolateMessage<ControlValueOptionResponse<T>> {
  ControlValueOptionMessage({
    required this.saneHandle,
    required this.index,
    required this.action,
    this.value,
  });

  final SaneHandle saneHandle;
  final int index;
  final SaneAction action;
  final T? value;

  @override
  Future<ControlValueOptionResponse<T>> handle(Sane sane) async {
    switch (value) {
      case final bool value:
        return ControlValueOptionResponse<bool>(
          result: await sane.controlBoolOption(
            handle: saneHandle,
            index: index,
            action: action,
            value: value,
          ),
        ) as ControlValueOptionResponse<T>;
      case final int value:
        return ControlValueOptionResponse<int>(
          result: await sane.controlIntOption(
            handle: saneHandle,
            index: index,
            action: action,
            value: value,
          ),
        ) as ControlValueOptionResponse<T>;
      case final double value:
        return ControlValueOptionResponse<double>(
          result: await sane.controlFixedOption(
            handle: saneHandle,
            index: index,
            action: action,
            value: value,
          ),
        ) as ControlValueOptionResponse<T>;
      case final String value:
        return ControlValueOptionResponse<String>(
          result: await sane.controlStringOption(
            handle: saneHandle,
            index: index,
            action: action,
            value: value,
          ),
        ) as ControlValueOptionResponse<T>;
      default:
        throw Exception('Invalid value type.');
    }
  }
}

class ControlValueOptionResponse<T> implements IsolateResponse {
  ControlValueOptionResponse({required this.result});

  final SaneOptionResult<T> result;
}
