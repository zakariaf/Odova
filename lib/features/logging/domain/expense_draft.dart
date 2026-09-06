// Every cost that is not fuel and not a service job, as one row.
//
// SPEC.md §10 `log.expense`: "No recurrence engine, no 'repeat yearly' switch.
// One payment is one row with a coverage window, which the cost dashboard
// spreads over the months it covers; twelve generated rows would be twelve rows
// to maintain, edit and delete."
//
// Category comes first because it is the only field that changes the rest of
// the form: Insurance and Road tax turn the coverage window on, Other reveals a
// name field, and nothing is preselected — so no keyboard appears until the
// user has said what this was.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';

/// What is wrong with the draft, in the order §10's form reads.
enum ExpenseProblem {
  /// No category chosen.
  noCategory,

  /// Category is `other` and no name was given.
  noLabel,

  /// No amount. Zero is a legal amount and is not this.
  noAmount,

  /// The amount is not a number.
  amountNotANumber,

  /// The coverage window ends before it starts.
  periodBackwards,

  /// Reserved: no `log.expense` date is ever in the future by mistake.
  ///
  /// §10 allows future dates here — prepaid insurance is real — so nothing
  /// produces this. It exists so the ENUM says so: a reader looking for the
  /// future-date rule finds the answer here rather than its absence.
  futureDate,
}

/// How long a prefilled coverage window runs.
const int kExpenseCoverageMonths = 12;

/// The categories §10 opens the coverage window for.
const Set<ExpenseCategory> kPeriodCategories = {
  ExpenseCategory.insurance,
  ExpenseCategory.taxRegistration,
};

/// One expense on its way to a row.
@immutable
class ExpenseDraft {
  /// Creates a draft.
  const ExpenseDraft({
    this.category,
    this.label = '',
    this.amount = '',
    this.isRefund = false,
    this.occurredOn = '',
    this.coversPeriod = false,
    this.coversFrom,
    this.coversTo,
    this.groupingSeparator = ',',
  });

  /// What this was for. Null until the user picks — §10 preselects nothing.
  final ExpenseCategory? category;

  /// The name, required for [ExpenseCategory.other] only.
  final String label;

  /// What was paid, as typed.
  final String amount;

  /// Whether this is money coming back.
  final bool isRefund;

  /// The date paid.
  final String occurredOn;

  /// Whether the coverage window is on.
  final bool coversPeriod;

  /// The window's start, or null.
  final String? coversFrom;

  /// Its end, or null.
  final String? coversTo;

  /// The thousands separator of the locale this form is being typed in.
  ///
  /// Carried, never read from a locale: a value object that reads a locale is a
  /// value object that answers differently in Tehran and Toronto. `1.234,50` is
  /// twelve hundred and thirty-four fifty in de-DE and ambiguous against a
  /// Latin-comma grouping, and `normalizeNumericInput` takes this as a required
  /// argument for exactly that reason.
  final String groupingSeparator;

  /// Whether the user has put anything into this draft.
  ///
  /// §10's dirty rule is "any field differs from its prefill", and nothing on
  /// these forms is prefilled — §10 is explicit that the odometer never is —
  /// so any content at all is a change. The draft answers this rather than the
  /// shell reaching into its fields, because the draft is what knows which of
  /// them the user can actually reach.
  bool get isDirty =>
      category != null ||
      isRefund ||
      coversPeriod ||
      label.trim().isNotEmpty ||
      amount.trim().isNotEmpty;

  /// A copy in [next], with everything that category decides.
  ///
  /// Insurance and Road tax arrive with a 12-month window already filled in:
  /// §10 puts From at the date paid and To one day short of a year later,
  /// because that is what a policy period is and typing it twice a year is a
  /// tax on the common case.
  ExpenseDraft withCategory(ExpenseCategory next) {
    final opens = kPeriodCategories.contains(next);
    final from = CivilDate.tryParse(occurredOn);
    return _copy(
      category: next,
      coversPeriod: opens,
      coversFrom: opens ? occurredOn : null,
      coversTo: opens && from != null ? _yearFrom(from) : null,
    );
  }

  /// A copy with the name replaced.
  ExpenseDraft withLabel(String value) => _copy(label: value);

  /// A copy with the amount replaced.
  ExpenseDraft withAmount(String value) => _copy(amount: value);

  /// A copy that is a refund.
  ExpenseDraft refunded() => _copy(isRefund: true);

  /// A copy with the window's end replaced.
  ExpenseDraft withCoversTo(String value) => _copy(coversTo: value);

  /// Everything wrong with this draft, in the order the form reads.
  List<ExpenseProblem> problems() {
    final problems = <ExpenseProblem>[];
    if (category == null) problems.add(ExpenseProblem.noCategory);
    if (category == ExpenseCategory.other && label.trim().isEmpty) {
      problems.add(ExpenseProblem.noLabel);
    }

    final read = parseDecimal(amount, groupingSeparator: groupingSeparator);
    switch (read) {
      // Zero IS an amount. §10 allows it, and a warranty job or a comped wash
      // really did cost nothing — refusing it would make the user lie.
      case DecimalOk():
        break;
      case DecimalEmpty():
        problems.add(ExpenseProblem.noAmount);
      case DecimalAmbiguous():
        problems.add(ExpenseProblem.amountNotANumber);
    }

    final from = CivilDate.tryParse(coversFrom ?? '');
    final to = CivilDate.tryParse(coversTo ?? '');
    if (coversPeriod && from != null && to != null && to < from) {
      problems.add(ExpenseProblem.periodBackwards);
    }
    return problems;
  }

  /// The amount in minor units, negative when this is a refund.
  ///
  /// §10 gives the SWITCH the sign: "a minus key on a numeric pad is
  /// inconsistent across platforms and reverses badly in RTL; a switch reads
  /// the same in six languages." `Expense.amount` is the only money field in
  /// the app that may be negative, which is what makes this legal.
  int? signedMinorUnits({required int exponent}) {
    final read = parseDecimal(amount, groupingSeparator: groupingSeparator);
    if (read is! DecimalOk) return null;
    final minor = scaleByPowerOfTen(read.canonical, exponent);
    if (minor == null) return null;
    return isRefund ? -minor : minor;
  }

  /// One day short of a year after [from] — a policy period, not 365 days.
  ///
  /// `addMonths` clamps, so a 29 February policy ends 27 February rather than
  /// falling off the calendar. The hand-rolled version this replaced had two
  /// ways to return a window that ended BEFORE it began: it kept `from.year`
  /// for a 1 January start, and it fell back to `from` when the anniversary
  /// did not parse — both of which `problems()` then reported as
  /// `periodBackwards` on a window the user never touched.
  static String _yearFrom(CivilDate from) =>
      from.addMonths(12).addDays(-1).toString();

  ExpenseDraft _copy({
    ExpenseCategory? category,
    String? label,
    String? amount,
    bool? isRefund,
    String? occurredOn,
    bool? coversPeriod,
    String? coversFrom,
    String? coversTo,
  }) => ExpenseDraft(
    category: category ?? this.category,
    label: label ?? this.label,
    amount: amount ?? this.amount,
    isRefund: isRefund ?? this.isRefund,
    occurredOn: occurredOn ?? this.occurredOn,
    coversPeriod: coversPeriod ?? this.coversPeriod,
    coversFrom: coversFrom ?? this.coversFrom,
    coversTo: coversTo ?? this.coversTo,
    groupingSeparator: groupingSeparator,
  );
}
