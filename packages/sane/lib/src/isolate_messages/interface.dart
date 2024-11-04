import 'package:sane/src/sane.dart';

abstract interface class IsolateMessage {
  Future<IsolateResponse> handle(Sane sane);
}

abstract interface class IsolateResponse {}
