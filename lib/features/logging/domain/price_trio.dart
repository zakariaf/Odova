// Quantity, price per unit, total: the user has two, the app writes the third.
//
// SPEC.md §10 *The price trio*. People arrive at this form with a receipt
// carrying a total, a pump display carrying a price per litre, or both. All
// three are supported and only two are stored — price per unit is re-derived,
// because a third column is a third copy of a fact the other two already carry
// and the three would drift.
//
// The rule that makes it trustworthy is that **the rounded, displayed value is
// what gets stored**. §10: "76.66 € ÷ 1.799 shows 42.61 L and stores 42 610 mL,
// not 42 613.7 — a hidden extra decimal makes the app's own price-per-litre
// disagree with the receipt, and then nothing on screen is trusted."
import 'package:meta/meta.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';

/// One of the three.
enum TrioField {
  /// Litres, kilograms or kilowatt-hours, by fuel kind.
  quantity,

  /// Price per litre / kg / kWh. Displayed, never stored.
  pricePerUnit,

  /// What was paid.
  total,
}

/// The three fields and which of them the app is currently writing.
///
/// Immutable, and every edit returns a new one: the touched ORDER is the whole
/// algorithm, and an object that mutated it in place would make "which field
/// did the user least recently touch" a question about history nobody kept.
@immutable
class PriceTrio {
  /// An empty trio.
  const PriceTrio({
    this.quantity = '',
    this.pricePerUnit = '',
    this.total = '',
    this.touched = const [],
    this.totalDecimals = 2,
    this.groupingSeparator = ',',
  });

  /// The quantity, as displayed.
  final String quantity;

  /// The price per unit, as displayed.
  final String pricePerUnit;

  /// The total, as displayed.
  final String total;

  /// Most recently edited first. §10's `touched.moveToFront(f)`.
  final List<TrioField> touched;

  /// The currency's ISO 4217 exponent — 2 for EUR, 0 for JPY, 3 for KWD.
  final int totalDecimals;

  /// The thousands separator of the locale this form is being typed in.
  ///
  /// Carried, never read from a locale: a value object that reads a locale is a
  /// value object that answers differently in Tehran and Toronto. `1.234,50` is
  /// twelve hundred and thirty-four fifty in de-DE and ambiguous against a
  /// Latin-comma grouping, and `normalizeNumericInput` takes this as a required
  /// argument for exactly that reason.
  final String groupingSeparator;

  /// The two fields that reach storage.
  ///
  /// §10: "Only quantity and total are persisted; price per unit is re-derived
  /// for display."
  static const Set<TrioField> persisted = {TrioField.quantity, TrioField.total};

  /// Whether the user has put anything into this draft.
  ///
  /// §10's dirty rule is "any field differs from its prefill", and nothing on
  /// these forms is prefilled — §10 is explicit that the odometer never is —
  /// so any content at all is a change. The draft answers this rather than the
  /// shell reaching into its fields, because the draft is what knows which of
  /// them the user can actually reach.
  bool get isDirty =>
      touched.isNotEmpty ||
      quantity.trim().isNotEmpty ||
      pricePerUnit.trim().isNotEmpty ||
      total.trim().isNotEmpty;

  /// Which field the app is writing, or null when it is writing none.
  ///
  /// Null when fewer than two of the three carry a usable value: two is the
  /// precondition, and computing from one would be inventing the fill-up.
  TrioField? get computedField {
    final target = _target;
    if (target == null) return null;
    return _computed(target) == null ? null : target;
  }

  /// The quantity in whole millilitres, from the DISPLAYED figure.
  ///
  /// Through the displayed string and never through the raw quotient, which is
  /// the rule this whole file exists for.
  int? get quantityMillilitres {
    final read = parseDecimal(
      _value(TrioField.quantity),
      groupingSeparator: groupingSeparator,
    );
    return read is DecimalOk ? millilitresFrom(read.canonical) : null;
  }

  /// [field] now reads [text], with everything that follows from it.
  PriceTrio edited(TrioField field, String text) {
    final order = [field, ...touched.where((f) => f != field)];
    final next = PriceTrio(
      quantity: field == TrioField.quantity ? text : quantity,
      pricePerUnit: field == TrioField.pricePerUnit ? text : pricePerUnit,
      total: field == TrioField.total ? text : total,
      touched: order,
      totalDecimals: totalDecimals,
      groupingSeparator: groupingSeparator,
    );
    return next._recomputed();
  }

  /// The field the user did not just touch, per §10's `touched[0..1]`.
  ///
  /// Null until two have been touched: before that there is no "other one".
  TrioField? get _target {
    if (touched.length < 2) return null;
    final recent = touched.take(2).toSet();
    return TrioField.values.firstWhere((f) => !recent.contains(f));
  }

  /// A copy with the target field filled in, or emptied when it cannot be.
  PriceTrio _recomputed() {
    final target = _target;
    if (target == null) return this;
    final value = _computed(target) ?? '';
    return PriceTrio(
      quantity: target == TrioField.quantity ? value : quantity,
      pricePerUnit: target == TrioField.pricePerUnit ? value : pricePerUnit,
      total: target == TrioField.total ? value : total,
      touched: touched,
      totalDecimals: totalDecimals,
      groupingSeparator: groupingSeparator,
    );
  }

  /// [target]'s value from the other two, or null when they cannot give one.
  ///
  /// §10's arithmetic and its rounding, exactly: quantity at 2 dp, price at
  /// 3 dp, total at the currency exponent.
  String? _computed(TrioField target) {
    final others = TrioField.values.where((f) => f != target);
    final values = <TrioField, double>{};
    for (final field in others) {
      final read = parseDecimal(
        _value(field),
        groupingSeparator: groupingSeparator,
      );
      if (read is! DecimalOk) return null;
      values[field] = read.value;
    }

    return switch (target) {
      TrioField.quantity => _divide(
        values[TrioField.total]!,
        values[TrioField.pricePerUnit]!,
        2,
      ),
      TrioField.pricePerUnit => _divide(
        values[TrioField.total]!,
        values[TrioField.quantity]!,
        3,
      ),
      TrioField.total =>
        (values[TrioField.quantity]! * values[TrioField.pricePerUnit]!)
            .toStringAsFixed(totalDecimals),
    };
  }

  /// [a] / [b] at [places], or null rather than an infinity.
  ///
  /// A zero denominator is a half-typed form, not an error to report: the user
  /// is on their way to a real number and a field that shouted at them for
  /// passing through zero would be shouting on every entry.
  static String? _divide(double a, double b, int places) =>
      b == 0 ? null : (a / b).toStringAsFixed(places);

  String _value(TrioField field) => switch (field) {
    TrioField.quantity => quantity,
    TrioField.pricePerUnit => pricePerUnit,
    TrioField.total => total,
  };
}
