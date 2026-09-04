// CalmStatusStyle is the ONE place a DueState becomes a colour, a silhouette,
// a word and an action.
//
// SPEC.md §1: never guess in a way that looks like fact. Most of what this file
// decides is how the app draws "we do not know" — and the two states that mean
// it must not borrow the palette of the two that mean something definite.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';

import '../../support/calm_ramps.dart';
import '../../support/calm_theme_harness.dart';
import '../../support/contrast.dart';

/// A stand-in for the generated `AppLocalizations`, which EPIC-04 brings.
class _Strings implements CalmStatusStrings {
  @override
  String get statusOverdue => 'overdue';
  @override
  String get statusDue => 'due';
  @override
  String get statusDueSoon => 'due soon';
  @override
  String get statusOk => 'ok';
  @override
  String get statusUnknown => 'unknown';
  @override
  String get statusNeedsOdometer => 'needs odometer';
}

void main() {
  final themes = {'light': calmColorsLight, 'dark': calmColorsDark};

  test('every state resolves to its own family, whole', () {
    // The ramp travels in one piece. Four separate fields would let resolve
    // pair overdue.base with due.ink and nothing would notice.
    for (final MapEntry(key: theme, value: colours) in themes.entries) {
      final ramps = rampsOf(colours);

      // Every DueState, not every ramp: `business` is the personal/business
      // split rather than a due state, and has no member to resolve from.
      for (final state in DueState.values) {
        final ramp = ramps[state.name]!;
        final name = state.name;
        final style = CalmStatusStyle.resolve(colours, state);

        expect(style.ramp, ramp, reason: '$theme $name');
        expect(style.base, ramp.base, reason: '$theme $name base');
        expect(style.ink, ramp.ink, reason: '$theme $name ink');
        expect(style.tint, ramp.tint, reason: '$theme $name tint');
        expect(style.edge, ramp.edge, reason: '$theme $name edge');
      }
    }
  });

  test('the six marks are six distinguishable silhouettes', () {
    // Colour is one signal of three, and it is the one that does not survive
    // grayscale, a colour-blind user or a phone in direct sun. Two states that
    // share a silhouette have thrown that signal away.
    final marks = {
      for (final state in DueState.values)
        state: CalmStatusStyle.resolve(calmColorsLight, state).mark,
    };

    final byShape = <(double, double, double), List<DueState>>{};
    for (final MapEntry(key: state, value: mark) in marks.entries) {
      byShape
          .putIfAbsent(
            (mark.diameter, mark.strokeWidth, mark.opacity),
            () => <DueState>[],
          )
          .add(state);
    }

    // `overdue` and `ok` deliberately share the 12pt filled disc: they are the
    // two states the user can act on and they are never adjacent — one is the
    // primary card, the other replaces it with the all-clear. Everything else
    // is distinct.
    final collisions = byShape.values.where((s) => s.length > 1).toList();
    expect(collisions, [
      [DueState.overdue, DueState.ok],
    ], reason: 'the marks are $marks');
  });

  test('the two uncertain states have the faintest marks, and neither borrows '
      'ok or overdue', () {
    final unknown = CalmStatusStyle.resolve(calmColorsLight, DueState.unknown);
    final needs = CalmStatusStyle.resolve(
      calmColorsLight,
      DueState.needsOdometer,
    );
    final overdue = CalmStatusStyle.resolve(calmColorsLight, DueState.overdue);
    final ok = CalmStatusStyle.resolve(calmColorsLight, DueState.ok);

    for (final style in [unknown, needs]) {
      expect(style.isUncertain, isTrue);
      // An app that cannot say when must not look like one making an
      // accusation, and must not look like one giving the all-clear either.
      expect(style.base, isNot(overdue.base));
      expect(style.base, isNot(ok.base));
      expect(
        style.mark.isFilled,
        isFalse,
        reason:
            'a filled disc reads as a '
            'statement; these two are rings',
      );
    }

    // They differ from each other too, and only by opacity — same diameter,
    // same stroke — so grayscale still separates them.
    expect(unknown.mark.diameter, needs.mark.diameter);
    expect(unknown.mark.strokeWidth, needs.mark.strokeWidth);
    expect(unknown.mark.opacity, isNot(needs.mark.opacity));
  });

  test('a state the engine is only guessing at asks for a reading', () {
    // SPEC.md §9's estimate table: at `confidence = default` the card reads
    // "Odova needs a reading to say when" and its action is Update odometer —
    // whatever the state. "Log it" is the one action that cannot resolve this:
    // the app does not know when the item is due, and doing the job does not
    // tell it.
    for (final state in DueState.values) {
      final style = CalmStatusStyle.resolve(calmColorsLight, state);

      for (final confidence in RateConfidence.values) {
        final expected =
            style.isUncertain || confidence == RateConfidence.defaulted
            ? 'action.updateOdometer'
            : 'action.logIt';
        expect(
          style.actionKey(confidence),
          expected,
          reason: '${state.name} at ${confidence.name}',
        );
      }
    }

    // The case the skill's own example gets wrong, named so it cannot
    // regress: a measured due-soon item logs, the same item at `defaulted`
    // asks for a reading.
    final dueSoon = CalmStatusStyle.resolve(calmColorsLight, DueState.dueSoon);
    expect(dueSoon.actionKey(RateConfidence.measured), 'action.logIt');
    expect(
      dueSoon.actionKey(RateConfidence.defaulted),
      'action.updateOdometer',
    );
  });

  test('ok is the only state that does not show on Home', () {
    // `ok` is rendered as CalmAllClear instead of a card.
    for (final state in DueState.values) {
      expect(
        CalmStatusStyle.resolve(calmColorsLight, state).showsOnHome,
        state != DueState.ok,
        reason: state.name,
      );
    }
  });

  test('every state has a word, and no widget builds one', () {
    // The label arrives from the app's localizations, so a status sentence is
    // one ICU message and nothing concatenates it.
    final strings = _Strings();
    final words = {
      for (final state in DueState.values)
        state: CalmStatusStyle.resolve(calmColorsLight, state).label(strings),
    };

    expect(words.values.toSet(), hasLength(DueState.values.length));
    expect(words[DueState.needsOdometer], 'needs odometer');
  });

  test('a figure is shown only when the engine actually measured one', () {
    // SPEC.md §1: an estimate is prefixed `~`, a projection is fuzzy, and an
    // item with no history says `unknown` rather than a number that looks
    // like a fact.
    for (final state in DueState.values) {
      for (final confidence in RateConfidence.values) {
        final allowed = mayShowFigure(state, confidence);
        if (CalmStatusStyle.resolve(calmColorsLight, state).isUncertain ||
            confidence == RateConfidence.defaulted) {
          expect(allowed, isFalse, reason: '${state.name}/${confidence.name}');
        } else {
          expect(allowed, isTrue, reason: '${state.name}/${confidence.name}');
        }
      }
    }
  });

  test('the text pair of every resolved style clears 4.5:1', () {
    // `ink` on `tint` is the pair a badge and a status line actually use, and
    // it is what makes `ink` safe as a text colour when `base` is not.
    for (final MapEntry(key: theme, value: colours) in themes.entries) {
      for (final state in DueState.values) {
        final style = CalmStatusStyle.resolve(colours, state);
        expect(
          contrastRatio(style.ink, style.tint),
          greaterThanOrEqualTo(bodyTextContrast),
          reason: '$theme ${state.name}',
        );
      }
    }
  });

  testWidgets('CalmStatusStyle.of resolves against the ambient theme', (
    tester,
  ) async {
    for (final (mode, colours) in [
      (ThemeMode.light, calmColorsLight),
      (ThemeMode.dark, calmColorsDark),
    ]) {
      late CalmStatusStyle style;
      await pumpCalm(
        tester,
        (context) => style = CalmStatusStyle.of(context, DueState.overdue),
        themeMode: mode,
      );

      expect(style.ramp, colours.overdue, reason: '$mode');
    }
  });
}
