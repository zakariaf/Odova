// Which digits the app draws, and the transform that draws them.
//
// SPEC.md §5: digit shaping is a DISPLAY transform only. Numbers are stored as
// numbers, never as digit strings, and the transform is the last step of
// formatting — after grouping and after separators — so that a comparison, a
// sort or a search never sees a shaped digit.
//
// Never mix two digit sets on one screen. One numbering system is active
// app-wide, which is why this resolves once rather than per widget.

/// The four values `Settings.numerals` can hold.
///
/// Three rows are offered against four stored values: `Automatic` stores
/// [auto]; `Latin (0-9)` stores [latin]; and `Local` resolves by language,
/// storing [extendedArabicIndic] for `fa` and `ckb` and [arabicIndic] for `ar`.
/// `Local` is offered only where the locale's default is not `latn`, because
/// nowhere else has a local digit set to name.
enum CalmNumerals {
  /// The locale's CLDR default, from SPEC.md §5's table. Resolve before use.
  auto('auto'),

  /// `0-9`.
  latin('latin'),

  /// U+0660–U+0669 `٠١٢٣٤٥٦٧٨٩` — Arabic outside the Maghreb.
  arabicIndic('arabic_indic'),

  /// U+06F0–U+06F9 `۰۱۲۳۴۵۶۷۸۹` — Persian and Sorani.
  ///
  /// A different codepoint range AND a different shape from [arabicIndic]:
  /// `۴۵۶` is not `٤٥٦`.
  extendedArabicIndic('extended_arabic_indic');

  const CalmNumerals(this.wire);

  /// The value as it is stored and exported.
  ///
  /// The old name `persian` for a numeral system is dead and must appear
  /// nowhere — `persian` is a CALENDAR value. A test greps for it.
  final String wire;
}

/// The Maghreb, where Arabic is written with Latin digits.
const _latinDigitArabicRegions = <String>{'MA', 'DZ', 'TN', 'LY'};

/// The first codepoint of each block.
const _blockStart = <CalmNumerals, int>{
  CalmNumerals.latin: 0x30,
  CalmNumerals.arabicIndic: 0x0660,
  CalmNumerals.extendedArabicIndic: 0x06F0,
};

/// SPEC.md §5's numerals table, applied to a full BCP 47 tag.
///
/// It reads the REGION, not the language: `ar-MA` gets Latin digits and
/// `ar-EG` does not. Switching on the language subtag is the documented
/// mistake, and it is the one that ships Arabic-Indic digits to Morocco.
///
/// **SPEC.md §18 question 8 — open, and this is the placeholder answer.**
/// `ckb` resolves to [CalmNumerals.extendedArabicIndic] (`۰۱۲۳`), matching
/// Persian. The alternative is [CalmNumerals.arabicIndic] (`٠١٢٣`), which is
/// CLDR's own default for `ckb` and is common in Iraqi Kurdistan print. This
/// is a native reader's call, not an engineering one — §18 says each open
/// question "can be closed with one sentence from the right person".
///
/// If it is wrong, a Sorani reader in Iraq sees Persian digit shapes where
/// they expect Arabic ones. It costs them one settings row to fix and costs us
/// one line here plus one test.
CalmNumerals resolveNumerals(CalmNumerals setting, String formatsTag) {
  if (setting != CalmNumerals.auto) return setting;

  final parts = formatsTag.split(RegExp('[-_]'));
  final language = parts.first.toLowerCase();
  final region = parts.length > 1 ? parts.last.toUpperCase() : null;

  return switch (language) {
    'fa' || 'ckb' => CalmNumerals.extendedArabicIndic,
    'ar' when _latinDigitArabicRegions.contains(region) => CalmNumerals.latin,
    'ar' => CalmNumerals.arabicIndic,
    _ => CalmNumerals.latin,
  };
}

/// Rewrites the ASCII digits of [text] into [numerals]'s block.
///
/// 1:1 by codepoint, and it touches nothing else — separators, letters and
/// spaces come through unchanged. The string length is therefore unchanged,
/// which is what lets a field echo a shaped value back without the caret
/// having to be moved.
String shapeDigits(String text, CalmNumerals numerals) {
  assert(
    numerals != CalmNumerals.auto,
    'resolve CalmNumerals.auto against the formats locale before shaping',
  );
  final start = _blockStart[numerals]!;
  if (start == 0x30) return text;

  return String.fromCharCodes([
    for (final unit in text.codeUnits)
      if (unit >= 0x30 && unit <= 0x39) start + (unit - 0x30) else unit,
  ]);
}

/// Folds every supported digit block back to ASCII.
///
/// The inverse of [shapeDigits], and the first thing any comparison, sort or
/// search does — a Persian `۴` and a Latin `4` are the same number and
/// different strings.
String foldDigitsToAscii(String text) => String.fromCharCodes([
  for (final unit in text.codeUnits)
    if (unit >= 0x0660 && unit <= 0x0669)
      0x30 + (unit - 0x0660)
    else if (unit >= 0x06F0 && unit <= 0x06F9)
      0x30 + (unit - 0x06F0)
    else
      unit,
]);
