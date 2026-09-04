// The nine id prefixes and the ULID underneath them.
//
// SPEC.md §3 Identity: `<prefix>_<ULID>` is the id in the database, in the
// export file and in every notification payload. One scheme everywhere, never
// reused, never renumbered — and time-sortable, which is what gives history
// pagination a free deterministic tiebreak.
import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/result.dart';
import 'package:test/test.dart';

import '../../support/source_tree.dart';

/// A factory whose clock and randomness are both fixed.
UlidFactory _factory({DateTime? at, int seed = 42}) => UlidFactory(
  clock: Clock.fixed(at ?? DateTime.utc(2026, 9, 3, 12)),
  random: Random(seed),
);

void main() {
  group('the nine prefixes', () {
    test('each entity mints its own, and they are SPECs spellings', () {
      // The two that get confused: the reminder table's prefix is `rem_` and
      // the service RECORD's is `srv_`. `svc_` is nobody's.
      final f = _factory();
      expect(VehicleId.mint(f).toString(), startsWith('veh_'));
      expect(ServiceItemId.mint(f).toString(), startsWith('rem_'));
      expect(ServiceRecordId.mint(f).toString(), startsWith('srv_'));
      expect(ServiceLineId.mint(f).toString(), startsWith('lin_'));
      expect(FillUpId.mint(f).toString(), startsWith('fil_'));
      expect(ExpenseId.mint(f).toString(), startsWith('exp_'));
      expect(TripId.mint(f).toString(), startsWith('trp_'));
      expect(OdometerReadingId.mint(f).toString(), startsWith('odo_'));
      expect(OdometerCorrectionId.mint(f).toString(), startsWith('cor_'));
    });

    test('the nine are distinct and there are exactly nine', () {
      expect(RecordIdKind.values, hasLength(9));
      expect(
        RecordIdKind.values.map((k) => k.prefix).toSet(),
        hasLength(9),
      );
      expect(RecordIdKind.values.map((k) => k.prefix).toSet(), {
        'veh_',
        'rem_',
        'srv_',
        'lin_',
        'fil_',
        'exp_',
        'trp_',
        'odo_',
        'cor_',
      });
    });
  });

  group('the body', () {
    test('is 26 Crockford base-32 characters', () {
      final f = _factory();
      final body = VehicleId.mint(f).toString().substring(4);
      expect(body, hasLength(26));
      expect(
        RegExp(r'^[0-9ABCDEFGHJKMNPQRSTVWXYZ]{26}$').hasMatch(body),
        isTrue,
      );
    });

    test('never contains I, L, O or U', () {
      // Crockford drops them precisely because a human reads an id out of an
      // export file or a bug report, and 1/I/l and 0/O are the pairs that get
      // mistyped.
      final f = _factory(seed: 7);
      for (var i = 0; i < 500; i++) {
        final body = VehicleId.mint(f).toString().substring(4);
        expect(
          RegExp('[ILOU]').hasMatch(body),
          isFalse,
          reason: body,
        );
      }
    });
  });

  group('parse', () {
    test('round-trips every one of the nine', () {
      final f = _factory();
      final minted = <RecordId>[
        VehicleId.mint(f),
        ServiceItemId.mint(f),
        ServiceRecordId.mint(f),
        ServiceLineId.mint(f),
        FillUpId.mint(f),
        ExpenseId.mint(f),
        TripId.mint(f),
        OdometerReadingId.mint(f),
        OdometerCorrectionId.mint(f),
      ];

      for (final id in minted) {
        final parsed = RecordId.parse(id.toString());
        expect(parsed, isA<Ok<RecordId, IdFailure>>(), reason: '$id');
        final value = (parsed as Ok<RecordId, IdFailure>).value;
        expect(value, id);
        expect(value.toString(), id.toString());
      }
    });

    test('rejects a 25- and a 27-character body', () {
      final good = VehicleId.mint(_factory()).toString();
      final body = good.substring(4);

      expect(
        VehicleId.parse('veh_${body.substring(1)}'),
        isA<Err<VehicleId, IdFailure>>(),
      );
      expect(
        VehicleId.parse('veh_${body}A'),
        isA<Err<VehicleId, IdFailure>>(),
      );
    });

    test('rejects an id whose prefix belongs to another entity', () {
      // The mistake this type exists to make impossible: passing a fill-up id
      // where a vehicle id is expected. It is a typed failure, not a
      // VehicleId that happens to be wrong.
      final fillUp = FillUpId.mint(_factory()).toString();
      final parsed = VehicleId.parse(fillUp);

      expect(parsed, isA<Err<VehicleId, IdFailure>>());
      expect(
        (parsed as Err<VehicleId, IdFailure>).failure.code,
        'wrong_prefix',
      );
    });

    test('rejects Crockfords excluded letters in the body', () {
      final body = 'I' * 26;
      expect(VehicleId.parse('veh_$body'), isA<Err<VehicleId, IdFailure>>());
    });

    test('nothing throws for bad input', () {
      for (final bad in ['', 'veh_', 'veh', '_', 'veh_!', 'x' * 40]) {
        expect(
          () => VehicleId.parse(bad),
          returnsNormally,
          reason: bad,
        );
        expect(VehicleId.tryParse(bad), isNull, reason: bad);
      }
    });
  });

  group('ordering', () {
    test('ids minted in the same millisecond sort in mint order', () {
      // The free deterministic tiebreak. Without the monotonic increment, two
      // ids minted in one millisecond order by their RANDOM bits, and history
      // pagination then returns rows in an order that changes between runs.
      final f = _factory();
      final minted = [
        for (var i = 0; i < 1000; i++) VehicleId.mint(f).toString(),
      ];

      final sorted = [...minted]..sort();
      expect(minted, sorted);
      expect(minted.toSet(), hasLength(1000));
    });

    test('ids are time-sortable across milliseconds, as plain strings', () {
      final early = VehicleId.mint(
        _factory(at: DateTime.utc(2026, 9, 3, 12)),
      ).toString();
      final late = VehicleId.mint(
        _factory(at: DateTime.utc(2026, 9, 3, 12, 0, 1)),
      ).toString();

      expect(early.compareTo(late), isNegative);
    });
  });

  group('determinism', () {
    test('the same clock and the same seed reproduce the same id', () {
      // Rule: the randomness comes from ONE injected generator. An ambient
      // `Random()` on the minting path makes a failing test unreproducible,
      // and `seeded-determinism-and-golden-vectors` calls that out by name.
      expect(
        VehicleId.mint(_factory()).toString(),
        VehicleId.mint(_factory()).toString(),
      );
    });

    test('no ambient Random or DateTime.now on the minting path', () {
      // The grep that keeps it true. `clock.now()` and the injected `Random`
      // are the only sources, and both arrive as constructor arguments.
      for (final path in [
        'lib/core/ids/ulid.dart',
        'lib/core/ids/record_id.dart',
      ]) {
        final source = sourceWithoutLineComments(File(path));
        expect(source, isNot(contains('DateTime.now()')), reason: path);
        expect(source, isNot(RegExp(r'Random\(\)')), reason: path);
      }
    });
  });
}
