import 'package:logging/logging.dart';
import 'package:sane/sane.dart';
import 'package:test/test.dart';

void main() {
  late Sane sane;

  setUp(() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  });

  test('can instantiate', () {
    sane = Sane();
  });

  test('same instance on repeated instantiation', () {
    final newSane = Sane();
    expect(sane, equals(newSane));
  });

  test('can exit', () {
    expect(sane.dispose, returnsNormally);
  });

  test('throws upon use', () {
    expect(
      () => sane.getDevices(localOnly: true),
      throwsA(isA<SaneDisposedError>()),
    );
  });

  test('can reinstiate with new instance', () {
    final newSane = Sane(Sane.mock());
    expect(sane, isNot(newSane));
    sane = newSane;
  });

  test('doesn\'t throw upon use', () {
    expect(() => sane.getDevices(localOnly: true), returnsNormally);
  });
}
