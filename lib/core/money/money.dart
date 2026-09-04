// An amount in one currency.
//
// SPEC.md §3 Canonical units (Money), §12 Ground rules. Three rules, and each
// one is a way somebody's money goes wrong:
//
//   1. Integer minor units, never a double. 0.1 + 0.2 is not 0.3, and a fuel
//      log adds hundreds of amounts.
//   2. The currency travels with the amount. A bare number is a number
//      somebody will add to a different currency.
//   3. There is NO conversion. The app has no network, so any rate it used
//      would be invented — and a made-up rate silently rewrites the resale
//      value of somebody's service history.
import 'package:meta/meta.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/value_equality.dart';

/// An amount of money.
@immutable
class Money with ValueEquality implements Comparable<Money> {
  /// Creates an amount from canonical minor units.
  const Money(this.amountMinor, this.currency);

  /// Nothing, in [currency].
  Money.zero(this.currency) : amountMinor = 0;

  /// What is stored and exported: cents, fils, rials.
  final int amountMinor;

  /// Which currency [amountMinor] is in.
  final Currency currency;

  /// Whether this is nothing.
  bool get isZero => amountMinor == 0;

  /// Whether this is money coming back — a refund, a reimbursement, a payout.
  ///
  /// Only an `Expense` can be negative (SPEC.md §3), and this is how a caller
  /// asks without reaching for the raw integer.
  bool get isNegative => amountMinor < 0;

  /// The sum.
  ///
  /// ASSERTS the currencies match rather than returning a failure. A screen
  /// that adds euros to pounds is wrong in its own logic, not handling a
  /// runtime condition — `error-handling-typed-results` rule 8: a bug is
  /// thrown, a recoverable failure is returned. Mixed totals go through
  /// `MoneyTotal`, which groups instead of summing.
  Money operator +(Money other) {
    _sameCurrency(other, '+');
    return Money(amountMinor + other.amountMinor, currency);
  }

  /// The difference.
  Money operator -(Money other) {
    _sameCurrency(other, '-');
    return Money(amountMinor - other.amountMinor, currency);
  }

  /// Scaled by a whole number.
  ///
  /// Only by an int. Multiplying money by a double is how a percentage becomes
  /// a fraction of a cent that then rounds twice; `allocate` is the way to
  /// divide money.
  Money operator *(int factor) => Money(amountMinor * factor, currency);

  void _sameCurrency(Money other, String operation) {
    if (other.currency != currency) {
      throw ArgumentError(
        'cannot $operation $currency and ${other.currency}: money never mixes '
        '(SPEC.md §12). Group with MoneyTotal instead of summing.',
      );
    }
  }

  @override
  int compareTo(Money other) {
    _sameCurrency(other, 'compare');
    return amountMinor.compareTo(other.amountMinor);
  }

  /// Whether this is more than [other].
  bool operator >(Money other) => compareTo(other) > 0;

  /// Whether this is less than [other].
  bool operator <(Money other) => compareTo(other) < 0;

  @override
  List<Object?> get props => [amountMinor, currency];

  @override
  String toString() => 'Money($amountMinor $currency)';
}
