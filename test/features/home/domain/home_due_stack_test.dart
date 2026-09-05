// Home's due stack, decided once in a pure function before any widget exists.
//
// SPEC.md §9 *Ordering* and *The unknown-anchor card*. Everything here is
// presentation over facts the due engine already computed — this file adds no
// arithmetic and the engine is untouched by it.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/home/domain/home_view_model.dart';
import 'package:test/test.dart';

const _vehicle = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _idBody = '01JQ8ZK3M7F0R6XN2E9TB4HC0';

CivilDate _day(String text) => CivilDate.tryParse(text)!;

ServiceItem _item(
  String suffix, {
  String? label,
  bool active = true,
  String? snoozedUntil,
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_$_idBody$suffix')!,
  vehicleId: VehicleId.tryParse(_vehicle)!,
  kind: ServiceKind.custom,
  label: label ?? 'Item $suffix',
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  isTracked: true,
  isActive: active,
  snoozedUntil: snoozedUntil,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// An assessed item, with the rung its anchor came from.
AssessedItem _assessed(
  String suffix, {
  required DueState state,
  String? projected,
  String? label,
  AnchorRung rung = AnchorRung.record,
  bool active = true,
  DueDriver driver = DueDriver.distance,
}) => (
  _item(suffix, label: label, active: active),
  DueAssessment(
    state: state,
    driver: driver,
    confidence: RateConfidence.measured,
    progress: 0.5,
    anchor: DueAnchor(
      date: _day('2025-01-01'),
      odometerMetres: const Distance.fromKm(100000).metres,
      dateRung: rung,
      odometerRung: rung,
    ),
    projectedDueDate: projected == null ? null : _day(projected),
  ),
);

void main() {
  test('sorts by projected due date ascending', () {
    // ONE sort key. Overdue items have past dates and float without a special
    // case; that is the point of §9's first ordering rule.
    final stack = buildHomeStack(
      items: [
        _assessed('B', state: DueState.dueSoon, projected: '2026-09-20'),
        _assessed('C', state: DueState.dueSoon, projected: '2026-10-10'),
        _assessed('A', state: DueState.overdue, projected: '2026-08-12'),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards.map((c) => c.item.label), [
      'Item A',
      'Item B',
      'Item C',
    ]);
  });

  test('caps the stack at three cards however many are due', () {
    final stack = buildHomeStack(
      items: [
        for (var i = 0; i < 9; i++)
          _assessed(
            '$i',
            state: DueState.overdue,
            projected: '2026-08-0${i + 1}',
          ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards, hasLength(3));
    expect(stack.moreDueCount, 6);
  });

  test('downgrades a purchase-anchored item to unknown', () {
    // §9: "Home renders any item anchored on the `purchase` or `first_reading`
    // rung as `unknown`, whatever the due engine returns." A 2019 car entered
    // today would otherwise open on eleven cards shouting OVERDUE.
    final stack = buildHomeStack(
      items: [
        _assessed(
          'A',
          state: DueState.overdue,
          projected: '2026-08-12',
          rung: AnchorRung.purchase,
        ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards, isEmpty);
    expect(stack.unknown, isNotNull);
    expect(stack.unknown!.labels, ['Item A']);
  });

  test('downgrades a first-reading-anchored item to unknown', () {
    final stack = buildHomeStack(
      items: [
        _assessed(
          'A',
          state: DueState.overdue,
          projected: '2026-08-12',
          rung: AnchorRung.firstReading,
        ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards, isEmpty);
    expect(stack.unknown!.labels, ['Item A']);
  });

  test('collapses unknown items into one card, always last', () {
    final stack = buildHomeStack(
      items: [
        for (var i = 0; i < 5; i++)
          _assessed(
            '$i',
            state: DueState.overdue,
            projected: '2026-08-0${i + 1}',
            rung: AnchorRung.purchase,
          ),
      ],
      today: _day('2026-09-02'),
    );

    expect(
      stack.cards,
      isEmpty,
      reason: 'none of them are in the sorted stack',
    );
    expect(stack.unknown!.labels, hasLength(3), reason: 'three named');
    expect(stack.unknown!.moreCount, 2);
  });

  test('needsOdometer never takes the primary slot while a time-driven due '
      'item exists', () {
    // §9: "an accusation the app can support beats one it cannot."
    final stack = buildHomeStack(
      items: [
        _assessed(
          'N',
          state: DueState.needsOdometer,
          projected: '2026-08-01',
          label: 'Needs a reading',
        ),
        _assessed(
          'T',
          state: DueState.due,
          projected: '2026-09-10',
          driver: DueDriver.time,
          label: 'Time driven',
        ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards.first.item.label, 'Time driven');
    expect(stack.cards[1].item.label, 'Needs a reading');
  });

  test('needsOdometer does take the primary slot when nothing else is due', () {
    final stack = buildHomeStack(
      items: [
        _assessed('N', state: DueState.needsOdometer, projected: '2026-08-01'),
        _assessed('S', state: DueState.dueSoon, projected: '2026-09-10'),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards.first.state, DueState.needsOdometer);
  });

  test('breaks ties by severity, then by label', () {
    // The labels sort AGAINST the severity here on purpose: with 'Aaa' before
    // 'Zzz' alphabetically, only the severity rule can put the `due` item
    // first. A fixture whose label order agreed with its severity order would
    // pass with the severity comparison deleted.
    final bySeverity = buildHomeStack(
      items: [
        _assessed(
          'S',
          state: DueState.dueSoon,
          projected: '2026-09-10',
          label: 'Aaa soon',
        ),
        _assessed(
          'D',
          state: DueState.due,
          projected: '2026-09-10',
          label: 'Zzz due',
        ),
      ],
      today: _day('2026-09-02'),
    );
    expect(bySeverity.cards.map((c) => c.item.label), ['Zzz due', 'Aaa soon']);

    // Then the label. German: Ölfilter before Ölwechsel.
    final byLabel = buildHomeStack(
      items: [
        _assessed(
          'W',
          state: DueState.due,
          projected: '2026-09-10',
          label: 'Ölwechsel',
        ),
        _assessed(
          'F',
          state: DueState.due,
          projected: '2026-09-10',
          label: 'Ölfilter',
        ),
      ],
      today: _day('2026-09-02'),
    );
    expect(byLabel.cards.map((c) => c.item.label), ['Ölfilter', 'Ölwechsel']);
  });

  test('excludes ok and paused from the stack but counts them as tracked', () {
    final stack = buildHomeStack(
      items: [
        // 'Q', not 'O': Crockford base32 excludes I, L, O and U, and a ULID
        // body carrying one does not parse.
        _assessed('Q', state: DueState.ok, projected: '2027-01-01'),
        _assessed(
          'P',
          state: DueState.overdue,
          projected: '2026-08-01',
          active: false,
        ),
        _assessed('D', state: DueState.due, projected: '2026-09-10'),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards, hasLength(1));
    expect(stack.cards.single.item.label, 'Item D');
    expect(stack.trackedCount, 3, reason: 'the see-all row counts all three');
  });

  test('pins a deep-linked item to the primary slot for one build', () {
    final items = [
      _assessed('A', state: DueState.overdue, projected: '2026-08-01'),
      _assessed('B', state: DueState.dueSoon, projected: '2026-10-10'),
    ];
    final pinned = buildHomeStack(
      items: items,
      today: _day('2026-09-02'),
      pinnedItemId: items[1].$1.id,
    );
    expect(pinned.cards.first.item.label, 'Item B');

    final natural = buildHomeStack(items: items, today: _day('2026-09-02'));
    expect(natural.cards.first.item.label, 'Item A');
  });

  test('a snoozed item keeps its state and gains a snoozed-until line', () {
    final stack = buildHomeStack(
      items: [
        (
          _item('A', snoozedUntil: '2026-10-12'),
          _assessed('A', state: DueState.overdue, projected: '2026-08-01').$2,
        ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards.single.state, DueState.overdue);
    expect(stack.cards.single.snoozedUntil, _day('2026-10-12'));
  });

  test('a snooze that has already run out draws no line', () {
    // §9 gives a snoozed card a fourth line reading "Snoozed until <date>".
    // `snoozed_until` is not cleared when it passes — nothing writes a row at
    // midnight — so the column still holds yesterday's date, and a card that
    // read it back unconditionally told the user it was snoozed until a day
    // that has already been and gone.
    //
    // This is what `today` is FOR. It was a required parameter of this
    // function that nothing in the body read.
    final stack = buildHomeStack(
      items: [
        (
          _item('A', snoozedUntil: '2026-09-01'),
          _assessed('A', state: DueState.overdue, projected: '2026-08-01').$2,
        ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards.single.state, DueState.overdue);
    expect(stack.cards.single.snoozedUntil, isNull);
  });

  test('a snooze ending TODAY has run out', () {
    // §3's clause is "`snoozed_until` in the future", which `isSnoozed` reads
    // as `until > today` — so the day the snooze names is the first day the
    // item is awake again, not the last day it sleeps.
    final stack = buildHomeStack(
      items: [
        (
          _item('A', snoozedUntil: '2026-09-02'),
          _assessed('A', state: DueState.overdue, projected: '2026-08-01').$2,
        ),
      ],
      today: _day('2026-09-02'),
    );

    expect(stack.cards.single.snoozedUntil, isNull);
  });
}
