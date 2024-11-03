import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/structures.dart';
import 'package:sane/src/type_conversion.dart';
import 'package:sane/src/utils.dart';

typedef AuthCallback = SaneCredentials Function(String resourceName);

class Sane {
  final Map<SaneHandle, SANE_Handle> _nativeHandles = {};
  SANE_Handle _getNativeHandle(SaneHandle handle) => _nativeHandles[handle]!;

  Future<int> init({
    AuthCallback? authCallback,
  }) {
    final completer = Completer<int>();

    authCallbackAdapter(
      SANE_String_Const resource,
      ffi.Pointer<SANE_Char> username,
      ffi.Pointer<SANE_Char> password,
    ) {
      final credentials = authCallback!(dartStringFromSaneString(resource)!);
      for (var i = 0;
          i < credentials.username.length && i < SANE_MAX_USERNAME_LEN;
          i++) {
        username[i] = credentials.username.codeUnitAt(i);
      }
      for (var i = 0;
          i < credentials.password.length && i < SANE_MAX_PASSWORD_LEN;
          i++) {
        password[i] = credentials.password.codeUnitAt(i);
      }
    }

    Future(() {
      final versionCodePointer = ffi.calloc<SANE_Int>();
      final nativeAuthCallback = authCallback != null
          ? ffi.NativeCallable<SANE_Auth_CallbackFunction>.isolateLocal(
              authCallbackAdapter,
            ).nativeFunction
          : ffi.nullptr;
      final status = dylib.sane_init(versionCodePointer, nativeAuthCallback);
      print('sane_init() -> ${status.name}');

      _handleSaneStatus(status);

      final versionCode = versionCodePointer.value;
      print('SANE version: ${SaneUtils.version(versionCodePointer.value)}');

      ffi.calloc.free(versionCodePointer);
      ffi.calloc.free(nativeAuthCallback);

      completer.complete(versionCode);
    });

    return completer.future;
  }

