// The three fields the OS carries for us, and what happens when they are wrong.
//
// SPEC.md §4.4.2. A notification body is baked into the OS at schedule time and
// so is its payload — a string that may sit in the notification centre for four
// months and be tapped after an app update that changed the schema. Every
// assumption this codec makes about it will eventually be tested by a real
// user's phone, so none of them is allowed to be implicit.
//
// The rule the failures exist for is SPEC.md §2's: never guess in a way that
// looks like fact. A payload naming a kind this build does not have is REFUSED,
// not defaulted to `reminder.due` — defaulting would open Home with a card
// pinned that has nothing to do with what the user tapped, and there is no
// version of that which is honest.
//
// Note the shape under test is `DeepLinkRequest`, not a new
// `NotificationPayload`
// sealed hierarchy. EPIC-08 built this type with exactly §4.4.2's three fields,
// and the six kinds differ only in whether `reminderId` is present —
// which `DeepLinkKind.carriesReminder` already says. Six subclasses holding
// identical fields would be a second name for one thing.
import 'package:odova/core/notifications/notification_payload.dart';
import 'package:odova/core/result.dart';
import 'package:test/test.dart';

const _vehicle = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD';
const _reminder = 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVD';

DeepLinkRequest? ok(Result<DeepLinkRequest, PayloadFailure> r) => r.valueOrNull;
PayloadFailure? err(Result<DeepLinkRequest, PayloadFailure> r) => switch (r) {
  Ok() => null,
  Err(:final failure) => failure,
};

void main() {
  group('the round trip', () {
    test('all six kinds survive encode then decode', () {
      for (final kind in DeepLinkKind.values) {
        final payload = DeepLinkRequest(
          kind: kind,
          vehicleId: _vehicle,
          reminderId: kind.carriesReminder ? _reminder : null,
        );

        expect(
          ok(decodePayload(encodePayload(payload))),
          payload,
          reason: '${kind.wire} did not survive the trip',
        );
      }
    });

    test('the encoded form is the three keys SPEC.md §4.4.2 names', () {
      // Pinned as a STRING, because this is a wire format that outlives the
      // build that wrote it. A renamed key is a payload every pending
      // notification on the phone still carries and no future build can read.
      expect(
        encodePayload(
          const DeepLinkRequest(
            kind: DeepLinkKind.reminderDue,
            vehicleId: _vehicle,
            reminderId: _reminder,
          ),
        ),
        '{"kind":"reminder.due","vehicleId":"$_vehicle",'
        '"reminderId":"$_reminder"}',
      );
    });

    test(
      'a kind that names no reminder omits the key rather than nulling it',
      () {
        expect(
          encodePayload(
            const DeepLinkRequest(
              kind: DeepLinkKind.keeper,
              vehicleId: _vehicle,
            ),
          ),
          '{"kind":"keeper","vehicleId":"$_vehicle"}',
        );
      },
    );
  });

  group('what it refuses', () {
    test('reminder.due and reminder.overdue without a reminderId', () {
      for (final kind in [
        DeepLinkKind.reminderDue,
        DeepLinkKind.reminderOverdue,
      ]) {
        final failure = err(
          decodePayload('{"kind":"${kind.wire}","vehicleId":"$_vehicle"}'),
        );
        expect(failure, isA<MissingPayloadField>(), reason: kind.wire);
        expect((failure! as MissingPayloadField).field, 'reminderId');
      }
    });

    test('the other four kinds CARRYING a reminderId', () {
      // Not ignored, refused. A grouped notification names several items and
      // pins none; one arriving with a single reminder on it was built by
      // something that does not agree with this build about what grouped
      // means, and honouring it would pin one arbitrary card out of five.
      for (final kind in DeepLinkKind.values.where((k) => !k.carriesReminder)) {
        expect(
          err(
            decodePayload(
              '{"kind":"${kind.wire}","vehicleId":"$_vehicle",'
              '"reminderId":"$_reminder"}',
            ),
          ),
          isA<UnexpectedPayloadField>(),
          reason: kind.wire,
        );
      }
    });

    test('a missing vehicleId, on every kind', () {
      for (final kind in DeepLinkKind.values) {
        expect(
          err(decodePayload('{"kind":"${kind.wire}"}')),
          isA<MissingPayloadField>(),
          reason: kind.wire,
        );
      }
    });

    test('an EMPTY id, which is not the same as a missing one', () {
      // A mutation check found this untested: the guard read `is! String` and
      // an empty string passed it. `""` is what a serialiser writes for a null
      // id, and it would route as a vehicle that cannot exist — which lands on
      // plain Home, so the damage is small and the silence is not: the payload
      // is malformed and the log should say so rather than reporting a vehicle
      // that was merely deleted.
      expect(
        err(decodePayload('{"kind":"keeper","vehicleId":""}')),
        isA<MissingPayloadField>(),
      );
      expect(
        err(
          decodePayload(
            '{"kind":"reminder.due","vehicleId":"$_vehicle","reminderId":""}',
          ),
        ),
        isA<MissingPayloadField>(),
      );
    });

    test('an unknown kind, rather than defaulting to reminder.due', () {
      // The app-update case: a payload written by a build that had a kind this
      // one does not. It is four months old and the user just tapped it.
      final failure = err(
        decodePayload('{"kind":"reminder.snoozed","vehicleId":"$_vehicle"}'),
      );
      expect(failure, isA<UnknownPayloadKind>());
      expect((failure! as UnknownPayloadKind).wire, 'reminder.snoozed');
    });

    test('a string that is not JSON at all', () {
      expect(err(decodePayload('not json')), isA<UnreadablePayload>());
    });

    test('JSON that is not an object', () {
      // `[]` and `"x"` are both valid JSON and neither is a payload.
      for (final wire in ['[]', '"reminder.due"', '7', 'null']) {
        expect(
          err(decodePayload(wire)),
          isA<UnreadablePayload>(),
          reason: wire,
        );
      }
    });

    test(
      'an empty payload, which is what a cold tap with no data looks like',
      () {
        expect(err(decodePayload('')), isA<UnreadablePayload>());
      },
    );

    test('a field of the wrong type', () {
      expect(
        err(decodePayload('{"kind":7,"vehicleId":"$_vehicle"}')),
        isA<UnreadablePayload>(),
      );
      expect(
        err(decodePayload('{"kind":"keeper","vehicleId":[]}')),
        isA<MissingPayloadField>(),
      );
    });
  });

  test('every failure says which field, so a log line is actionable', () {
    // No user ever sees these — a bad payload routes to plain Home in silence,
    // per §7. They exist for the person reading a bug report.
    expect(
      err(decodePayload('{"kind":"keeper"}'))!.code,
      'payload_missing_field',
    );
  });
}
