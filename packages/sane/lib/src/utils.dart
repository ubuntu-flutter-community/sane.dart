abstract class SaneUtils {
  static int versionMajor(int versionCode) {
    return (versionCode >> 24) & 0xff;
  }

  static int versionMinor(int versionCode) {
    return (versionCode >> 16) & 0xff;
  }

  static int versionBuild(int versionCode) {
    return (versionCode >> 0) & 0xffff;
  }

  static String version(int versionCode) {
    return '${versionMajor(versionCode)}.${versionMinor(versionCode)}.${versionBuild(versionCode)}';
  }
}
