// Which card `settings.notifications` shows, and in what order its rows sit.
//
// SPEC.md §13 gives that screen five states, and they differ in more than a
// sentence: the `denied` state moves the calendar row ABOVE the delivery
// group, because an `.ics` export is the only thing on the screen that still
// works. A widget switching on a boolean cannot express that, and a widget
// switching on five booleans is five booleans nobody can hold at once.
//
// Pure, no I/O, no Flutter: it takes values.
import 'package:meta/meta.dart';
import 'package:odova/app/notifications/notification_permission_port.dart';

/// The card at the top of the screen, or none.
@immutable
sealed class NotificationsCard {
  const NotificationsCard();
}

/// §13's `neverAsked` card: "Reminders are off." with **Turn on reminders**.
///
/// The rows below stay LIVE. A user may set 07:00 and turn the fuel category
/// off before they grant anything, and greying the screen out until they say
/// yes is asking for a decision before showing what it is about.
final class NotificationsOffCard extends NotificationsCard {
  /// Creates the card.
  const NotificationsOffCard();
}

/// §13's `denied` card, whose only action is the phone's own settings.
final class NotificationsBlockedCard extends NotificationsCard {
  /// Creates the card.
  const NotificationsBlockedCard();
}

/// §14's one-time background-restriction card.
///
/// Shown after three scheduled deliveries have gone unconfirmed, which is the
/// signature of an OEM battery manager killing the app rather than of anything
/// Odova did. ONCE: a card that returns every launch is a card the user learns
/// to look past, and it names a thing they may not be able to change.
final class NotificationsBackgroundRestrictedCard extends NotificationsCard {
  /// Creates the card.
  const NotificationsBackgroundRestrictedCard();
}

/// No card at all.
///
/// The `granted` and working state. There is deliberately no reassuring green
/// banner: §13 gives this screen no confirmation of a thing that is simply
/// working, and a banner saying so is a row the user reads once and then
/// scrolls past for ever.
final class NotificationsNoCard extends NotificationsCard {
  /// Creates the card.
  const NotificationsNoCard();
}

/// What the screen draws, and in what order.
@immutable
class NotificationsChrome {
  /// Creates the chrome.
  const NotificationsChrome({
    required this.card,
    required this.calendarFirst,
    required this.showsSilentFooter,
  });

  /// The card at the top, or [NotificationsNoCard].
  final NotificationsCard card;

  /// Whether the calendar row moves above the delivery group.
  ///
  /// It does exactly when notifications are blocked: the `.ics` export is then
  /// the only thing on the screen that still delivers anything, and leaving it
  /// under four rows of controls that cannot work is hiding the one door that
  /// is open.
  ///
  /// **Resolved but not yet rendered.** SPEC.md §18 decision 13 — whether the
  /// `.ics` export ships in v1 — is open, and EPIC-16 says in writing that it
  /// is out, so the row it reorders does not exist. The rule is kept here
  /// rather than deleted because it is the answer to a question the screen
  /// will ask the moment that decision closes yes, and it is tested.
  final bool calendarFirst;

  /// Whether §13's "Odova won't send you anything" footer shows.
  final bool showsSilentFooter;
}

/// Resolves §13's five states.
///
/// [deliveriesUnconfirmed] is §14's ledger — how many scheduled deliveries the
/// app has never seen confirmed. [backgroundCardShown] is the other half of
/// its "once" rule, so a second build does not repeat it.
NotificationsChrome resolveNotificationsChrome({
  required NotificationPermission permission,
  required bool allCategoriesOff,
  int deliveriesUnconfirmed = 0,
  bool backgroundCardShown = false,
}) {
  // Permission FIRST. A phone that will not deliver anything makes every other
  // state on this screen moot, and telling a blocked user that their
  // categories are off is answering a question they did not ask.
  final blocked = permission == NotificationPermission.denied;

  final card = switch (permission) {
    NotificationPermission.denied => const NotificationsBlockedCard(),
    NotificationPermission.neverAsked => const NotificationsOffCard(),
    NotificationPermission.granted =>
      deliveriesUnconfirmed >= kUnconfirmedDeliveriesBeforeWarning &&
              !backgroundCardShown
          ? const NotificationsBackgroundRestrictedCard()
          : const NotificationsNoCard(),
  };

  return NotificationsChrome(
    card: card,
    calendarFirst: blocked,
    // Only where notifications COULD arrive and the user has turned every
    // category off. Under a blocked permission the footer would be the second
    // sentence explaining the same silence, and the first one is the one that
    // can be acted on.
    showsSilentFooter: allCategoriesOff && !blocked,
  );
}

/// How many unconfirmed deliveries §14 treats as an OEM killing the app.
///
/// Three, because one is a phone in a tunnel and two is a coincidence.
const int kUnconfirmedDeliveriesBeforeWarning = 3;
