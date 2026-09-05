// The sale form.
//
// SPEC.md §8: "**Mark as sold** opens a small form: sale date (default today,
// ≤ today) and sale price (optional). It is offered before Delete everywhere,
// because 'I sold the car' is what people mean most of the time they reach for
// Delete, and the history they are about to destroy is what made the sale worth
// more."
//
// Two fields and one rule. The sheet writes NOTHING: it returns a
// [MarkAsSoldResult] and `VehiclesNotifier` performs the sale, the same
// division `showConfirmDeleteDialog` uses — a form with no port to the database
// cannot half-save.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/l10n/numeric_input.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// What the user agreed to.
typedef MarkAsSoldResult = ({String soldOn, int? soldPriceMinor});

/// The latest date the picker will offer, given [today].
///
/// SPEC.md §8's "≤ today", enforced where the user is rather than as an error
/// after the fact: a car sold next Tuesday is a typo, and a future `sold_on`
/// puts a sale price into a running-cost total for a month that has not
/// happened.
///
/// LOCAL midnight, because `showDatePicker` compares against local dates and a
/// UTC instant one hour into tomorrow would silently offer tomorrow.
DateTime markAsSoldLastDate(DateTime today) =>
    DateTime(today.year, today.month, today.day);

/// Asks when [vehicleName] was sold and for how much.
///
/// Returns null on cancel, and on a swipe-away. SPEC.md §7: no overlay is ever
/// dismissed into a state-changing outcome.
Future<MarkAsSoldResult?> showMarkAsSoldSheet(
  BuildContext context, {
  required String vehicleName,
}) => CalmSheet.show<MarkAsSoldResult>(
  context,
  builder: (context) => MarkAsSoldSheet(vehicleName: vehicleName),
);

/// The form, without its route.
class MarkAsSoldSheet extends ConsumerStatefulWidget {
  /// Creates the form.
  const MarkAsSoldSheet({required this.vehicleName, super.key});

  /// Named on the sheet, because a swipe on the wrong row is the mistake this
  /// is the last chance to catch.
  final String vehicleName;

  @override
  ConsumerState<MarkAsSoldSheet> createState() => _MarkAsSoldSheetState();
}

class _MarkAsSoldSheetState extends ConsumerState<MarkAsSoldSheet> {
  final _price = TextEditingController();
  late DateTime _soldOn = markAsSoldLastDate(
    ref.read(clockProvider).now().toLocal(),
  );

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  /// The price in minor units, or null when the field is empty.
  ///
  /// A THIRD state — unparseable — is what blocks the sale, and it is the only
  /// thing on this form that can.
  ({bool valid, int? minor}) _parsePrice(Currency currency, String tag) {
    final text = _price.text.trim();
    if (text.isEmpty) return (valid: true, minor: null);
    final read = normalizeNumericInput(
      text,
      groupingSeparator: groupingSeparatorFor(tag),
    );
    if (read is! NumericInputOk) return (valid: false, minor: null);
    // String arithmetic, not `double.parse(...) * minorPerMajor`. That is what
    // this line used to be, and 8,500.005 — exactly half a cent — came back as
    // 850000 rather than 850001, because the double holding it is
    // 850000.49999999994. SPEC.md §3, and `value-objects-money-and-units` in
    // one sentence: money never travels through a double.
    final minor = minorUnitsFrom(read.canonical, currency);
    if (minor == null || minor < 0) return (valid: false, minor: null);
    return (valid: true, minor: minor);
  }

  /// `YYYY-MM-DD`. Through `CivilDate`, which owns the format.
  ///
  /// The picker cannot offer a year outside 1900..today, so the fallback is
  /// unreachable from the UI — it exists because `fromDateTime` is honest about
  /// a clock that has no four-digit year.
  String _isoDate(DateTime date) =>
      (CivilDate.fromDateTime(date) ?? CivilDate.fromDateTime(DateTime(1970))!)
          .toString();

  Future<void> _pickDate() async {
    final today = markAsSoldLastDate(ref.read(clockProvider).now().toLocal());
    final picked = await showDatePicker(
      context: context,
      initialDate: _soldOn,
      // 1900 rather than the vehicle's purchase date: a classic changes hands
      // and the app does not always know when it was bought.
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked != null && mounted) setState(() => _soldOn = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final currency =
        ref.watch(settingsProvider).value?.currencyDefault ??
        Currency.tryParse('EUR')!;
    final price = _parsePrice(currency, tag);

    return CalmSheet(
      title: l10n.vehicleMarkAsSold,
      subtitle: widget.vehicleName,
      actions: [
        CalmButton(
          label: l10n.commonCancel,
          variant: CalmButtonVariant.quiet,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CalmButton(
          label: l10n.vehicleMarkAsSold,
          // SPEC.md §1: Save is never disabled without an explanation, and
          // `CalmButton` asserts that a disabled one carries a reason.
          disabledBecause: price.valid ? null : l10n.odometerNotANumberError,
          onPressed: price.valid
              ? () => Navigator.of(context).pop((
                  soldOn: _isoDate(_soldOn),
                  soldPriceMinor: price.minor,
                ))
              : null,
        ),
      ],
      children: [
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.vehicleSoldOn,
              value: formatLongDate(_isoDate(_soldOn), tag),
              onTap: _pickDate,
              showChevron: true,
            ),
          ],
        ),
        CalmField(
          label: l10n.vehicleSoldPrice,
          controller: _price,
          numeric: true,
          // A currency AFFIX rather than a symbol inside the field: the value
          // is what the user typed and the code is what the app stores it as,
          // and merging them makes the field impossible to clear.
          affix: Text(currency.code),
          errorText: price.valid ? null : l10n.odometerNotANumberError,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
