import 'package:sane/src/sane.dart';
import 'package:test/test.dart';

void main() {
  test('Sane init test', () {
    expect(Sane.new, returnsNormally);
  });
}
