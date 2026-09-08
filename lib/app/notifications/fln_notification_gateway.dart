// The only file in Odova that imports flutter_local_notifications.
//
// `tools/check_single_fln_import.sh` fails the build on a second one, and the
// rule is what keeps every other line of scheduling logic testable off-device:
// the pure scheduler decides WHAT and WHEN, and this file is the whole of HOW.
//
// Three decisions here are SPEC.md's rather than the plugin's defaults.
//
// **Inexact alarms, always.** SPEC.md §4.6.3: "Do not request exact-alarm
// privileges. Nothing here needs minute precision, and asking is a review risk
// and a trust cost." `inexactAllowWhileIdle` pierces Doze, needs no permission,
// and drifts by about an hour — which is why §4.2 makes every body an ABSOLUTE
// anchor ("due around 12 October") rather than a countdown ("due in 3 weeks").
// A countdown is a lie the moment delivery drifts; a date is not.
//
// This is also where this file departs from the `local-notifications-scheduler`
// skill, which says to gate exact firing behind SCHEDULE_EXACT_ALARM with an
// inexact fallback. The skill is a general default and the spec is this
// product's decision — CLAUDE.md §3 — and Odova asks for neither permission.
//
// **Wall-clock in, TZDateTime out.** The caller hands a `YYYY-MM-DDTHH:MM`
// string and this resolves it in `tz.local` at schedule time, so a user who
// flies Berlin -> Tehran gets 09:00 in Tehran. `tz.local` MUST have been set by
// `initializeNotifications()` first; the `timezone` package defaults to UTC,
// and forgetting it makes every reminder fire at the wrong hour for anyone not
// on GMT — silently, and only on their device.
//
// **Three channels, matching §4.4.4's three category switches.** They are not a
// cosmetic grouping: they are the app-level control, and there is no other one.
// Channel ids are created once by Android and never change; a renamed id is a
// new channel with the user's old preference silently discarded.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:odova/app/notifications/notification_gateway.dart';
import 'package:odova/app/notifications/notification_permission_port.dart';
import 'package:odova/core/notifications/scheduled_notification.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Loads the TZ database and points `tz.local` at this device's zone.
///
/// Called from `bootstrap()` BEFORE anything can schedule. Split from the
/// gateway's constructor because it is async, once-per-process, and has to
/// happen even when no notification is ever scheduled — `sync_notifications`
/// resolves fire times through `tz.local` whether or not the OS is reachable.
///
/// Falls back to UTC when the platform will not say. That is wrong for most
/// users and it is the honest wrong: the alternative is throwing out of cold
/// launch over a reminder, which SPEC.md §6.4 forbids in as many words —
/// notifications are an accelerant and no feature may depend on delivery.
Future<void> initializeTimeZones() async {
  tz_data.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone));
  } on Object {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

/// The live gateway.
class FlnNotificationGateway implements NotificationGateway {
  /// Wraps the plugin instance created in `bootstrap()`.
  const FlnNotificationGateway(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> schedule(ScheduledNotification notification) =>
      _plugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        _resolve(notification.fireAtLocal),
        _detailsFor(notification.channel),
        // SPEC.md §4.6.3. Never `exactAllowWhileIdle`, and never
        // `USE_EXACT_ALARM` in the manifest.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // iOS only, and required by this plugin version. `absoluteTime` is the
        // correct half of the pair: the TZDateTime above was already resolved
        // in `tz.local` at schedule time, so it IS an absolute instant and
        // asking iOS to re-interpret it as wall-clock would apply the zone
        // twice.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: notification.payload,
      );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<PendingNotification>> getPending() async {
    final pending = await _plugin.pendingNotificationRequests();
    // Ids only, deliberately. The plugin's request object also carries the
    // title, body and payload it was given — but the PLATFORM does not return
    // a fire time, and modelling what the plugin happens to remember would
    // invite code that reads a `when` the OS never gives back.
    return [for (final request in pending) PendingNotification(request.id)];
  }

  /// A wall-clock string in the CURRENT zone.
  ///
  /// A fire time already in the past resolves to the past, and the plugin will
  /// not deliver it. That is correct here and is not a silent drop: SPEC.md
  /// §4.2.2 rule 3 says a recomputed time in the past goes to the NEXT delivery
  /// slot, and that decision belongs to the pure scheduler, which has the
  /// clock and the preferences. Making it here would put it in the one file
  /// that cannot be unit-tested.
  static tz.TZDateTime _resolve(String wallClock) {
    final parsed = DateTime.parse(wallClock);
    return tz.TZDateTime(
      tz.local,
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
    );
  }

  static NotificationDetails _detailsFor(NotificationChannelId channel) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.wire,
          _channelNames[channel]!,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  // English, and only English. Android shows the channel name in system
  // settings and caches it per channel id, so it does not re-read a localised
  // string on a language change — a localised name here would be frozen at
  // whatever the user's language was on first launch, which is worse than a
  // consistent one. SPEC.md §13 owns the localised labels the app itself shows.
  static const Map<NotificationChannelId, String> _channelNames = {
    NotificationChannelId.reminders: 'Service reminders',
    NotificationChannelId.odometer: 'Odometer reminders',
    NotificationChannelId.keeping: 'Odova status',
  };
}

/// SPEC.md §4.6 has a pre-prompt, a cooldown and a `NotificationPermission`
/// enum with a `neverAsked` member — all of it domain code, all of it tested,
/// and **nothing behind it**. `NotificationPermissionPort` declared `read()`
/// and no `request()`, no implementation existed anywhere in `lib/`, and the
/// provider threw `UnimplementedError` in production.
///
/// The screen did not show that error. `notifications_screen.dart` reads
/// `ref.watch(notificationPermissionState).value ?? NotificationPermission
/// .granted`, so a provider that threw came back null and the screen assumed
/// permission had been given — a screen full of switches over an OS that had
/// never been asked. On a device: no iOS dialog, no Android 13 dialog, ever,
/// and no error either.
///
/// Found by a person tapping the toggle and noticing nothing happened.
///
/// It lives in THIS file because `notifications_import_policy_test` allows
/// `flutter_local_notifications` in exactly one of them, and that rule is
/// §4.6.1's: one import point is what keeps the scheduling maths pure and
/// testable. A second file would have been the easier change and the wrong
/// one.
///
/// Both platforms are asked through their own resolver, because the plugin has
/// no cross-platform permission call: iOS wants `alert`/`badge`/`sound` and
/// Android wants the single `POST_NOTIFICATIONS` runtime grant that arrived in
/// 13. A resolver that returns null is a platform with nothing to ask — an
/// older Android, or a test host — and that is [NotificationPermission.granted]
/// rather than an error, because on those platforms the notification really
/// will be delivered.
class FlnPermissionPort implements NotificationPermissionPort {
  /// Creates the port over [_plugin].
  const FlnPermissionPort(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<NotificationPermission> read() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      // NULL is not `false`. The plugin returns null when it cannot tell, and
      // reporting `denied` there would draw §4.6's "turn them on in Settings"
      // card over a phone where they are already on.
      return switch (enabled) {
        true => NotificationPermission.granted,
        false => NotificationPermission.denied,
        null => NotificationPermission.granted,
      };
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios == null) return NotificationPermission.granted;

    // iOS has no "read" that distinguishes never-asked from denied without
    // asking, so `checkPermissions` is the closest thing: it reports what was
    // granted, and a first launch reports nothing granted. §4.6's pre-prompt
    // is what stops that reading as a refusal — it asks before the OS does.
    final status = await ios.checkPermissions();
    return (status?.isAlertEnabled ?? false)
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> request() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return (granted ?? true)
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios == null) return NotificationPermission.granted;

    // No `critical`, and no provisional. §4.6 asks for at most two reminders a
    // week at a time the user picked; a critical alert bypasses Do Not Disturb
    // and this app has nothing that earns that.
    final granted = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return (granted ?? false)
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }
}

