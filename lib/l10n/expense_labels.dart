// The names of the ten expense categories.
//
// SPEC.md §10 draws them as chips: Insurance · Road tax · Parking · Toll ·
// Fine · Wash · Tyre storage · Accessory · Finance · Other. Before this file
// the form rendered `ExpenseCategory.wire` — `tax_registration`, in English,
// on every phone — which is a storage detail leaking onto a screen.
//
// A switch and not a map, so adding a category to the enum stops compiling
// here rather than silently drawing a blank chip.
//
// §10 also calls these "the longest strings in the app" (`Reifeneinlagerung`,
// `Zulassung und Steuer`) and requires that they wrap to three rows in German
// rather than truncate. That is the chip bar's job; it starts here with them
// being real strings in all six locales.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// [category]'s name in the user's language.
String expenseCategoryLabel(AppLocalizations l10n, ExpenseCategory category) =>
    switch (category) {
      ExpenseCategory.insurance => l10n.expenseCategoryInsurance,
      ExpenseCategory.taxRegistration => l10n.expenseCategoryTaxRegistration,
      ExpenseCategory.parking => l10n.expenseCategoryParking,
      ExpenseCategory.toll => l10n.expenseCategoryToll,
      ExpenseCategory.fine => l10n.expenseCategoryFine,
      ExpenseCategory.wash => l10n.expenseCategoryWash,
      ExpenseCategory.tyreStorage => l10n.expenseCategoryTyreStorage,
      ExpenseCategory.accessories => l10n.expenseCategoryAccessories,
      ExpenseCategory.finance => l10n.expenseCategoryFinance,
      ExpenseCategory.other => l10n.expenseCategoryOther,
    };
