import 'package:sane/src/sane.dart';

abstract interface class IsolateMessage<T extends IsolateResponse> {
  Future<T> handle(Sane sane);
}

abstract interface class IsolateResponse {}
