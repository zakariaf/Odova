// SPEC.md §13's five states for `settings.notifications`, resolved in one
// place.
//
// They differ in more than a sentence: the blocked state MOVES the calendar
// row above the delivery group, because an `.ics` export is then the only
// thing on the screen that still delivers anything.
import 'package:odova/app/notifications/notification_permission_port.dart';
import 'package:odova/features/settings/domain/notifications_chrome.dart';
import 'package:test/test.dart';

NotificationsChrome _chrome({
  NotificationPermission permission = NotificationPermission.granted,
  bool allCategoriesOff = false,
  int deliveriesUnconfirmed = 0,
  bool backgroundCardShown = false,
}) => resolveNotificationsChrome(
  permission: permission,
  allCategoriesOff: allCategoriesOff,
  deliveriesUnconfirmed: deliveriesUnconfirmed,
  backgroundCardShown: backgroundCardShown,
);

void main() {
  test('never asked shows the off card, and leaves the rows live', () {
    // A user may set 07:00 and turn the fuel category off before granting
    // anything. Greying the screen out until they say yes asks for a decision
    // before showing what it is about.
    final chrome = _chrome(permission: NotificationPermission.neverAsked);

    expect(chrome.card, isA<NotificationsOffCard>());
    expect(chrome.calendarFirst, isFalse);
  });

  test('denied shows the blocked card and moves the calendar row up', () {
    // The reorder is the point. Under a blocked permission the `.ics` export
    // is the only thing on this screen that still works, and leaving it under
    // four rows of controls that cannot is hiding the one open door.
    final chrome = _chrome(permission: NotificationPermission.denied);

    expect(chrome.card, isA<NotificationsBlockedCard>());
    expect(chrome.calendarFirst, isTrue);
  });

  test('granted and working shows no card at all', () {
    // Asserted as an ABSENCE, so nobody adds a reassuring green banner: §13
    // gives this screen no confirmation of a thing that is simply working.
    expect(_chrome().card, isA<NotificationsNoCard>());
    expect(_chrome().showsSilentFooter, isFalse);
  });

  test('all categories off shows the silent footer', () {
    final chrome = _chrome(allCategoriesOff: true);

    expect(chrome.card, isA<NotificationsNoCard>());
    expect(chrome.showsSilentFooter, isTrue);
  });

  test('a blocked permission suppresses the silent footer', () {
    // Two sentences explaining the same silence, and only one of them can be
    // acted on. The card is that one.
    final chrome = _chrome(
      permission: NotificationPermission.denied,
      allCategoriesOff: true,
    );

    expect(chrome.card, isA<NotificationsBlockedCard>());
    expect(chrome.showsSilentFooter, isFalse);
  });

  test('three unconfirmed deliveries warn about the phone, once', () {
    // §14: three, because one is a phone in a tunnel and two is a
    // coincidence. And ONCE — a card that returns every launch is one the
    // user learns to look past, about a thing they may not be able to change.
    expect(
      _chrome(deliveriesUnconfirmed: 2).card,
      isA<NotificationsNoCard>(),
    );
    expect(
      _chrome(deliveriesUnconfirmed: 3).card,
      isA<NotificationsBackgroundRestrictedCard>(),
    );
    expect(
      _chrome(deliveriesUnconfirmed: 9, backgroundCardShown: true).card,
      isA<NotificationsNoCard>(),
    );
  });

  test('permission outranks the delivery ledger', () {
    // A phone that will not deliver anything makes every other state moot, and
    // telling a blocked user their phone may be restricting the app is
    // answering a question they did not ask.
    expect(
      _chrome(
        permission: NotificationPermission.denied,
        deliveriesUnconfirmed: 9,
      ).card,
      isA<NotificationsBlockedCard>(),
    );
    expect(
      _chrome(
        permission: NotificationPermission.neverAsked,
        deliveriesUnconfirmed: 9,
      ).card,
      isA<NotificationsOffCard>(),
    );
  });

  test('the permission enum keeps never-asked apart from denied', () {
    // Three values, and the third is not "denied by the OS". `neverAsked`
    // still has a door — the app can ask — and `denied`'s only remaining door
    // is the phone's own settings. Collapsed into a boolean, a user who has
    // never been asked gets told to go and change something they never turned
    // off.
    expect(NotificationPermission.values, hasLength(3));
    expect(
      _chrome(permission: NotificationPermission.neverAsked).card.runtimeType,
      isNot(
        _chrome(permission: NotificationPermission.denied).card.runtimeType,
      ),
    );
  });
}
