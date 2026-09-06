// What a service record cost, and which reminders it resets.
//
// SPEC.md §10 *Cost model*: "Record cost is always Σ lines — there is no second
// cost field." That is the whole design. Most people hold one invoice with one
// number, so the default is one Total that becomes one line; splitting it by
// item is opt-in, and when it is on the Total is read-only and equals the sum.
//
// A second stored total would be a number that could disagree with its own
// lines, and the first time it did nobody would know which was true.
import 'package:meta/meta.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';

/// The id a `+ Other` line carries instead of a service item's.
///
/// §10: `+ Other` "produces a line with no item link — a job that resets
/// nothing". It needs a key inside the draft so its amount can be typed; it
/// must never reach `service_lines.service_item_id`.
const String kOtherLineId = '__other__';

/// One line on its way to storage.
typedef ServiceCostLine = ({String label, String amount, String? itemId});

/// The ticked items, the amounts, and the one total.
@immutable
class ServiceCostModel {
  /// Creates an empty model.
  const ServiceCostModel({
    this.ticks = const {},
    this.amounts = const {},
    this.total = '',
    this.isSplit = false,
    this.otherLabel,
  });

  /// Ticked items, by id, with the label to write on their line.
  ///
  /// Insertion-ordered, so the lines come out in the order the user ticked
  /// them rather than in a hash order that changes between runs.
  final Map<String, String> ticks;

  /// Per-item amounts, typed behind *Split the cost by item*.
  final Map<String, String> amounts;

  /// The single Total, when the split is off.
  final String total;

  /// Whether *Split the cost by item* is on.
  final bool isSplit;

  /// The `+ Other` line's label, or null when there is none.
  final String? otherLabel;

  /// Which reminders this record will re-anchor.
  ///
  /// The TICKED ones only. An unticked item keeps its money and loses its
  /// reset, and a `+ Other` line never had one.
  List<String> get tickedItemIds => ticks.keys.toList();

  /// Whether the Total field is the sum rather than an input.
  bool get totalIsReadOnly => isSplit;

  /// A copy with [id] ticked, labelled [label].
  ServiceCostModel ticked(String id, String label) => _copy(
    ticks: {...ticks, id: label},
  );

  /// A copy with [id] unticked.
  ///
  /// The AMOUNT stays. §10: "Unticking a chip whose amount was typed keeps the
  /// money as a plain line and states the consequence." The money was really
  /// spent; only the reminder link goes.
  ServiceCostModel unticked(String id) => _copy(ticks: {...ticks}..remove(id));

  /// A copy carrying a `+ Other` line labelled [label].
  ServiceCostModel withOther(String label) => _copy(otherLabel: label);

  /// A copy with the split on.
  ServiceCostModel split() => _copy(isSplit: true);

  /// A copy with [id]'s per-item amount replaced.
  ServiceCostModel withAmount(String id, String amount) =>
      _copy(amounts: {...amounts, id: amount});

  /// A copy with the single Total replaced.
  ServiceCostModel withTotal(String value) => _copy(total: value);

  /// The lines this record will be written with.
  ///
  /// At least one, always — `ServiceRepository.saveRecord` refuses a record
  /// with none, and a service that reset no reminder is still a service that
  /// cost money. [fallbackLabel] is the localised "Service", supplied by the
  /// caller because this file has no `BuildContext` and never will.
  List<ServiceCostLine> lines({required String fallbackLabel}) {
    if (!isSplit) {
      // One invoice, one number, one line. Labelled with the ticked item when
      // there is exactly one — splitting it across several would be inventing a
      // breakdown the user did not give.
      final label = ticks.length == 1 ? ticks.values.single : fallbackLabel;
      return [
        (
          label: label,
          amount: total,
          itemId: ticks.length == 1 ? ticks.keys.single : null,
        ),
      ];
    }

    final lines = <ServiceCostLine>[
      for (final MapEntry(key: id, value: label) in ticks.entries)
        (label: label, amount: amounts[id] ?? '', itemId: id),
      if (otherLabel case final other?)
        (label: other, amount: amounts[kOtherLineId] ?? '', itemId: null),
      // An amount typed against an item that was then unticked. §10 keeps the
      // money and drops the link; without this the line would vanish and the
      // record would be short by what it cost.
      for (final MapEntry(key: id, value: amount) in amounts.entries)
        if (!ticks.containsKey(id) && id != kOtherLineId)
          (label: fallbackLabel, amount: amount, itemId: null),
    ];
    return lines.isEmpty
        ? [(label: fallbackLabel, amount: total, itemId: null)]
        : lines;
  }

  /// The Total, which under a split is the sum of the amounts.
  String get sum {
    var minor = 0;
    var any = false;
    for (final amount in amounts.values) {
      final read = parseDecimal(amount, groupingSeparator: ',');
      if (read is! DecimalOk) continue;
      // Two decimal places by string, for the same reason money always is:
      // `1.005 * 100` is 100.49999999999999 as a double and rounds DOWN.
      final scaled = scaleByPowerOfTen(read.canonical, 2);
      if (scaled == null) continue;
      minor += scaled;
      any = true;
    }
    if (!any) return '';
    return (minor / 100).toStringAsFixed(2);
  }

  ServiceCostModel _copy({
    Map<String, String>? ticks,
    Map<String, String>? amounts,
    String? total,
    bool? isSplit,
    String? otherLabel,
  }) => ServiceCostModel(
    ticks: ticks ?? this.ticks,
    amounts: amounts ?? this.amounts,
    total: total ?? this.total,
    isSplit: isSplit ?? this.isSplit,
    otherLabel: otherLabel ?? this.otherLabel,
  );
}
