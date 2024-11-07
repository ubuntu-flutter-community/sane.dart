class SaneCredentials {
  SaneCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

enum SaneFrameFormat {
  gray,
  rgb,
  red,
  green,
  blue;
}

class SaneParameters {
  SaneParameters({
    required this.format,
    required this.lastFrame,
    required this.bytesPerLine,
    required this.pixelsPerLine,
    required this.lines,
    required this.depth,
  });

  final SaneFrameFormat format;
  final bool lastFrame;
  final int bytesPerLine;
  final int pixelsPerLine;
  final int lines;
  final int depth;
}

enum SaneOptionValueType {
  bool,
  int,
  fixed,
  string,
  button,
  group;
}

enum SaneOptionUnit {
  none,
  pixel,
  bit,
  mm,
  dpi,
  percent,
  microsecond;
}

enum SaneOptionCapability {
  softSelect,
  hardSelect,
  softDetect,
  emulated,
  automatic,
  inactive,
  advanced;
}

abstract class SaneOptionConstraint {}

class SaneOptionConstraintRange<T extends num> implements SaneOptionConstraint {
  SaneOptionConstraintRange({
    required this.min,
    required this.max,
    required this.quant,
  });

  final T min;

  final T max;

  final T quant;
}

class SaneOptionConstraintWordList<T extends num>
    implements SaneOptionConstraint {
  SaneOptionConstraintWordList({
    required this.wordList,
  });

  final List<T> wordList;
}

class SaneOptionConstraintStringList implements SaneOptionConstraint {
  SaneOptionConstraintStringList({
    required this.stringList,
  });

  final List<String> stringList;
}

class SaneOptionDescriptor {
  SaneOptionDescriptor({
    required this.index,
    required this.name,
    required this.title,
    required this.desc,
    required this.type,
    required this.unit,
    required this.size,
    required this.capabilities,
    required this.constraint,
  });

  final int index;
  final String? name;
  final String? title;
  final String? desc;
  final SaneOptionValueType type;
  final SaneOptionUnit unit;
  final int size;
  final List<SaneOptionCapability> capabilities;
  final SaneOptionConstraint? constraint;
}

enum SaneAction {
  getValue,
  setValue,
  setAuto;
}

enum SaneOptionInfo {
  inexact,
  reloadOptions,
  reloadParams;
}

class SaneOptionResult<T> {
  SaneOptionResult({
    required this.result,
    required this.infos,
  });

  final T result;
  final List<SaneOptionInfo> infos;
}
