// Four drafts, one modal, and nothing on disk until Save.
//
// SPEC.md §10: "Per-segment drafts live in memory for the life of the modal,
// never in the database — a mis-tap on the segment bar costs nothing." And
// Discard drops every one of them, not only the visible one.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/application/log_modal_notifier.dart';

void main() {
  test('each segment keeps its own draft', () {
    // Type into Fill-up, switch to Expense, switch back: still there.
    var state = const LogModalState();

    state = state.withNote(LogType.fillUp, 'Shell A61');
    state = state.on(LogType.expense);
    state = state.withNote(LogType.expense, 'Allianz');
    state = state.on(LogType.fillUp);

    expect(state.draftFor(LogType.fillUp).note, 'Shell A61');
    expect(state.draftFor(LogType.expense).note, 'Allianz');
    expect(state.segment, LogType.fillUp);
  });

  test('an untouched modal is not dirty', () {
    expect(const LogModalState().isDirty, isFalse);
  });

  test('a keystroke on ANY segment makes the modal dirty', () {
    // §10's dismissal rule is about the modal, not the visible body: a user
    // who typed into Expense and switched to Fill-up still has something to
    // lose.
    final state = const LogModalState().withNote(LogType.expense, 'x');

    expect(state.isDirty, isTrue);
  });

  test('discard drops EVERY segment', () {
    // §10, verbatim: Discard "drops every segment's draft". A user who
    // mis-tapped the segment bar twice and then discarded said one thing, not
    // four.
    final state = const LogModalState()
        .withNote(LogType.fillUp, 'a')
        .withNote(LogType.service, 'b')
        .withNote(LogType.expense, 'c')
        .withNote(LogType.odometer, 'd')
        .discarded();

    for (final type in LogType.values) {
      expect(state.draftFor(type).note, isEmpty, reason: type.wire);
    }
    expect(state.isDirty, isFalse);
  });

  test('switching segments is not an edit', () {
    // Three switches and the modal is still clean — otherwise every mis-tap
    // would earn a discard dialog on the way out.
    final state = const LogModalState()
        .on(LogType.service)
        .on(LogType.expense)
        .on(LogType.fillUp);

    expect(state.isDirty, isFalse);
  });
}
