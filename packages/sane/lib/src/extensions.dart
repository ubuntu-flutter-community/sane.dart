import 'package:logging/logging.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';

extension SaneStatusExtension on SANE_Status {
  /// Throws [SaneException] if the status is not [SANE_Status.STATUS_GOOD].
  @pragma('vm:prefer-inline')
  void check() {
    if (this != SANE_Status.STATUS_GOOD) {
      throw SaneException(this);
    }
  }
}

extension LoggerExtension on Logger {
  void redirect(LogRecord record) {
    log(
      record.level,
      record.message,
      record.error,
      record.stackTrace,
      record.zone,
    );
  }
}
