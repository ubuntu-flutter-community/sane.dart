import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/logger.dart';
import 'package:sane/src/type_conversion.dart';

class SyncSane implements Sane {
  factory SyncSane() => _instance ??= SyncSane._();

  SyncSane._();

  static SyncSane? _instance;
  bool _disposed = false;

  @override
  SaneVersion initialize([AuthCallback? authCallback]) {
    _checkIfDisposed();

    void authCallbackAdapter(
      SANE_String_Const resource,
      ffi.Pointer<SANE_Char> username,
      ffi.Pointer<SANE_Char> password,
    ) {
      final credentials = authCallback!(resource.toDartString());
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

    final versionCodePointer = ffi.calloc<SANE_Int>();
    final nativeAuthCallback = authCallback != null
        ? ffi.NativeCallable<SANE_Auth_CallbackFunction>.isolateLocal(
            authCallbackAdapter,
          ).nativeFunction
        : ffi.nullptr;
    try {
      final status = dylib.sane_init(versionCodePointer, nativeAuthCallback);

      logger.finest('sane_init() -> ${status.name}');

      status.check();

      final versionCode = versionCodePointer.value;

      final version = SaneVersion.fromCode(versionCode);

      logger.finest('SANE version: $version');

      return version;
    } finally {
      ffi.calloc.free(versionCodePointer);
      ffi.calloc.free(nativeAuthCallback);
    }
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future.value();

    final completer = Completer<void>();

    Future(() {
      _disposed = true;

      dylib.sane_exit();
      logger.finest('sane_exit()');

      completer.complete();

      _instance = null;
    });

    return completer.future;
  }

  @override
  List<SyncSaneDevice> getDevices({required bool localOnly}) {
    _checkIfDisposed();

    final deviceListPointer =
        ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();

    try {
      final status = dylib.sane_get_devices(
        deviceListPointer,
        localOnly.asSaneBool,
      );

      logger.finest('sane_get_devices() -> ${status.name}');

      status.check();

      final devices = <SyncSaneDevice>[];

      for (var i = 0; deviceListPointer.value[i] != ffi.nullptr; i++) {
        final device = deviceListPointer.value[i].ref;
        devices.add(SyncSaneDevice(device));
      }

      return List.unmodifiable(devices);
    } finally {
      ffi.calloc.free(deviceListPointer);
    }
  }

  @pragma('vm:prefer-inline')
  void _checkIfDisposed() {
    if (_disposed) throw SaneDisposedError();
  }
}

class SyncSaneDevice implements SaneDevice, ffi.Finalizable {
  factory SyncSaneDevice(SANE_Device device) {
    final vendor = device.vendor.toDartString();
    return SyncSaneDevice._(
      name: device.name.toDartString(),
      vendor: vendor == 'Noname' ? null : vendor,
      type: device.type.toDartString(),
      model: device.model.toDartString(),
    );
  }

  SyncSaneDevice._({
    required this.name,
    required this.vendor,
    required this.model,
    required this.type,
  });

  static final _finalizer = ffi.NativeFinalizer(dylib.addresses.sane_close);

  SANE_Handle? _handle;

  bool _closed = false;

  @override
  final String name;

  @override
  final String type;

  @override
  final String? vendor;

  @override
  final String model;

  @override
  void cancel() {
    _checkIfDisposed();

    final handle = _handle;

    if (handle == null) return;

    dylib.sane_cancel(handle);
  }

  SANE_Handle _open() {
    final namePointer = name.toSaneString();
    final handlePointer = ffi.calloc.allocate<SANE_Handle>(
      ffi.sizeOf<SANE_Handle>(),
    );

    try {
      dylib.sane_open(namePointer, handlePointer).check();
      final handle = handlePointer.value;
      _finalizer.attach(this, handle);
      return handle;
    } finally {
      ffi.calloc.free(namePointer);
      ffi.calloc.free(handlePointer);
    }
  }

  @override
  void close() {
    if (_closed) return;

    _closed = true;

    if (_handle == null) return;

    _finalizer.detach(this);
    dylib.sane_close(_handle!);
  }

  @override
  Uint8List read({required int bufferSize}) {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    final lengthPointer = ffi.calloc<SANE_Int>();
    final bufferPointer = ffi.calloc<SANE_Byte>(bufferSize);

    try {
      dylib.sane_read(handle, bufferPointer, bufferSize, lengthPointer).check();

      logger.finest('sane_read()');

      final length = lengthPointer.value;
      final buffer = bufferPointer.cast<Uint8>().asTypedList(length);

      return buffer;
    } finally {
      ffi.calloc.free(lengthPointer);
      ffi.calloc.free(bufferPointer);
    }
  }

