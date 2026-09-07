// `settings.import`'s three states, and the one rule that shapes all of them.
//
// SPEC.md §6 §4.3: "Nothing is written before Confirm. The preview is
// mandatory, cannot be skipped, and reaching it has changed nothing on the
// device." So the preview state holds a PLAN and not a promise — the plan is
// what `BackupReader` produced, and the reader writes nothing to produce it.
//
// A sealed state rather than a bag of nullable fields: the progress state has
// no buttons, the result state has no comparison, and a screen that read the
// wrong half of one object would render a Cancel the user could not use.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:odova/features/backup/domain/import_preview.dart';
import 'package:odova/features/backup/domain/import_warning.dart';

/// What the modal is showing.
@immutable
sealed class ImportScreenState {
  const ImportScreenState();
}

/// §4.3's preview. Nothing has been written to reach it.
final class ImportPreviewState extends ImportScreenState {
  /// Creates the preview.
  const ImportPreviewState({
    required this.variant,
    required this.fileName,
    required this.exportedAtUtcMs,
    required this.comparison,
    required this.plan,
  });

  /// Which of §4.3's three this is.
  final PreviewVariant variant;

  /// The picked file's name, rendered forced-LTR.
  final String fileName;

  /// When the file was written, for the header line.
  final int? exportedAtUtcMs;

  /// NOW → AFTER, every record type.
  final List<ImportCountRow> comparison;

  /// What would happen. Held, not applied.
  final ImportPlan plan;

  /// The warnings, in the order the reader produced them.
  List<ImportWarning> get warnings => plan.warnings;
}

/// The import is running. No buttons, and no way out.
///
/// §13: "the progress state is non-cancellable and disables swipe-down
/// dismissal". Past the swap there is nothing to cancel BACK to, and offering
/// a Cancel that cannot work is worse than offering none.
final class ImportProgressState extends ImportScreenState {
  /// Creates the progress state.
  const ImportProgressState();
}

/// It finished.
///
/// A state and not a snackbar when anything was skipped: a snackbar cannot
/// carry a list, and a count that quietly dropped three things must be
/// acknowledged by a tap.
final class ImportResultState extends ImportScreenState {
  /// Creates the result.
  const ImportResultState({
    required this.vehicles,
    required this.records,
    required this.skipped,
  });

  /// How many vehicles are now on the phone.
  final int vehicles;

  /// How many records are now on the phone.
  final int records;

  /// What could not be read.
  final List<SkippedEntry> skipped;

  /// Whether the modal may dismiss itself.
  ///
  /// Only with nothing skipped. Everything else holds until the user has seen
  /// the list.
  bool get canDismissItself => skipped.isEmpty;
}

/// Applies [plan]. Returns the vehicle and record counts, or null on failure.
///
/// A typedef rather than a one-method interface — `one_member_abstracts` is
/// right that a class here buys nothing, and the port is genuinely one verb:
/// everything else in the flow is a read that has already happened.
typedef ApplyImport =
    Future<({int vehicles, int records})?> Function(ImportPlan plan);

/// Nothing wired in.
///
/// Named rather than throwing, so a confirm on an unwired build returns the
/// user to the preview instead of crashing the modal they were trying to
/// leave.
Future<({int vehicles, int records})?> noImportApply(ImportPlan plan) async =>
    null;

/// The action the screen calls.
final Provider<ApplyImport> importActionsProvider = Provider<ApplyImport>(
  (ref) => noImportApply,
);

/// The state the modal opens on, supplied by whoever picked the file.
final Provider<ImportScreenState> importInitialStateProvider =
    Provider<ImportScreenState>(
      (ref) => throw UnimplementedError(
        'settings.import is only reachable with a plan — the picker builds '
        'one and overrides this. A modal that opened without one would be a '
        'preview of nothing.',
      ),
    );

/// The modal's notifier.
class ImportNotifier extends Notifier<ImportScreenState> {
  @override
  ImportScreenState build() => ref.watch(importInitialStateProvider);

  /// Applies the plan. The one write in the whole flow.
  Future<void> confirm() async {
    final current = state;
    if (current is! ImportPreviewState) return;

    state = const ImportProgressState();
    final result = await ref.read(importActionsProvider)(current.plan);

    if (result == null) {
      // Back to the preview, with the file unchanged and the phone unchanged.
      // §5.2's promise is that a failed import changes nothing, and returning
      // the user to the screen they were on is what makes that visible.
      state = current;
      return;
    }

    state = ImportResultState(
      vehicles: result.vehicles,
      records: result.records,
      skipped: [
        for (final warning in current.warnings)
          if (warning is SkippedRecords) ...warning.entries,
      ],
    );
  }
}

/// The modal's state.
final NotifierProvider<ImportNotifier, ImportScreenState> importScreenProvider =
    NotifierProvider<ImportNotifier, ImportScreenState>(
      ImportNotifier.new,
    );
