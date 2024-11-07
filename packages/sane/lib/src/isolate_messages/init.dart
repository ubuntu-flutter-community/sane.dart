import 'package:sane/src/impl/sane_sync.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class InitMessage implements IsolateMessage<InitResponse> {
  @override
  Future<InitResponse> handle(Sane sane) async {
    return InitResponse(
      versionCode: await sane.init(),
    );
  }
}

class InitResponse implements IsolateResponse {
  InitResponse({required this.versionCode});

  final int versionCode;
}
