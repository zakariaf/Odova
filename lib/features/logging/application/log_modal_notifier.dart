// The four drafts the log modal holds, and nothing else.
//
// SPEC.md §10: "Per-segment drafts live in memory for the life of the modal,
// never in the database — a mis-tap on the segment bar costs nothing." So this
// is state and not storage, and the only way out of it is Save.
//
// It also owns the answer to "is there anything to lose", which is asked of the
// MODAL and not of the visible body: a user who typed into Expense and switched
// to Fill-up still has something to lose, and a guard that asked only the
// segment on screen would let it go silently.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/routing/routes.dart';

/// One segment's in-memory draft.
///
/// Deliberately small for now: the four form bodies grow their own fields onto
/// it as they are built, and a shape invented ahead of its first reader is a
/// shape that turns out to be wrong.
@immutable
class LogDraft {
  /// Creates a draft.
  const LogDraft({this.note = ''});

  /// The free-text note every segment carries.
  final String note;

  /// Whether the user has put anything into this segment.
  bool get isDirty => note.isNotEmpty;

  /// A copy with [note] replaced.
  LogDraft withNote(String value) => LogDraft(note: value);
}

/// Which segment is showing, and what is in all four.
@immutable
class LogModalState {
  /// Creates the state.
  const LogModalState({
    this.segment = LogType.fillUp,
    this.drafts = const {},
  });

  /// The segment on screen. §10 opens on Fill-up "whatever the caller".
  final LogType segment;

  /// The four drafts, by segment. Absent means untouched.
  final Map<LogType, LogDraft> drafts;

  /// [type]'s draft, empty if it has none yet.
  LogDraft draftFor(LogType type) => drafts[type] ?? const LogDraft();

  /// Whether ANY segment has something in it.
  bool get isDirty => drafts.values.any((d) => d.isDirty);

  /// A copy showing [type]. Switching is not an edit — otherwise every mis-tap
  /// on the segment bar would earn a discard dialog on the way out.
  LogModalState on(LogType type) =>
      LogModalState(segment: type, drafts: drafts);

  /// A copy with [type]'s note replaced.
  LogModalState withNote(LogType type, String note) => LogModalState(
    segment: segment,
    drafts: {...drafts, type: draftFor(type).withNote(note)},
  );

  /// Every draft dropped.
  ///
  /// ALL FOUR, per §10 — a user who mis-tapped the segment bar twice and then
  /// discarded said one thing, not four. The segment stays where it is: the
  /// modal is about to close, and moving it first would be a visible flinch.
  LogModalState discarded() => LogModalState(segment: segment);
}

/// The log modal's drafts, for the life of one modal.
///
/// `autoDispose`, which is what "for the life of the modal" means mechanically:
/// the drafts go when the route does, and a second opening starts empty rather
/// than inheriting what the last one abandoned.
final NotifierProvider<LogModalNotifier, LogModalState> logModalProvider =
    NotifierProvider.autoDispose<LogModalNotifier, LogModalState>(
      LogModalNotifier.new,
    );

/// Holds the four drafts.
class LogModalNotifier extends Notifier<LogModalState> {
  @override
  LogModalState build() => const LogModalState();

  /// Records a note on [type].
  void setNote(LogType type, String note) => state = state.withNote(type, note);

  /// Drops all four drafts.
  void discard() => state = state.discarded();
}
