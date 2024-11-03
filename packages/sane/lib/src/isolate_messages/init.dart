import 'package:sane/src/isolate_messages/interface.dart';

class InitMessage implements IsolateMessage {}

class InitResponse implements IsolateResponse {
  InitResponse({required this.versionCode});

  final int versionCode;
}
