import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class InitMessage implements IsolateMessage<InitResponse> {
  @override
  Future<InitResponse> handle(Sane sane) async {
    final version = await sane.initialize();
    return InitResponse(version);
  }
}

class InitResponse implements IsolateResponse {
  InitResponse(this.version);

  final SaneVersion version;
}
