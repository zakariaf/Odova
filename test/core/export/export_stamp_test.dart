// The four values that say who wrote a file, and why they are one object.
@TestOn('vm')
library;

import 'dart:io';

import 'package:odova/core/export/export_stamp.dart';
import 'package:test/test.dart';

void main() {
  test('it compares by value, so two stamps of one export are equal', () {
    // A stamp travels from `bootstrap` into a projection and out into an
    // envelope. Identity equality would make a test that rebuilt it fail for
    // no reason a reader could see.
    const a = ExportStamp(
      nowUtcMs: 1788374460000,
      appVersion: '1.0.0',
      appBuild: '42',
      platform: 'android',
    );
    const b = ExportStamp(
      nowUtcMs: 1788374460000,
      appVersion: '1.0.0',
      appBuild: '42',
      platform: 'android',
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('every identity field is required', () {
    // The whole reason this type exists. The four were once loose parameters
    // with placeholder defaults — `nowUtcMs = 0, appVersion = ''` — and the
    // one production caller passed none, so every pre-migration safety copy on
    // every phone was stamped 1970-01-01 by an app with no name, on the ONE
    // file §6.4.4 calls the escape route.
    //
    // Asserted over the SOURCE, because "the compiler asks" is a property of
    // the declaration and there is no way to call it wrongly to prove it.
    final source = File(
      'lib/core/export/export_stamp.dart',
    ).readAsStringSync();

    for (final field in const [
      'nowUtcMs',
      'appVersion',
      'appBuild',
      'platform',
    ]) {
      expect(source, contains('required this.$field'), reason: field);
    }
    // The offset is the one exception, and it is defaulted on purpose: a
    // migration runs before the timezone database is certainly loaded, and a
    // wrong offset on a file nobody reads by hand is a smaller lie than a
    // crash on cold launch.
    expect(source, contains('this.localOffset = Duration.zero'));
  });
}
