import 'package:sane/sane.dart';
import 'package:test/test.dart';

void main() {
  late Sane sane;

  test('can instantiate', () {
    sane = Sane();
  });

  test('same instance on repeated instantiation', () {
    final newSane = Sane();
    expect(sane, equals(newSane));
  });

  test('can exit', () {
    expect(sane.exit, returnsNormally);
  });

  test('throws upon use', () {
    expect(
      () => sane.getDevices(localOnly: true),
      throwsA(isA<SaneDisposedError>()),
    );
  });

  test('can reinstiate with new instance', () {
    final newSane = Sane();
    expect(sane, isNot(newSane));
    sane = newSane;
  });

  test('doesn\'t throw upon use', () {
    expect(() => sane.getDevices(localOnly: true), returnsNormally);
  });
}
