import 'dart:io';
import 'dart:typed_data';

import 'package:sane/sane.dart';

void main(List<String> args) async {
  final sane = SaneIsolate(sane: Sane());
  await sane.spawn();

  await sane.init();

  final devices = await sane.getDevices(localOnly: true);
  for (var device in devices) {
    print('Device found: ${device.name}');
  }

  final handle = await sane.openDevice(devices.first);

  final optionDescriptors = await sane.getAllOptionDescriptors(handle);

  for (var optionDescriptor in optionDescriptors) {
    if (optionDescriptor.name == 'mode') {
      await sane.controlStringOption(
        handle: handle,
        index: optionDescriptor.index,
        action: SaneAction.setValue,
        value: 'Color',
      );
      break;
    }
  }

  await sane.start(handle);

  final parameters = await sane.getParameters(handle);
  print('Parameters: format(${parameters.format}), depth(${parameters.depth})');

  final rawPixelDataList = <Uint8List>[];
  Uint8List? bytes;
  while (true) {
    bytes = await sane.read(handle, parameters.bytesPerLine);
    if (bytes.isEmpty) break;
    rawPixelDataList.add(bytes);
  }

  await sane.cancel(handle);
  await sane.close(handle);
  await sane.exit();

  sane.kill();

  Uint8List mergeUint8Lists(List<Uint8List> lists) {
    int totalLength = lists.fold(0, (length, list) => length + list.length);
    Uint8List result = Uint8List(totalLength);
    int offset = 0;
    for (var list in lists) {
      result.setRange(offset, offset + list.length, list);
      offset += list.length;
    }

    return result;
  }

  final file = File('./output.ppm');
  file.writeAsStringSync(
    "P6\n${parameters.pixelsPerLine} ${parameters.lines}\n255\n",
    mode: FileMode.write,
  );
  final rawPixelData = mergeUint8Lists(rawPixelDataList);
  file.writeAsBytesSync(rawPixelData, mode: FileMode.append);
}
