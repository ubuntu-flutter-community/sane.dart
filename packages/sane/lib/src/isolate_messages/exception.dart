import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class ExceptionResponse implements IsolateResponse {
  ExceptionResponse({
    required this.exception,
    required this.stackTrace,
  });

  final SaneException exception;
  final StackTrace stackTrace;
}
