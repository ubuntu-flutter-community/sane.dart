import 'package:sane/src/impl/sane_sync.dart';

abstract interface class IsolateMessage<T extends IsolateResponse> {
  Future<T> handle(Sane sane);
}

abstract interface class IsolateResponse {}
