// Volume, in millilitres.
//
// SPEC.md §3 Canonical units. Millilitres and not litres because a gallon is
// not a whole number of litres: a US gallon is exactly 3785.411784 mL and an
// imperial gallon exactly 4546.09 mL, so whole gallons are whole millilitres
// (to within a fraction) and whole litres would round every American fill-up.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// One US gallon in NANOlitres, exactly: 3785.411784 mL.
///
/// Nanolitres, because that is the coarsest unit in which the value is a whole
/// number — 3785.411784 mL is 3,785,411.784 µL, so microlitres would round it.
/// The US gallon is defined as 231 cubic inches and the inch as exactly
/// 25.4 mm, which makes this exact rather than measured.
///
/// The name matters: the first version called it `microlitresPerGallonUs` with
/// this same value, so every gallon reading came out a thousandfold wrong. A
/// unit in a constant's NAME is the only thing checking the arithmetic that
/// uses it.
const nanolitresPerGallonUs = 3785411784;

/// One imperial gallon in NANOlitres, exactly: 4546.09 mL.
///
/// Defined as exactly 4.54609 L since 1985. A DIFFERENT unit from the US
/// gallon, not a variant of it — SPEC.md §5 forbids conflating them in storage
/// or on a chart axis, because 20 mpg means two different things.
const nanolitresPerGallonUk = 4546090000;

/// A volume of liquid.
@immutable
class Volume with ValueEquality implements Comparable<Volume> {
  /// Creates a volume from canonical millilitres.
  const Volume(this.millilitres);

  /// From whole litres.
  const Volume.fromLitres(int litres) : millilitres = litres * 1000;

  /// Nothing.
  static const zero = Volume(0);

  /// The canonical value.
  final int millilitres;

  /// For display only.
  double get litres => millilitres / 1000;

  /// For display only.
  double get gallonsUs => millilitres * 1000000 / nanolitresPerGallonUs;

  /// For display only.
  double get gallonsUk => millilitres * 1000000 / nanolitresPerGallonUk;

  /// This volume in [unit], for display only.
  double inUnit(VolumeUnit unit) => switch (unit) {
    VolumeUnit.l => litres,
    VolumeUnit.galUs => gallonsUs,
    VolumeUnit.galUk => gallonsUk,
  };

  /// The sum.
  Volume operator +(Volume other) => Volume(millilitres + other.millilitres);

  /// The difference.
  Volume operator -(Volume other) => Volume(millilitres - other.millilitres);

  @override
  int compareTo(Volume other) => millilitres.compareTo(other.millilitres);

  /// Whether this is greater than [other].
  bool operator >(Volume other) => millilitres > other.millilitres;

  /// Whether this is less than [other].
  bool operator <(Volume other) => millilitres < other.millilitres;

  @override
  List<Object?> get props => [millilitres];

  @override
  String toString() => 'Volume(${millilitres}mL)';
}

/// How a volume is shown. Storage is always millilitres.
enum VolumeUnit {
  /// Litres.
  l('l'),

  /// US gallons — 3.785 L.
  galUs('gal_us'),

  /// Imperial gallons — 4.546 L. A different unit, not a variant.
  galUk('gal_uk');

  const VolumeUnit(this.wire);

  /// The value as stored and exported.
  final String wire;
}
