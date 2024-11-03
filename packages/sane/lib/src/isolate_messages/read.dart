import 'dart:typed_data';

import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class ReadMessage implements IsolateMessage {
  ReadMessage({
    required this.handle,
    required this.bufferSize,
  });

  final SaneHandle handle;
  final int bufferSize;
}

class ReadResponse implements IsolateResponse {
  ReadResponse({
    required this.bytes,
  });

  final Uint8List bytes;
}
