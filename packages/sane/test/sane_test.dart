import 'package:sane/src/impl/sane_sync.dart';
import 'package:test/test.dart';

void main() {
  test('Sane init test', () {
    expect(Sane.new, returnsNormally);
  });
}