  @override
  void start() {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    dylib.sane_start(handle).check();
  }

  @pragma('vm:prefer-inline')
  void _checkIfDisposed() {
    if (_closed) throw SaneDisposedError();
  }

  @override
  SaneOptionDescriptor getOptionDescriptor(int index) {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    final optionDescriptorPointer =
        dylib.sane_get_option_descriptor(handle, index);

    try {
      return saneOptionDescriptorFromNative(
        optionDescriptorPointer.ref,
        index,
      );
    } finally {
      ffi.calloc.free(optionDescriptorPointer);
    }
  }

  @override
  List<SaneOptionDescriptor> getAllOptionDescriptors() {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    final optionDescriptors = <SaneOptionDescriptor>[];

    for (var i = 0; true; i++) {
      final descriptorPointer = dylib.sane_get_option_descriptor(handle, i);
      try {
        if (descriptorPointer == ffi.nullptr) break;
        optionDescriptors.add(
          saneOptionDescriptorFromNative(descriptorPointer.ref, i),
        );
      } finally {
        ffi.calloc.free(descriptorPointer);
      }
    }

    return optionDescriptors;
  }

  SaneOptionResult<T> _controlOption<T>({
    required int index,
    required SaneAction action,
    T? value,
  }) {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    final optionDescriptor = saneOptionDescriptorFromNative(
      dylib.sane_get_option_descriptor(handle, index).ref,
      index,
    );
    final optionType = optionDescriptor.type;
    final optionSize = optionDescriptor.size;

    final infoPointer = ffi.calloc<SANE_Int>();

    ffi.Pointer allocateOptionValue() {
      return switch (optionType) {
        SaneOptionValueType.bool => ffi.calloc<SANE_Bool>(optionSize),
        SaneOptionValueType.int => ffi.calloc<SANE_Int>(optionSize),
        SaneOptionValueType.fixed => ffi.calloc<SANE_Word>(optionSize),
        SaneOptionValueType.string => ffi.calloc<SANE_Char>(optionSize),
        SaneOptionValueType.button => ffi.nullptr,
        SaneOptionValueType.group => throw const SaneInvalidDataException(),
      };
    }

    final valuePointer = allocateOptionValue();

    if (action == SaneAction.setValue) {
      switch (optionType) {
        case SaneOptionValueType.bool when value is bool:
          (valuePointer as ffi.Pointer<SANE_Bool>).value = value.asSaneBool;
          break;

        case SaneOptionValueType.int when value is int:
          (valuePointer as ffi.Pointer<SANE_Int>).value = value;
          break;

        case SaneOptionValueType.fixed when value is double:
          (valuePointer as ffi.Pointer<SANE_Word>).value =
              doubleToSaneFixed(value);
          break;

        case SaneOptionValueType.string when value is String:
          (valuePointer as ffi.Pointer<SANE_String_Const>).value =
              value.toSaneString();
          break;

        case SaneOptionValueType.button:
          break;

        case SaneOptionValueType.group:
        default:
          throw const SaneInvalidDataException();
      }
    }

    final status = dylib.sane_control_option(
      handle,
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
        result = (valuePointer as ffi.Pointer<SANE_Char>).toDartString();

      case SaneOptionValueType.button:
        result = null;

      default:
        throw const SaneInvalidDataException();
    }

    ffi.calloc.free(valuePointer);
    ffi.calloc.free(infoPointer);

    return SaneOptionResult(
      result: result,
      infos: infos,
    );
  }

  @override
  SaneOptionResult<bool> controlBoolOption(
    int index,
    SaneAction action,
    bool? value,
  ) {
    return _controlOption<bool>(
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<int> controlIntOption(
    int index,
    SaneAction action,
    int? value,
  ) {
    return _controlOption<int>(
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<double> controlFixedOption(
    int index,
    SaneAction action,
    double? value,
  ) {
    return _controlOption<double>(
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<String> controlStringOption(
    int index,
    SaneAction action,
    String? value,
  ) {
    return _controlOption<String>(
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<Null> controlButtonOption(int index) {
    return _controlOption<Null>(
      index: index,
      action: SaneAction.setValue,
      value: null,
    );
  }

  @override
  SaneParameters getParameters() {
    _checkIfDisposed();

    final handle = _handle ??= _open();
    final nativeParametersPointer = ffi.calloc<SANE_Parameters>();

    try {
      final status = dylib.sane_get_parameters(
        handle,
        nativeParametersPointer,
      );
      logger.finest('sane_get_parameters() -> ${status.name}');

      status.check();

      return saneParametersFromNative(nativeParametersPointer.ref);
    } finally {
      ffi.calloc.free(nativeParametersPointer);
    }
  }
}
