// SPEC.md §5's register decision: formal, in the languages that distinguish.
//
// German *Sie*, French *vous*. Odova is addressing a stranger about their most
// expensive possession and their money, and the informal address assumes a
// relationship the app has not earned.
//
// **This exists because review cannot catch it.** Exactly one German string in
// the app had drifted to *du* — `discardBody`, against ten that used *Sie* —
// and it survived a review pass, a parity pass and a merge, because nobody on
// this project reads all six languages. A gate does.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<MapEntry<String, String>> _messages(String locale) => _arb(locale)
    .entries
    .where((e) => !e.key.startsWith('@'))
    .map((e) => MapEntry(e.key, e.value as String));

void main() {
  test('German addresses the user as Sie, never du', () {
    // Every one of these is unambiguously the informal pronoun in German —
    // there is no noun `du`, `dir`, `dich` or `dein-`. Capitalised `Sie` needs
    // no counterpart rule: it is the correct form and it is also the plural
    // `sie`, so a positive test for it would pass on the wrong word.
    //
    // ONE exception, and it is the gate's own bug rather than a loophole:
    // `dein\w*` matches `deinstallieren`, which is the verb "to uninstall" and
    // has nothing to do with the possessive. It cried wolf on a correct string
    // — "wenn Sie Odova deinstallieren" — and this file's own comment says
    // what happens to a gate that does that. `dein(?!stall)` also covers
    // `Deinstallation`, and no German possessive begins `deinstall-`, so it
    // still catches `deine`, `deinem` and `deiner`.
    final informal = RegExp(
      r'\b(du|dir|dich|dein(?!stall)\w*)\b',
      caseSensitive: false,
      unicode: true,
    );
    final offenders = [
      for (final m in _messages('de'))
        if (informal.hasMatch(m.value)) '${m.key}: ${m.value}',
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'SPEC.md §5: German is formal. Rewrite with Sie/Ihr-, or change the '
          'spec deliberately and delete this test.',
    );
  });

  test('the German net catches the possessive and not the verb', () {
    // Guard the guard, both ways. Without the second half this is a gate that
    // has been widened until it catches nothing; without the first it is a
    // gate that blocks the word for "uninstall".
    final informal = RegExp(
      r'\b(du|dir|dich|dein(?!stall)\w*)\b',
      caseSensitive: false,
      unicode: true,
    );

    for (final caught in const [
      'Hast du das gesichert?',
      'Wir zeigen dir deine Einträge.',
      'Das gehört dir.',
      'deinem Fahrzeug',
    ]) {
      expect(informal.hasMatch(caught), isTrue, reason: caught);
    }
    for (final allowed in const [
      'wenn Sie Odova deinstallieren',
      'Die Deinstallation entfernt die Kopien.',
      'Ihre Einträge',
    ]) {
      expect(informal.hasMatch(allowed), isFalse, reason: allowed);
    }
  });

  test('French addresses the user as vous, never tu', () {
    // A NET rather than a proof, and deliberately so. `tu`, `toi` and the
    // elided `t'` are unambiguous, but `ton` and `ta` are also the noun "tone"
    // and a possessive that a false positive would block a legitimate string
    // over — so they are not matched. A gate that cries wolf gets deleted, and
    // then it catches nothing at all.
    final informal = RegExp(
      r"\b(tu|toi)\b|\bt['’](es|as)\b",
      caseSensitive: false,
      unicode: true,
    );
    final offenders = [
      for (final m in _messages('fr'))
        if (informal.hasMatch(m.value)) '${m.key}: ${m.value}',
    ];
    expect(offenders, isEmpty, reason: 'SPEC.md §5: French is formal.');
  });

  test('the gate is looking at something', () {
    // A regex that matches nothing passes forever. Both locales must actually
    // carry the formal forms, or the two tests above are green because the
    // files are empty rather than because the copy is right.
    expect(
      _messages(
        'de',
      ).where((m) => RegExp(r'\b(Sie|Ihr\w*)\b').hasMatch(m.value)),
      isNotEmpty,
    );
    expect(
      _messages('fr').where(
        (m) => RegExp(r'\b([Vv]ous|[Vv]otre|[Vv]os)\b').hasMatch(m.value),
      ),
      isNotEmpty,
    );
  });
}
