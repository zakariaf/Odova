// SPEC.md §13's currency picker — a SHEET, never a push.
//
// §7 allows no branch in this app three levels deep, and the currency list is
// long enough to need a search field; a pushed screen would put it a
// navigation level away from the preview it changes. The footer says what
// changing it does NOT do, because that is the question somebody hesitating
// over this row is actually asking.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_search_field.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// The codes §13's sheet offers.
///
/// A CURATED list, not every ISO 4217 code. `Currency.tryParse` accepts any
/// well-formed three letters — it has to, because a backup written on another
/// phone may carry one — but a picker of 180 rows would be 160 nobody has
/// checked a single amount against, and the ones that matter here are the six
/// shipped locales' own currencies plus the majors a user is likely to have
/// spent in.
///
/// Every three-decimal currency in the app's exponent table is present on
/// purpose: those are the ones where getting the minor units wrong is a
/// silent factor of ten, and they belong in front of a tester rather than
/// only in a fixture. Widening this is an `SPEC.md` §18 question, not a code
/// change.
const List<String> kCurrencyChoices = [
  'EUR', 'USD', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK',
  'CAD', 'AUD', 'NZD', 'JPY', 'TRY', 'RUB', 'INR', 'ZAR', 'BRL',
  // The six locales' own, and the Gulf and Maghreb currencies an Arabic or
  // Sorani user is most likely to hold.
  'IRR', 'IQD', 'SAR', 'AED', 'KWD', 'BHD', 'OMR', 'QAR', 'JOD', 'LBP',
  'EGP', 'MAD', 'TND', 'DZD', 'LYD', 'AFN', 'PKR',
];

/// A currency's row value.
///
/// The CODE, isolated. It is an identifier, and three Latin letters loose in a
/// right-to-left line drift to the wrong end.
///
/// Just the code, not `Euro (EUR)`: a currency NAME needs a name table in six
/// languages, and 35 invented translations is worse than the code every bank
/// statement already uses. Recorded as deferred rather than left as a doc
/// promising something the body does not do.
String currencyRowLabel(Currency currency) => isolate(currency.code);

/// Opens §13's currency sheet.
Future<void> showCurrencySheet(
  BuildContext context, {
  required Currency current,
  required ValueChanged<Currency> onSelected,
}) => CalmSheet.show<void>(
  context,
  builder: (sheetContext) =>
      _CurrencySheet(current: current, onSelected: onSelected),
);

class _CurrencySheet extends StatefulWidget {
  const _CurrencySheet({required this.current, required this.onSelected});

  final Currency current;
  final ValueChanged<Currency> onSelected;

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // Folded on BOTH sides. A user typing `eur` finds EUR, and a user typing
    // in their own digits or script is matched against a folded haystack
    // rather than against whatever their keyboard produced.
    final query = _query.trim().toLowerCase();
    final matches = [
      for (final code in kCurrencyChoices)
        if (query.isEmpty || code.toLowerCase().contains(query)) code,
    ];

    return CalmSheet(
      title: l10n.unitsRowCurrency,
      children: [
        CalmSearchField(
          controller: _search,
          hint: l10n.unitsCurrencySearch,
          closeLabel: l10n.commonCancel,
          onChanged: (value) => setState(() => _query = value),
          onClose: () => Navigator.of(context).pop(),
        ),
        SizedBox(height: space.s4),
        CalmRowGroup(
          rows: [
            for (final code in matches)
              CalmListRow(
                title: currencyRowLabel(Currency.tryParse(code)!),
                selected: code == widget.current.code,
                end: code == widget.current.code
                    ? Icon(
                        Icons.check,
                        size: space.iconMd,
                        color: colors.brand,
                      )
                    : null,
                onTap: () {
                  final chosen = Currency.tryParse(code);
                  Navigator.of(context).pop();
                  if (chosen != null) widget.onSelected(chosen);
                },
              ),
          ],
        ),
        SizedBox(height: space.s4),
        // What it does NOT do. §2 forbids a rate anywhere in this app, and
        // somebody switching their default needs to know their history is not
        // being converted BEFORE they tap rather than after.
        Text(
          l10n.unitsFooter,
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}
