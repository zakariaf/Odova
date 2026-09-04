// What colour the car is, as a stored value.
//
// SPEC.md §8's swatch row. `Vehicle.colour` is a nullable string in the schema
// and in the backup file, so this enum's job is to be the only thing that
// writes one: a free-form column with nine sanctioned values is a column that
// ends up with ten.
//
// **The paints are not here.** A colour is a Flutter `Color` and `lib/core` is
// pure Dart; the eight hex values live in `lib/theme/calm/` with the rest of
// the palette. This file is the vocabulary, that one is the appearance.
//
// Pure Dart, no Flutter import.

/// One of the nine swatches, in the order the row draws them.
enum VehicleColour {
  /// Plain white.
  white,

  /// Light metallic.
  silver,

  /// Mid grey.
  grey,

  /// Near-black.
  black,

  /// A muted red.
  red,

  /// A muted blue.
  blue,

  /// A muted green.
  green,

  /// A muted yellow.
  yellow,

  /// Not one of these.
  ///
  /// NOT a paint, and drawn as an outlined swatch with no fill. EPIC-09 F-9.18:
  /// the design supplied eight colours and brown was not among them, and a
  /// ninth hex chosen to sit beside eight hand-tuned ones is design work rather
  /// than engineering. Somebody with a brown car picks this and names the car;
  /// nothing in the app branches on the value.
  other;

  /// The value as stored and exported — the enum's own name.
  ///
  /// Derived rather than declared, so the two cannot drift. A hand-written
  /// table of nine strings is nine chances to typo one, and the typo would
  /// only show as a colour that stopped round-tripping through a backup.
  String get wire => name;

  /// Reads a stored value, or null.
  ///
  /// Null for anything unrecognised, including a value a future version wrote.
  /// SPEC.md §2 forbids guessing in a way that looks like fact, and mapping an
  /// unknown `brown` onto `red` would repaint somebody's car.
  static VehicleColour? tryParse(String? wire) {
    for (final colour in values) {
      if (colour.wire == wire) return colour;
    }
    return null;
  }
}
