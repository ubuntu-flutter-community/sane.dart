import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sane/sane.dart';

final _logger = Logger('sane.mock');

class MockSane implements Sane {
  @override
  void dispose() => _logger.finest('disposed');

  @override
  Future<List<SaneDevDevice>> getDevices({required bool localOnly}) {
    _logger.finest('sane_get_devices()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => List.generate(3, SaneDevDevice.new),
    );
  }

  @override
  SaneVersion initialize([AuthCallback? authCallback]) {
    _logger.finest('initialized');
    return const SaneVersion.fromCode(13371337);
  }
}

class SaneDevDevice implements SaneDevice {
  const SaneDevDevice(this.index);

  final int index;

  @override
  Future<void> cancel() {
    _logger.finest('sane_cancel()');
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> close() {
    _logger.finest('sane_close()');
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  String get model => 'Model $index';

  @override
  String get name => 'Name $index';

  @override
  Future<Uint8List> read({required int bufferSize}) {
    _logger.finest('sane_read()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => Uint8List.fromList([]),
    );
  }

  @override
  Future<void> start() {
    _logger.finest('sane_start()');
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  String get type => 'Type $index';

  @override
  String? get vendor => 'Vendor $index';

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(
    int index,
  ) {
    _logger.finest('sane_getOptionDescriptor()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneOptionDescriptor(
        index: index,
        name: 'name',
        title: 'title',
        desc: 'desc',
        type: SaneOptionValueType.int,
        unit: SaneOptionUnit.none,
        size: 1,
        capabilities: [],
        constraint: null,
      ),
    );
  }

  @override
  Future<SaneParameters> getParameters() {
    _logger.finest('sane_getParameters()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneParameters(
        format: SaneFrameFormat.gray,
        lastFrame: true,
        bytesPerLine: 800,
        pixelsPerLine: 100,
        lines: 100,
        depth: 8,
      ),
    );
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors() {
    _logger.finest('sane_getAllOptionDescriptors()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => [
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
      ],
    );
  }

  @override
  Future<SaneOptionResult<bool>> controlBoolOption(
    int index,
    SaneAction action, [
    bool? value,
  ]) {
    _logger.finest('sane_controlBoolOption()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneOptionResult(result: value ?? true, infos: []),
    );
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption(int index) {
    _logger.finest('sane_controlButtonOption()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneOptionResult(result: null, infos: []),
    );
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption(
    int index,
    SaneAction action, [
    double? value,
  ]) {
    _logger.finest('sane_controlFixedOption()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneOptionResult(result: value ?? .1, infos: []),
    );
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption(
    int index,
    SaneAction action, [
    int? value,
  ]) {
    _logger.finest('sane_controlIntOption()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneOptionResult(result: value ?? 1, infos: []),
    );
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption(
    int index,
    SaneAction action, [
    String? value,
  ]) {
    _logger.finest('sane_controlStringOption()');
    return Future.delayed(
      const Duration(seconds: 1),
      () => SaneOptionResult(result: value ?? 'value', infos: []),
    );
  }
}
