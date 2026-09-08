// The service form's item chips, in the order §9 puts them.
//
// SPEC.md §10 `log.service`: "item chips are the vehicle's active items,
// sorted overdue → due → due soon → ok — paused items excluded, `+ Other`
// last." The ORDER is not this file's invention: it is `compareAssessedItems`,
// the same comparator Home's three cards and `reminders.list` use, because a
// third ordering is the one a user notices.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/logging/domain/service_item_chips.dart';
import 'package:test/test.dart';

final VehicleId _vehicleId = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;

// A ULID is 26 CROCKFORD characters, so the varying one comes from that
// alphabet rather than from a counter that reaches ten and produces a 27th.
const String _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
int _n = 0;
ServiceItemId _id() => ServiceItemId.tryParse(
  'rem_01JQ8ZK3M7F0R6XN2E9TB4HCV${_crockford[_n++ % 32]}',
)!;

AssessedItem _item(
  String label, {
  required DueState state,
  String? due,
  bool isActive = true,
  ServiceKind kind = ServiceKind.custom,
}) => (
  ServiceItem(
    id: _id(),
    vehicleId: _vehicleId,
    kind: kind,
    label: label,
    priority: ServicePriority.normal,
    rollover: ServiceRollover.fromActual,
    intervalMonths: 12,
    isActive: isActive,
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  ),
  DueAssessment(
    state: state,
    driver: DueDriver.time,
    confidence: RateConfidence.measured,
    progress: 1,
    projectedDueDate: CivilDate.tryParse(due ?? ''),
  ),
);

void main() {
  test('a paused item is not offered', () {
    // §10 excludes them, and the reason is that ticking a paused item would
    // re-anchor a reminder the user has deliberately turned off.
    final chips = serviceItemChips(
      assessments: [
        _item('Oil and filter', state: DueState.ok, due: '2026-12-01'),
        _item('Air filter', state: DueState.ok, isActive: false),
      ],
      ticked: const {},
    );

    expect(chips.map((c) => c.label), ['Oil and filter']);
  });

  test('overdue comes before due, and due before ok', () {
    final chips = serviceItemChips(
      assessments: [
        _item('Ok', state: DueState.ok, due: '2027-01-01'),
        _item('Overdue', state: DueState.overdue, due: '2026-01-01'),
        _item('Due soon', state: DueState.dueSoon, due: '2026-10-01'),
      ],
      ticked: const {},
    );

    expect(chips.map((c) => c.label), ['Overdue', 'Due soon', 'Ok']);
  });

  test('an item with no projected date sorts last, not first', () {
    // It has no place on the axis the others are ordered by, and putting it
    // first would give the primary slot to the item the app knows least about.
    final chips = serviceItemChips(
      assessments: [
        _item('Unknown', state: DueState.unknown),
        _item('Ok', state: DueState.ok, due: '2027-01-01'),
      ],
      ticked: const {},
    );

    expect(chips.map((c) => c.label), ['Ok', 'Unknown']);
  });

  test('a ticked item comes back ticked', () {
    // ONE list of items, asked twice. Two lists would mint two sets of ids and
    // the tick could never match — which is the bug this assertion is for.
    final items = [
      _item('Oil and filter', state: DueState.ok, due: '2026-12-01'),
      _item('Air filter', state: DueState.ok, due: '2026-12-02'),
    ];
    final chips = serviceItemChips(assessments: items, ticked: const {});
    final ticked = serviceItemChips(
      assessments: items,
      ticked: {chips.first.id},
    );

    expect(ticked.first.ticked, isTrue);
    expect(ticked.last.ticked, isFalse);
  });

  test('a seeded item IS offered, named by its kind', () {
    // This asserted the opposite — that an item with no label is excluded —
    // and that rule excluded the entire catalogue, because SPEC.md §8 gives
    // `ServiceItem.label` meaning only for `kind = custom` and every seed
    // therefore has a null one. On a real vehicle the form offered `+ Other`
    // and nothing else, which is what a manual pass on a device found.
    //
    // The chip carries its KIND now and the presentation edge resolves the
    // name, so "a chip with no text" cannot happen without there being no name
    // for that kind at all — which `serviceKindLabel`'s exhaustive switch makes
    // a compile error.
    final chips = serviceItemChips(
      assessments: [
        _item(
          '',
          kind: ServiceKind.oilAndFilter,
          state: DueState.ok,
          due: '2026-12-01',
        ),
      ],
      ticked: const {},
    );

    expect(chips, hasLength(1));
    expect(chips.single.kind, ServiceKind.oilAndFilter);
    expect(chips.single.label, isEmpty, reason: 'the seed carries no label');
  });
}
