// The four operations, and the shape the OS actually has.
//
// SPEC.md §4.6.1. The port is deliberately tiny — schedule, cancel, cancelAll,
// getPending — and every temptation to make it richer is logic that belongs in
// the pure scheduler, where it can be tested without a device.
//
// This is a CONTRACT suite: it runs against the fake, and the fake's job is to
// be wrong in exactly the ways the real OS is wrong. A fake that is more
// helpful than the platform is worse than no fake, because it makes code that
// cannot work pass.
//
// The `getPending` case is the one that earns its keep. iOS and Android both
// expose the pending set as IDS AND NOTHING ELSE — no fire time. Code that
// reads `when` off a pending notification compiles, passes against a generous
// fake, and then cannot be written against the platform at all. §6.1 says the
// same thing from the other side: `scheduled_notifications` is the truth for
// "why", and the OS is the truth for "whether".
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/fake_notification_gateway.dart';
import 'package:odova/core/notifications/notification_payload.dart';
import 'package:odova/core/notifications/scheduled_notification.dart';
import 'package:odova/core/result.dart';

const _vehicle = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD';
const _reminder = 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVD';

ScheduledNotification note(
  int id, {
  String title = 'Passat',
  String body = 'Oil and filter is due now.',
  String fireAtLocal = '2026-10-12T09:00',
}) => ScheduledNotification(
  id: id,
  key: 'key-$id',
  title: title,
  body: body,
  fireAtLocal: fireAtLocal,
  channel: NotificationChannelId.reminders,
  payload: encodePayload(
    const DeepLinkRequest(
      kind: DeepLinkKind.reminderDue,
      vehicleId: _vehicle,
      reminderId: _reminder,
    ),
  ),
);

void main() {
  late FakeNotificationGateway gateway;

  setUp(() => gateway = FakeNotificationGateway());

  test('schedule then getPending returns exactly that notification', () async {
    await gateway.schedule(note(1));

    expect(await gateway.getPending(), [const PendingNotification(1)]);
  });

  test('cancel removes one id and leaves the rest', () async {
    for (final id in [1, 2, 3]) {
      await gateway.schedule(note(id));
    }

    await gateway.cancel(2);

    expect(
      (await gateway.getPending()).map((p) => p.id),
      unorderedEquals(<int>[1, 3]),
    );
  });

  test('cancelling an id that is not pending is not an error', () async {
    // The OS's own behaviour, and the reason reconcile can be written as a
    // plain diff: a notification the user swiped away is gone from the pending
    // set, and cancelling it must not throw on a cold-start rebuild.
    await gateway.schedule(note(1));

    await gateway.cancel(99);

    expect((await gateway.getPending()).map((p) => p.id), [1]);
  });

  test('cancelAll empties the pending set', () async {
    for (final id in [1, 2, 3]) {
      await gateway.schedule(note(id));
    }

    await gateway.cancelAll();

    expect(await gateway.getPending(), isEmpty);
  });

  test('getPending exposes ids only, never fire times', () async {
    // Not a style preference. Neither platform gives the fire time back, so a
    // `PendingNotification` with a `when` on it is a field the live adapter
    // could only fill by inventing one.
    await gateway.schedule(note(1));

    final pending = (await gateway.getPending()).single;

    expect(pending.props, [1], reason: 'the id is the whole value');
  });

  test('scheduling one id twice replaces rather than duplicates', () async {
    // What `zonedSchedule` does on both platforms, and what makes reconcile
    // idempotent: a second run over unchanged input rewrites the same rows and
    // the user sees nothing.
    await gateway.schedule(note(1, body: 'first'));
    await gateway.schedule(note(1, body: 'second'));

    expect(await gateway.getPending(), hasLength(1));
    expect(gateway.scheduled.single.body, 'second');
  });

  test(
    'the fake records what it was asked to schedule, for assertions',
    () async {
      // The fake is not only a store: the body and the payload are what tests
      // about locale rebuilds and deep links assert on.
      await gateway.schedule(note(1, title: 'Der Passat'));

      expect(gateway.scheduled.single.title, 'Der Passat');
      expect(
        decodePayload(gateway.scheduled.single.payload).valueOrNull?.kind,
        DeepLinkKind.reminderDue,
      );
    },
  );
}
