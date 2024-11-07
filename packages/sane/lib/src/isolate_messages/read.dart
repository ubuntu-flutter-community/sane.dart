import 'dart:typed_data';

import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class ReadMessage implements IsolateMessage<ReadResponse> {
  const ReadMessage({
    required this.deviceName,
    required this.bufferSize,
  });

  final String deviceName;
  final int bufferSize;

  @override
  Future<ReadResponse> handle(Sane sane) async {
    final device = getDevice(deviceName);
    final bytes = await device.read(bufferSize: bufferSize);
    return ReadResponse(bytes);
  }
}

class ReadResponse implements IsolateResponse {
  ReadResponse(this.bytes);

  final Uint8List bytes;
}