  Future<void> exit() {
    final completer = Completer<void>();

    Future(() {
      dylib.sane_exit();
      print('sane_exit()');

      completer.complete();
    });

    return completer.future;
  }

  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) async {
    final completer = Completer<List<SaneDevice>>();

    Future(() {
      final deviceListPointer =
          ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();
      final status = dylib.sane_get_devices(
        deviceListPointer,
        saneBoolFromDartBool(localOnly),
      );
      print('sane_get_devices() -> ${status.name}');

      _handleSaneStatus(status);

      final devices = <SaneDevice>[];
      for (var i = 0; deviceListPointer.value[i] != ffi.nullptr; i++) {
        final nativeDevice = deviceListPointer.value[i].ref;
        devices.add(saneDeviceFromNative(nativeDevice));
      }

      ffi.calloc.free(deviceListPointer);

      completer.complete(devices);
    });

    return completer.future;
  }

  Future<SaneHandle> open(String deviceName) async {
    final completer = Completer<SaneHandle>();

    Future(() {
      final nativeHandlePointer = ffi.calloc<SANE_Handle>();
      final deviceNamePointer = saneStringFromDartString(deviceName);
      final status = dylib.sane_open(deviceNamePointer, nativeHandlePointer);
      print('sane_open() -> ${status.name}');

      _handleSaneStatus(status);

      final handle = SaneHandle(deviceName: deviceName);
      _nativeHandles.addAll({
        handle: nativeHandlePointer.value,
      });

      ffi.calloc.free(nativeHandlePointer);
      ffi.calloc.free(deviceNamePointer);

      completer.complete(handle);
    });

    return completer.future;
  }

  Future<SaneHandle> openDevice(SaneDevice device) async {
    return open(device.name);
  }

  Future<void> close(SaneHandle handle) {
    final completer = Completer<void>();

    Future(() {
      dylib.sane_close(_getNativeHandle(handle));
      _nativeHandles.remove(handle);
      print('sane_close()');

      completer.complete();
    });

    return completer.future;
  }

  Future<SaneOptionDescriptor> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) {
    final completer = Completer<SaneOptionDescriptor>();

    Future(() {
      final optionDescriptorPointer =
          dylib.sane_get_option_descriptor(_getNativeHandle(handle), index);
      final optionDescriptor = saneOptionDescriptorFromNative(
        optionDescriptorPointer.ref,
        index,
      );

      ffi.calloc.free(optionDescriptorPointer);

      completer.complete(optionDescriptor);
    });

    return completer.future;
  }

  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) {
    final completer = Completer<List<SaneOptionDescriptor>>();

    Future(() {
      final optionDescriptors = <SaneOptionDescriptor>[];

      for (var i = 0; true; i++) {
        final descriptorPointer =
            dylib.sane_get_option_descriptor(_getNativeHandle(handle), i);
        if (descriptorPointer == ffi.nullptr) break;
        optionDescriptors.add(
          saneOptionDescriptorFromNative(descriptorPointer.ref, i),
        );
      }

      completer.complete(optionDescriptors);
    });

    return completer.future;
  }

  Future<SaneOptionResult<T>> _controlOption<T>({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    T? value,
  }) {
    final completer = Completer<SaneOptionResult<T>>();

    Future(() {
      final optionDescriptor = saneOptionDescriptorFromNative(
        dylib.sane_get_option_descriptor(_getNativeHandle(handle), index).ref,
        index,
      );
      final optionType = optionDescriptor.type;
      final optionSize = optionDescriptor.size;

      final infoPointer = ffi.calloc<SANE_Int>();

      late final ffi.Pointer valuePointer;
      switch (optionType) {
        case SaneOptionValueType.bool:
          valuePointer = ffi.calloc<SANE_Bool>(optionSize);

        case SaneOptionValueType.int:
          valuePointer = ffi.calloc<SANE_Int>(optionSize);

        case SaneOptionValueType.fixed:
          valuePointer = ffi.calloc<SANE_Word>(optionSize);

        case SaneOptionValueType.string:
          valuePointer = ffi.calloc<SANE_Char>(optionSize);

        case SaneOptionValueType.button:
          valuePointer = ffi.nullptr;

        case SaneOptionValueType.group:
          throw SaneInvalidException();
      }

      if (action == SaneAction.setValue) {
        switch (optionType) {
          case SaneOptionValueType.bool:
            if (value is! bool) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Bool>).value =
                saneBoolFromDartBool(value);
            break;

          case SaneOptionValueType.int:
            if (value is! int) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Int>).value = value;
            break;

          case SaneOptionValueType.fixed:
            if (value is! double) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Word>).value =
                doubleToSaneFixed(value);
            break;

          case SaneOptionValueType.string:
            if (value is! String) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Char>).value =
                saneStringFromDartString(value).value;
            break;

          case SaneOptionValueType.button:
            break;

          case SaneOptionValueType.group:
            continue invalid;

          invalid:
          default:
            throw SaneInvalidException();
        }
      }

      final status = dylib.sane_control_option(
        _getNativeHandle(handle),
        index,
        nativeSaneActionFromDart(action),
        valuePointer.cast<ffi.Void>(),
        infoPointer,
      );
      print('sane_control_option($index, $action, $value) -> ${status.name}');

      _handleSaneStatus(status);

      final infos = saneOptionInfoFromNative(infoPointer.value);
      late final dynamic result;
      switch (optionType) {
        case SaneOptionValueType.bool:
          result = dartBoolFromSaneBool(
              (valuePointer as ffi.Pointer<SANE_Bool>).value);

        case SaneOptionValueType.int:
          result = (valuePointer as ffi.Pointer<SANE_Int>).value;

        case SaneOptionValueType.fixed:
          result =
              saneFixedToDouble((valuePointer as ffi.Pointer<SANE_Word>).value);

        case SaneOptionValueType.string:
          result = dartStringFromSaneString(
                valuePointer as ffi.Pointer<SANE_Char>,
              ) ??
              '';

        case SaneOptionValueType.button:
          result = null;

        default:
          throw SaneInvalidException();
      }

      ffi.calloc.free(valuePointer);
      ffi.calloc.free(infoPointer);

      completer.complete(SaneOptionResult(
        result: result,
        infos: infos,
      ));
    });

    return completer.future;
  }

  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) async {
    return await _controlOption<bool>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<int>> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) async {
    return await _controlOption<int>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<double>> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) async {
    return await _controlOption<double>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<String>> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) async {
    return await _controlOption<String>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    return await _controlOption<Null>(
      handle: handle,
      index: index,
      action: SaneAction.setValue,
      value: null,
    );
  }

  Future<SaneParameters> getParameters(SaneHandle handle) {
    final completer = Completer<SaneParameters>();

    Future(() {
      final nativeParametersPointer = ffi.calloc<SANE_Parameters>();
      final status = dylib.sane_get_parameters(
          _getNativeHandle(handle), nativeParametersPointer);
      print('sane_get_parameters() -> ${status.name}');

      _handleSaneStatus(status);

      final parameters = saneParametersFromNative(nativeParametersPointer.ref);

      ffi.calloc.free(nativeParametersPointer);

      completer.complete(parameters);
    });

    return completer.future;
  }

  Future<void> start(SaneHandle handle) {
    final completer = Completer<void>();

    Future(() {
      final status = dylib.sane_start(_getNativeHandle(handle));
      print('sane_start() -> ${status.name}');

      _handleSaneStatus(status);

      completer.complete();
    });

    return completer.future;
  }

  Future<Uint8List> read(SaneHandle handle, int bufferSize) {
    final completer = Completer<Uint8List>();

    Future(() {
      final bytesReadPointer = ffi.calloc<SANE_Int>();
      final bufferPointer = ffi.calloc<SANE_Byte>(bufferSize);

      final status = dylib.sane_read(
        _getNativeHandle(handle),
        bufferPointer,
        bufferSize,
        bytesReadPointer,
      );
      print('sane_read() -> ${status.name}');

      _handleSaneStatus(status);

      final bytes = Uint8List.fromList(
        List.generate(
          bytesReadPointer.value,
          (i) => (bufferPointer + i).value,
        ),
      );

      ffi.calloc.free(bytesReadPointer);
      ffi.calloc.free(bufferPointer);

      completer.complete(bytes);
    });

    return completer.future;
  }

  Future<void> cancel(SaneHandle handle) {
    final completer = Completer<void>();

    Future(() {
      dylib.sane_cancel(_getNativeHandle(handle));
      print('sane_cancel()');

      completer.complete();
    });

    return completer.future;
  }

  Future<void> setIOMode(SaneHandle handle, SaneIOMode mode) {
    final completer = Completer<void>();

    Future(() {
      final status = dylib.sane_set_io_mode(
        _getNativeHandle(handle),
        saneBoolFromIOMode(mode),
      );
      print('sane_set_io_mode() -> ${status.name}');

      _handleSaneStatus(status);

      completer.complete();
    });

    return completer.future;
  }

  void _handleSaneStatus(SANE_Status status) {
    switch (status) {
      case SANE_Status.STATUS_UNSUPPORTED:
        throw SaneUnsupportedException();
      case SANE_Status.STATUS_CANCELLED:
        throw SaneCancelledException();
      case SANE_Status.STATUS_DEVICE_BUSY:
        throw SaneDeviceBusyException();
      case SANE_Status.STATUS_INVAL:
        throw SaneInvalidException();
      case SANE_Status.STATUS_JAMMED:
        throw SaneJammedException();
      case SANE_Status.STATUS_NO_DOCS:
        throw SaneNoDocumentsException();
      case SANE_Status.STATUS_COVER_OPEN:
        throw SaneCoverOpenException();
      case SANE_Status.STATUS_IO_ERROR:
        throw SaneIOErrorException();
      case SANE_Status.STATUS_NO_MEM:
        throw SaneNoMemoryException();
      case SANE_Status.STATUS_ACCESS_DENIED:
        throw SaneAccessDeniedException();
      default:
    }
  }
}