/// The plugin, initialised, or null when the platform would not have it.
///
/// **This never ran.** `bootstrap()` overrode neither
/// `notificationGatewayProvider` nor `notificationPermissionProvider`, and
/// neither has a working default — so every rule EPIC-16 wrote was live in the
/// tests and inert in the app. `sync_notifications.dart` says in its own header
/// that this is "the seam this repo has shipped without five times"; it shipped
/// without it a sixth.
///
/// It returns null rather than throwing on any failure. SPEC.md §6.4:
/// notifications are an accelerant and no feature may depend on delivery, so a
/// plugin that will not initialise must cost the user a reminder and not a
/// launch. The caller then wires the inert defaults and the app comes up.
Future<FlutterLocalNotificationsPlugin?> initializeNotifications() async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        // The launcher icon, which every Flutter Android project has. A named
        // asset would be one more thing to keep in step with the manifest.
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Nothing is requested HERE. §4.6 asks after its own pre-prompt, at a
        // moment the user can see the reason — an OS dialog on the first frame
        // of a first launch is the one a user dismisses without reading.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    // The RETURN VALUE IS IGNORED ON PURPOSE, and reading it cost this app
    // notifications on iOS entirely.
    //
    // `initialize` answers a different question on each platform. Android
    // returns whether the plugin set itself up. **Darwin returns whether
    // permissions were granted** — and three lines above this, all three
    // `request*Permission` flags are deliberately `false`, because §4.6 asks
    // after its own pre-prompt rather than on the first frame of a first
    // launch. So on iOS `initialize` returned `false` every time, by design,
    // and `(ready ?? false) ? plugin : null` read that as a failure.
    //
    // The consequence was the whole feature: `bootstrap()` overrode neither
    // provider, both fell back to their inert defaults, and on iOS the app
    // could not ask for permission, could not schedule a reminder, and showed
    // §13's `neverAsked` card for ever. "I'm clicking Turn on Reminders and
    // nothing happens" is exactly what that looks like.
    //
    // A THROW is still a failure and still returns null — §6.4 forbids cold
    // launch dying over a reminder. `ready` is logged nowhere and gated on
    // nowhere, because on one of the two platforms it does not mean what the
    // name says.
    return plugin;
  } on Object {
    return null;
  }
}
