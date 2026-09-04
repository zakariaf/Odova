/// Building domain value objects in a test, without a `!` at every call site.
///
/// **Flutter-free, like the rest of `test/support` that `test/core` touches** —
/// see the note at the top of `source_tree.dart`. It imports `lib/core/` only,
/// which the purity gate already keeps free of `dart:ui`.
///
/// `Currency.tryParse` returns null by design, because a three-character string
/// is not a currency and "default to two decimals" is how a yen amount ends up
/// a hundred times too small. That is right for production and unreadable in a
/// fixture, where the code is a literal the author just typed.
///
/// It re-exports the value types as well as the builders, so a fixture file
/// takes one import rather than six. A fixture that says
/// `import 'values.dart'` and then builds `Distance`, `Money` and
/// `LiquidVolume` is reading the same way the domain does.
library;

import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';

export 'package:odova/core/money/currency.dart';
export 'package:odova/core/money/money.dart';
export 'package:odova/core/units/distance.dart';
export 'package:odova/core/units/energy.dart';
export 'package:odova/core/units/fuel_quantity.dart';
export 'package:odova/core/units/mass.dart';
export 'package:odova/core/units/volume.dart';

/// [code] as a [Currency]. Throws on a literal that is not one.
///
/// Named `isoCurrency` rather than `currencyOf`, which is the production
/// mapper's name for the same idea: two identically named top-level functions
/// make every file that needs both take a prefix, and a test that reaches for
/// the wrong one still compiles.
Currency isoCurrency(String code) =>
    Currency.tryParse(code) ?? (throw ArgumentError.value(code, 'code'));

/// [amountMinor] of [code].
Money money(int amountMinor, String code) =>
    Money(amountMinor, isoCurrency(code));

/// [metres] as a [Distance], or null for a null.
///
/// The nullable form is what fixtures need: most of these columns are optional
/// and a test that writes `metres == null ? null : Distance(metres)` inline
/// stops being about the thing it is testing.
Distance? metres(int? metres) => metres == null ? null : Distance(metres);
