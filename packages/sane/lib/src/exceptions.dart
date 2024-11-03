import 'package:ffi/ffi.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';

/// Base class for all possible errors that can occur in the SANE library.
///
/// See also:
///
/// - [SaneEofException]
/// - [SaneJammedException]
/// - [SaneDeviceBusyException]
/// - [SaneInvalidDataException]
/// - [SaneIoException]
/// - [SaneNoDocumentsException]
/// - [SaneCoverOpenException]
/// - [SaneUnsupportedException]
/// - [SaneCancelledException]
/// - [SaneNoMemoryException]
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
sealed class SaneException implements Exception {
  factory SaneException(SANE_Status status) {
    final exception = switch (status) {
      SANE_Status.STATUS_GOOD => throw ArgumentError(
          'Cannot create SaneException with status STATUS_GOOD',
          'status',
        ),
      SANE_Status.STATUS_UNSUPPORTED => const SaneUnsupportedException(),
      SANE_Status.STATUS_CANCELLED => const SaneCancelledException(),
      SANE_Status.STATUS_DEVICE_BUSY => const SaneDeviceBusyException(),
      SANE_Status.STATUS_INVAL => const SaneInvalidDataException(),
      SANE_Status.STATUS_EOF => const SaneEofException(),
      SANE_Status.STATUS_JAMMED => const SaneJammedException(),
      SANE_Status.STATUS_NO_DOCS => const SaneNoDocumentsException(),
      SANE_Status.STATUS_COVER_OPEN => const SaneCoverOpenException(),
      SANE_Status.STATUS_IO_ERROR => const SaneIoException(),
      SANE_Status.STATUS_NO_MEM => const SaneNoMemoryException(),
      SANE_Status.STATUS_ACCESS_DENIED => const SaneAccessDeniedException(),
    };

    assert(exception._status == status);

    return exception;
  }

  const SaneException._();
  SANE_Status get _status;

  String get message {
    return dylib.sane_strstatus(_status).cast<Utf8>().toDartString();
  }

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}

/// No more data available.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneEofException extends SaneException {
  const SaneEofException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_EOF;
}

/// The document feeder is jammed.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneJammedException extends SaneException {
  const SaneJammedException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_JAMMED;
}

/// The document feeder is out of documents.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneNoDocumentsException extends SaneException {
  const SaneNoDocumentsException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_NO_DOCS;
}

/// The scanner cover is open.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneCoverOpenException extends SaneException {
  const SaneCoverOpenException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_COVER_OPEN;
}

/// The device is busy.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneDeviceBusyException extends SaneException {
  const SaneDeviceBusyException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_DEVICE_BUSY;
}

/// Data is invalid.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneInvalidDataException extends SaneException {
  const SaneInvalidDataException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_INVAL;
}

/// Error during device I/O.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneIoException extends SaneException {
  const SaneIoException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_IO_ERROR;
}

/// Out of memory.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneNoMemoryException extends SaneException {
  const SaneNoMemoryException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_NO_MEM;
}

/// Access to resource has been denied.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneAccessDeniedException extends SaneException {
  const SaneAccessDeniedException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_ACCESS_DENIED;
}

/// Operation was cancelled.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneCancelledException extends SaneException {
  const SaneCancelledException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_CANCELLED;
}

/// Operation is not supported.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SaneUnsupportedException extends SaneException {
  const SaneUnsupportedException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_UNSUPPORTED;
}
