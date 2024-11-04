import 'dart:typed_data';

import 'package:sane/sane.dart';

class SaneDev implements Sane {
  @override
  Future<void> cancel(SaneHandle handle) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_cancel()');
    });
  }

  @override
  Future<void> close(SaneHandle handle) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_close()');
    });
  }

  @override
  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_controlBoolOption()');
      return SaneOptionResult(result: value ?? true, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_controlButtonOption()');
      return SaneOptionResult(result: null, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_controlFixedOption()');
      return SaneOptionResult(result: value ?? .1, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_controlIntOption()');
      return SaneOptionResult(result: value ?? 1, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_controlStringOption()');
      return SaneOptionResult(result: value ?? 'value', infos: []);
    });
  }

  @override
  Future<void> exit() {
    return Future(() {
      print('sane_exit()');
    });
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_getAllOptionDescriptors()');
      return [
        SaneOptionDescriptor(
          index: 0,
          name: 'name',
          title: 'title',
          desc: 'desc',
          type: SaneOptionValueType.int,
          unit: SaneOptionUnit.none,
          size: 1,
          capabilities: [],
          constraint: null,
        ),
      ];
    });
  }

  @override
  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_getDevices()');
      return [
        for (var i = 0; i < 3; i++)
          SaneDevice(
            name: 'name $i',
            vendor: 'Vendor$i',
            model: 'Model$i',
            type: 'Type$i',
          ),
      ];
    });
  }

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_getOptionDescriptor()');
      return SaneOptionDescriptor(
        index: index,
        name: 'name',
        title: 'title',
        desc: 'desc',
        type: SaneOptionValueType.int,
        unit: SaneOptionUnit.none,
        size: 1,
        capabilities: [],
        constraint: null,
      );
    });
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_getParameters()');
      return SaneParameters(
        format: SaneFrameFormat.gray,
        lastFrame: true,
        bytesPerLine: 800,
        pixelsPerLine: 100,
        lines: 100,
        depth: 8,
      );
    });
  }

  @override
  Future<int> init({
    AuthCallback? authCallback,
  }) {
    return Future(() {
      print('sane_init()');
      return 1;
    });
  }

  @override
  Future<SaneHandle> open(String deviceName) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_open()');
      return SaneHandle(deviceName: deviceName);
    });
  }

  @override
  Future<SaneHandle> openDevice(SaneDevice device) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_openDevice()');
      return SaneHandle(deviceName: device.name);
    });
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_read()');
      return Uint8List.fromList([]);
    });
  }

  @override
  Future<void> setIOMode(SaneHandle handle, SaneIOMode mode) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_setIOMode()');
    });
  }

  @override
  Future<void> start(SaneHandle handle) {
    return Future.delayed(const Duration(seconds: 1), () {
      print('sane_start()');
    });
  }
}
