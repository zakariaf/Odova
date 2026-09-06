// §11: "It is live until the snackbar dismisses — 6 seconds, or the next
// navigation."
//
// Two clauses, and the second is the one that gets dropped. A snackbar's own
// duration expires it on time; nothing expires it when the user taps a row and
// walks away from the screen the undo belonged to. An Undo that survives a
// navigation reverts a write the user has stopped thinking about, from a
// screen that is no longer showing what it would revert.
@TestOn('vm')
library;

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:odova/features/history/application/undo_window.dart';
import 'package:test/test.dart';

const _window = Duration(seconds: 6);

void main() {
  test('an offered undo is live, and dies when the window elapses', () {
    fakeAsync((async) {
      final undo = UndoWindow();
      addTearDown(undo.dispose);
      var ran = 0;

      undo.offer(window: _window, undo: () async => ran++);
      expect(undo.isLive, isTrue);

      async.elapse(const Duration(seconds: 5, milliseconds: 999));
      expect(undo.isLive, isTrue, reason: 'not a millisecond early');

      async.elapse(const Duration(milliseconds: 1));
      expect(undo.isLive, isFalse);

      unawaited(undo.invoke());
      async.flushMicrotasks();
      expect(ran, 0, reason: 'a dead undo does nothing at all');
    });
  });

  test('the next navigation kills it first', () {
    // The clause that gets dropped. Without it this passes at six seconds
    // anyway, which is why the assertion is at ONE second — before the window
    // could possibly have expired on its own.
    fakeAsync((async) {
      final undo = UndoWindow();
      addTearDown(undo.dispose);
      var ran = 0;

      undo.offer(window: _window, undo: () async => ran++);
      async.elapse(const Duration(seconds: 1));

      undo.cancel();
      expect(undo.isLive, isFalse);

      unawaited(undo.invoke());
      async.flushMicrotasks();
      expect(ran, 0);
    });
  });

  test('invoking runs the undo exactly once, however many taps arrive', () {
    // A snackbar action is a tap target, and a tap target on a phone in the
    // rain gets hit twice. Running the revert twice re-applies a pre-write
    // snapshot on top of itself, which is a second write nobody asked for.
    fakeAsync((async) {
      final undo = UndoWindow();
      addTearDown(undo.dispose);
      var ran = 0;

      undo.offer(window: _window, undo: () async => ran++);
      unawaited(undo.invoke());
      unawaited(undo.invoke());
      async.flushMicrotasks();

      expect(ran, 1);
      expect(undo.isLive, isFalse, reason: 'spent by the first tap');
    });
  });

  test('a second offer replaces the first, and the first never fires', () {
    // §11 allows one Undo. Two on screen is two undos with no way to tell
    // which is which; two in memory is worse, because the older one silently
    // reverts a write two edits back.
    fakeAsync((async) {
      final undo = UndoWindow();
      addTearDown(undo.dispose);
      final ran = <String>[];

      undo.offer(window: _window, undo: () async => ran.add('first'));
      async.elapse(const Duration(seconds: 1));
      undo.offer(window: _window, undo: () async => ran.add('second'));

      unawaited(undo.invoke());
      async.flushMicrotasks();

      expect(ran, ['second']);
    });
  });

  test('the replacement gets a full window, not the remainder of the old', () {
    fakeAsync((async) {
      final undo = UndoWindow();
      addTearDown(undo.dispose);

      undo.offer(window: _window, undo: () async {});
      async.elapse(const Duration(seconds: 5));
      undo.offer(window: _window, undo: () async {});

      async.elapse(const Duration(seconds: 5));
      expect(undo.isLive, isTrue, reason: 'the old timer did not carry over');
    });
  });

  test('dispose kills the timer, so a dead screen fires nothing', () {
    fakeAsync((async) {
      final undo = UndoWindow()
        ..offer(window: _window, undo: () async {})
        ..dispose();

      expect(undo.isLive, isFalse);
      async.elapse(const Duration(seconds: 10));
    });
  });
}
