// One answer to "are these the same name".
@TestOn('vm')
library;

import 'package:odova/core/l10n/folded_name.dart';
import 'package:test/test.dart';

void main() {
  test('it folds digits, bidi, case and whitespace', () {
    expect(foldedName('Golf ۲۰۱۹'), foldedName('golf 2019'));
    expect(foldedName('  Van '), foldedName('van'));
    expect(foldedName('‏The Golf'), foldedName('the golf'));
    expect(foldedName('The Golf'), isNot(foldedName('The Polo')));
  });

  test('an empty name folds to empty', () {
    // The delete dialog treats that as "never matches", which is the whole
    // reason it asks: a vehicle named "" would otherwise unlock the instant
    // the dialog opened, with nothing typed.
    expect(foldedName('   ‏'), isEmpty);
  });
}
