// The More section, once, for the three forms that have one.
//
// SPEC.md §10 puts the optional fields behind More on `log.fillup`,
// `log.service` and `log.expense`, and the rule that decides the design is the
// same on all three: "More is collapsed by default and collapsed again next
// time: nothing inside it changes a consumption figure."
//
// Two consequences, and they are why this is one file rather than three:
//
//   1. **Nothing in here is ever prefilled.** §10 offers recent stations as
//      chips and says they "never auto-fill", for the same reason the odometer
//      is never prefilled from an estimate — a value that arrives as a default
//      gets saved unread.
//   2. **`log.odometer` does not have one at all.** §10: "Two fields. No
//      notes, no category, no More section — this screen exists to be finished
//      before the user changes their mind; one more optional field would be a
//      net loss." That is a rule about the SCREEN, so it lives beside the
//      others rather than as an absence somewhere else.
import 'package:flutter/material.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// Whether [type] has a More section at all.
bool logTypeHasMore(LogType type) => type != LogType.odometer;

/// Opens the More section for [type].
Future<void> showLogMoreSheet(
  BuildContext context, {
  required LogType type,
  required FillUpDraft fillUp,
  required ValueChanged<FillUpDraft> onFillUpChanged,
}) => CalmSheet.show<void>(
  context,
  builder: (context) => LogMoreSheet(
    type: type,
    fillUp: fillUp,
    onFillUpChanged: onFillUpChanged,
  ),
);

/// §10's More section.
class LogMoreSheet extends StatefulWidget {
  /// Creates the sheet.
  const LogMoreSheet({
    required this.type,
    required this.fillUp,
    required this.onFillUpChanged,
    super.key,
  });

  /// Which form's More this is.
  final LogType type;

  /// The fill-up draft, when [type] is `log.fillup`.
  final FillUpDraft fillUp;

  /// Called with the draft after every change.
  final ValueChanged<FillUpDraft> onFillUpChanged;

  @override
  State<LogMoreSheet> createState() => _LogMoreSheetState();
}

class _LogMoreSheetState extends State<LogMoreSheet> {
  late final TextEditingController _station = TextEditingController(
    text: widget.fillUp.station,
  );
  late final TextEditingController _grade = TextEditingController(
    text: widget.fillUp.grade,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.fillUp.notes,
  );

  @override
  void dispose() {
    _station.dispose();
    _grade.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return CalmSheet(
      title: l10n.logMoreRow,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: space.s4,
          children: [
            if (widget.type == LogType.fillUp) ..._fillUpFields(l10n),
          ],
        ),
      ],
    );
  }

  List<Widget> _fillUpFields(AppLocalizations l10n) => [
    CalmField(
      label: l10n.logFillUpStation,
      controller: _station,
      onChanged: (value) =>
          widget.onFillUpChanged(widget.fillUp.withStation(value)),
    ),
    CalmField(
      label: l10n.logFillUpGrade,
      controller: _grade,
      onChanged: (value) =>
          widget.onFillUpChanged(widget.fillUp.withGrade(value)),
    ),
    CalmField(
      label: l10n.logNotes,
      controller: _notes,
      onChanged: (value) =>
          widget.onFillUpChanged(widget.fillUp.withNotes(value)),
    ),
    CalmRowGroup(
      rows: [
        CalmListRow.switchRow(
          title: l10n.logFillUpChainBroken,
          // The consequence, stated. It silently changes what the NEXT full
          // tank means — consumption starts fresh from here rather than
          // spanning a gap the app cannot see — and nothing else on the form
          // says so.
          subtitle: l10n.logFillUpChainBrokenHint,
          value: widget.fillUp.chainBroken,
          onToggle: () => widget.onFillUpChanged(
            widget.fillUp.withChainBroken(broken: !widget.fillUp.chainBroken),
          ),
        ),
      ],
    ),
  ];
}
