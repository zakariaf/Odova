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
    final informal = RegExp(
      r'\b(du|dir|dich|dein\w*)\b',
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
