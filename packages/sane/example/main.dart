// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/impl/sane_mock.dart';
import 'package:sane/src/impl/sane_native.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final sane = NativeSane(MockSane());

  final version = await sane.initialize();

  print(version);

  final devices = await sane.getDevices(localOnly: false);
  for (final device in devices) {
    print('Device found: ${device.name}');
  }
  if (devices.isEmpty) {
    print('No device found');
    return;
  }

  final device = devices.first;

  final optionDescriptors = await device.getAllOptionDescriptors();

  for (final optionDescriptor in optionDescriptors) {
    if (optionDescriptor.name == 'mode') {
      await device.controlStringOption(
        optionDescriptor.index,
        SaneAction.setValue,
        'Color',
      );
      break;
    }
  }

  await device.start();

  final parameters = await device.getParameters();
  print('Parameters: format(${parameters.format}), depth(${parameters.depth})');

  final rawPixelDataList = <Uint8List>[];
  Uint8List? bytes;
  while (true) {
    bytes = await device.read(bufferSize: parameters.bytesPerLine);
    if (bytes.isEmpty) break;
    rawPixelDataList.add(bytes);
  }

  await device.cancel();
  await device.close();

  Uint8List mergeUint8Lists(List<Uint8List> lists) {
    final totalLength = lists.fold(0, (length, list) => length + list.length);
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final list in lists) {
      result.setRange(offset, offset + list.length, list);
      offset += list.length;
    }

    return result;
  }

  final file = File('./output.ppm');
  file.writeAsStringSync(
    'P6\n${parameters.pixelsPerLine} ${parameters.lines}\n255\n',
    mode: FileMode.write,
  );
  final rawPixelData = mergeUint8Lists(rawPixelDataList);
  file.writeAsBytesSync(rawPixelData, mode: FileMode.append);

  await sane.dispose();
}
