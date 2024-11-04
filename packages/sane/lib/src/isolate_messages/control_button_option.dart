import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class ControlButtonOptionMessage implements IsolateMessage {
  ControlButtonOptionMessage({
    required this.saneHandle,
    required this.index,
  });

  final SaneHandle saneHandle;
  final int index;

  @override
  Future<ControlButtonOptionResponse> handle(Sane sane) async {
    return ControlButtonOptionResponse(
      result: await sane.controlButtonOption(
        handle: saneHandle,
        index: index,
      ),
    );
  }
}

class ControlButtonOptionResponse implements IsolateResponse {
  ControlButtonOptionResponse({required this.result});

  final SaneOptionResult<Null> result;
}
