// What "the same name" means, once, for everything that compares two.
//
// Two places ask the question and they must not answer differently:
// `dialog.confirmDelete` unlocks Delete when the typed name matches the
// vehicle's, and `vehicle.edit` notes a duplicate when a typed name matches
// another vehicle's. Two spellings of the comparison make "Golf ۲۰۱۹" one
// vehicle to the dialog and two to the note.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';

/// [text] as it is compared: digits folded, bidi stripped, trimmed, lowercased.
///
/// Every fold is load-bearing, and three of the four are about a user who
/// cannot get past a gate rather than about tidiness:
///
/// * **Digits.** A Persian-keyboard user typing `Golf ۲۰۱۹` must not be locked
///   out of deleting their own car by a numbering system they did not choose.
/// * **Bidi controls.** A name that arrived from an import carrying an
///   invisible U+200F is a name no soft keyboard can reproduce — Delete would
///   be permanently disabled and the vehicle permanently undeletable, with no
///   other route to removing it.
/// * **Case.** A phone keyboard that auto-capitalises would lock the owner of a
///   van called `van` out of the same gate, for a letter they did not type.
///   The confirmation exists to make the user stop and read the name, not to
///   test their shift key.
/// * **Whitespace.** `Van ` and `Van` are the same answer to "what do you call
///   it", and a check that only fires on an exact byte match is a check that
///   mostly does not fire.
String foldedName(String text) =>
    foldDigitsToAscii(stripBidi(text)).trim().toLowerCase();
