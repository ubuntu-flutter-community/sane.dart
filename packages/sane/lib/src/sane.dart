import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/impl/sane_mock.dart';
import 'package:sane/src/impl/sane_native.dart';
import 'package:sane/src/impl/sane_sync.dart';

typedef AuthCallback = SaneCredentials Function(String resourceName);

abstract interface class Sane {
  /// Instantiates a new asynchronous SANE instance.
  ///
  /// See also:
  ///
  /// - [Sane.sync]
  factory Sane([Sane? backingSane]) => NativeSane(backingSane);

  /// Instantiates a new synchronous SANE instance.
  factory Sane.sync() => SyncSane();

  /// Instantiates a mock SANE instance for testing.
  factory Sane.mock() => MockSane();

  /// Disposes the SANE instance.
  ///
  /// Closes all device handles and all future calls are invalid.
  ///
  /// See also:
  ///
  /// - [`sane_exit`](https://sane-project.gitlab.io/standard/api.html#sane-exit)
  void dispose();

  /// Initializes the SANE library.
  FutureOr<SaneVersion> initialize([AuthCallback? authCallback]);

  /// Queries the list of devices that are available.
  ///
  /// This method can be called repeatedly to detect when new devices become
  /// available. If argument [localOnly] is true, only local devices are
  /// returned (devices directly attached to the machine that SANE is running
  /// on). If it is `false`, the device list includes all remote devices that
  /// are accessible to the SANE library.
  ///
  /// See also:
  ///
  /// - [`sane_get_devices`](https://sane-project.gitlab.io/standard/api.html#sane-get-devices)
  FutureOr<List<SaneDevice>> getDevices({required bool localOnly});
}

// TODO(Craftplacer): Turn SaneVersion into an extension type, once available.
@immutable
class SaneVersion {
  const SaneVersion.fromCode(this.code);

  final int code;

  int get major => (code >> 24) & 0xff;

  int get minor => (code >> 16) & 0xff;

  int get build => (code >> 0) & 0xffff;

  @override
  String toString() => '$major.$minor.$build';

  @override
  bool operator ==(covariant SaneVersion other) => code == other.code;

  @override
  int get hashCode => code;
}

/// Represents a SANE device.
///
/// Devices can be retrieved using [Sane.getDevices].
///
/// See also:
///
/// - [Device Descriptor Type](https://sane-project.gitlab.io/standard/api.html#device-descriptor-type)
abstract interface class SaneDevice {
  /// The name of the device.
  String get name;

  /// The type of the device.
  ///
  /// For a list of predefined types, see [SaneDeviceTypes].
  String get type;

  /// The vendor (manufacturer) of the device.
  ///
  /// Can be `null` for virtual devices that have no physical vendor associated.
  String? get vendor;

  /// The model of the device.
  String get model;

  /// Disposes the SANE device. Infers [cancel].
  ///
  /// See also:
  ///
  /// - [`sane_close`](https://sane-project.gitlab.io/standard/api.html#sane-close)
  FutureOr<void> close();

  /// Tries to cancel the currently pending operation of the device immediately
  /// or as quickly as possible.
  ///
  /// See also:
  ///
  /// - [`sane_cancel`](https://sane-project.gitlab.io/standard/api.html#sane-cancel)
  FutureOr<void> cancel();

  /// Reads image data from the device.
  ///
  /// The returned [Uint8List] is [bufferSize] bytes long or less. If it is
  /// zero, the end of the frame has been reached.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneCancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SaneJammedException] if the document feeder is jammed.
  /// - Throws [SaneNoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SaneCoverOpenException] if the scanner cover is open.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_read`](https://sane-project.gitlab.io/standard/api.html#sane-read)
  FutureOr<Uint8List> read({required int bufferSize});

  /// Initiates acquisition of an image from the device.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneCancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SaneDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SaneJammedException] if the document feeder is jammed.
  /// - Throws [SaneNoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SaneCoverOpenException] if the scanner cover is open.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneInvalidDataException] if the sane cannot be started with the
  ///   current set of options. The frontend should reload the option
  ///   descriptors.
  ///
  /// See also:
  ///
  /// - [`sane_start`](https://sane-project.gitlab.io/standard/api.html#sane-start)
  FutureOr<void> start();

  FutureOr<SaneOptionDescriptor> getOptionDescriptor(int index);

  FutureOr<List<SaneOptionDescriptor>> getAllOptionDescriptors();

  FutureOr<SaneOptionResult<bool>> controlBoolOption(
    int index,
    SaneAction action,
    bool? value,
  );

  FutureOr<SaneOptionResult<int>> controlIntOption(
    int index,
    SaneAction action,
    int? value,
  );

  FutureOr<SaneOptionResult<double>> controlFixedOption(
    int index,
    SaneAction action,
    double? value,
  );

  FutureOr<SaneOptionResult<String>> controlStringOption(
    int index,
    SaneAction action,
    String? value,
  );

  FutureOr<SaneOptionResult<Null>> controlButtonOption(int index);

  FutureOr<SaneParameters> getParameters();
}

/// Predefined device types for [SaneDevice.type].
///
/// See also:
///
/// - [Predefined Device Information Strings](https://sane-project.gitlab.io/standard/api.html#vendor-names)
abstract final class SaneDeviceTypes {
  static const filmScanner = 'film scanner';
  static const flatbedScanner = 'flatbed scanner';
  static const frameGrabber = 'frame grabber';
  static const handheldScanner = 'handheld scanner';
  static const multiFunctionPeripheral = 'multi-function peripheral';
  static const sheetfedScanner = 'sheetfed scanner';
  static const stillCamera = 'still camera';
  static const videoCamera = 'video camera';
  static const virtualDevice = 'virtual device';
}
