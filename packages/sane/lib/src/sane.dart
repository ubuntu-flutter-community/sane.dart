import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/logger.dart';
import 'package:sane/src/structures.dart';
import 'package:sane/src/type_conversion.dart';
import 'package:sane/src/utils.dart';

typedef AuthCallback = SaneCredentials Function(String resourceName);

class Sane {
  factory Sane() => _instance ??= Sane._();

  Sane._();

  static Sane? _instance;
  bool _exited = false;
  final Map<SaneHandle, SANE_Handle> _nativeHandles = {};

  SANE_Handle _getNativeHandle(SaneHandle handle) => _nativeHandles[handle]!;

  Future<int> init({
    AuthCallback? authCallback,
  }) {
    _checkIfExited();

    final completer = Completer<int>();

    void authCallbackAdapter(
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
      logger.finest('sane_init() -> ${status.name}');

      status.check();

      final versionCode = versionCodePointer.value;
      logger.finest(
        'SANE version: ${SaneUtils.version(versionCodePointer.value)}',
      );

      ffi.calloc.free(versionCodePointer);
      ffi.calloc.free(nativeAuthCallback);

      completer.complete(versionCode);
    });

    return completer.future;
  }

  Future<void> exit() {
    if (_exited) return Future.value();

    final completer = Completer<void>();

    Future(() {
      _exited = true;

      dylib.sane_exit();
      logger.finest('sane_exit()');

      completer.complete();

      _instance = null;
    });

    return completer.future;
  }

  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) {
    _checkIfExited();

    final completer = Completer<List<SaneDevice>>();

    Future(() {
      final deviceListPointer =
          ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();
      final status = dylib.sane_get_devices(
        deviceListPointer,
        saneBoolFromDartBool(localOnly),
      );

      logger.finest('sane_get_devices() -> ${status.name}');

      status.check();

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

  Future<SaneHandle> open(String deviceName) {
    _checkIfExited();

    final completer = Completer<SaneHandle>();

    Future(() {
      final nativeHandlePointer = ffi.calloc<SANE_Handle>();
      final deviceNamePointer = saneStringFromDartString(deviceName);
      final status = dylib.sane_open(deviceNamePointer, nativeHandlePointer);
      logger.finest('sane_open() -> ${status.name}');

      status.check();

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

  Future<SaneHandle> openDevice(SaneDevice device) {
    _checkIfExited();

    return open(device.name);
  }

  Future<void> close(SaneHandle handle) {
    _checkIfExited();

    final completer = Completer<void>();

    Future(() {
      dylib.sane_close(_getNativeHandle(handle));
      _nativeHandles.remove(handle);
      logger.finest('sane_close()');

      completer.complete();
    });

    return completer.future;
  }

  Future<SaneOptionDescriptor> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) {
    _checkIfExited();

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
    _checkIfExited();

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
    _checkIfExited();

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
          throw const SaneInvalidDataException();
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
            throw const SaneInvalidDataException();
        }
      }

      final status = dylib.sane_control_option(
        _getNativeHandle(handle),
        index,
        nativeSaneActionFromDart(action),
        valuePointer.cast<ffi.Void>(),
        infoPointer,
      );
      logger.finest(
        'sane_control_option($index, $action, $value) -> ${status.name}',
      );

      status.check();

      final infos = saneOptionInfoFromNative(infoPointer.value);
      late final dynamic result;
      switch (optionType) {
        case SaneOptionValueType.bool:
          result = dartBoolFromSaneBool(
            (valuePointer as ffi.Pointer<SANE_Bool>).value,
          );

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
          throw const SaneInvalidDataException();
      }

      ffi.calloc.free(valuePointer);
      ffi.calloc.free(infoPointer);

      completer.complete(
        SaneOptionResult(
          result: result,
          infos: infos,
        ),
      );
    });

    return completer.future;
  }

  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) {
    return _controlOption<bool>(
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
  }) {
    return _controlOption<int>(
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
  }) {
    return _controlOption<double>(
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
  }) {
    return _controlOption<String>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) {
    return _controlOption<Null>(
      handle: handle,
      index: index,
      action: SaneAction.setValue,
      value: null,
    );
  }

  Future<SaneParameters> getParameters(SaneHandle handle) {
    _checkIfExited();

    final completer = Completer<SaneParameters>();

    Future(() {
      final nativeParametersPointer = ffi.calloc<SANE_Parameters>();
      final status = dylib.sane_get_parameters(
        _getNativeHandle(handle),
        nativeParametersPointer,
      );
      logger.finest('sane_get_parameters() -> ${status.name}');

      status.check();

      final parameters = saneParametersFromNative(nativeParametersPointer.ref);

      ffi.calloc.free(nativeParametersPointer);

      completer.complete(parameters);
    });

    return completer.future;
  }

  Future<void> start(SaneHandle handle) {
    _checkIfExited();

    final completer = Completer<void>();

    Future(() {
      final status = dylib.sane_start(_getNativeHandle(handle));
      logger.finest('sane_start() -> ${status.name}');

      status.check();

      completer.complete();
    });

    return completer.future;
  }

  Future<Uint8List> read(SaneHandle handle, int bufferSize) {
    _checkIfExited();

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
      logger.finest('sane_read() -> ${status.name}');

      status.check();

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
    _checkIfExited();

    final completer = Completer<void>();

    Future(() {
      dylib.sane_cancel(_getNativeHandle(handle));
      logger.finest('sane_cancel()');

      completer.complete();
    });

    return completer.future;
  }

  Future<void> setIOMode(SaneHandle handle, SaneIOMode mode) {
    _checkIfExited();

    final completer = Completer<void>();

    Future(() {
      final status = dylib.sane_set_io_mode(
        _getNativeHandle(handle),
        saneBoolFromIOMode(mode),
      );
      logger.finest('sane_set_io_mode() -> ${status.name}');

      status.check();

      completer.complete();
    });

    return completer.future;
  }

  @pragma('vm:prefer-inline')
  void _checkIfExited() {
    if (_exited) throw SaneDisposedError();
  }
}
