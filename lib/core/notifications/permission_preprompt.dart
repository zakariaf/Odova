// The one OS dialog, and the rules that stop it being wasted.
//
// SPEC.md §4.4.5. On both platforms the permission dialog can be raised exactly
// ONCE. A reflex "Don't allow" at launch ends the conversation permanently and
// there is no second ask — so the pre-prompt exists to keep that one shot for a
// moment when the answer means something.
//
// Everything here is about not spending it: after the user has proved they want
// to track something, at most once a month, at most three times ever, never on
// the onboarding path. "Not now" is deliberately cheap, and §6.4 is what makes
// it affordable — the in-app due list must be fully useful with zero
// notifications ever delivered, so a decline costs the user no functionality
// and the app has no reason to press.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// The three states an OS notification permission can be in.
///
/// `neverAsked` is NOT `denied`, and collapsing them into a boolean is how a
/// user who has never been asked gets told to go and change something they
/// never turned off. Lives in core because both the pre-prompt decision and the
/// port that reads the OS need it, and they are in different layers.
enum NotificationPermission {
  /// The app has not asked yet.
  neverAsked,

  /// Granted; reminders can be delivered.
  granted,

  /// Refused, or turned off later in the phone's settings.
  denied,
}

/// At most one pre-prompt per 30 days.
const int kPrePromptCooldownDays = 30;

/// At most three, ever, across every trigger and every vehicle.
///
/// After the third the sheet never appears again and `settings.notifications`
/// is the only remaining door — the "declined in-app three times" state that
/// screen already carries.
const int kPrePromptMaxShows = 3;

/// Why the sheet is being considered — SPEC.md §4.4.5's three moments.
enum PrePromptTrigger {
  /// The user has just proved they want to keep track of something.
  firstServiceRecord,

  /// There is now a real thing to be told about.
  firstDueSoon,

  /// The user asked, on `settings.notifications`.
  settingsRow,
}

/// What the user tapped.
enum PrePromptAnswer {
  /// Raises the real OS dialog.
  turnOn,

  /// Dismisses, and writes nothing but the counter.
  notNow;

  /// Whether this answer raises the OS permission dialog.
  ///
  /// Exactly one of them does. A test asserts the permission port receives zero
  /// calls on the "Not now" path, because raising the dialog there would spend
  /// the one shot on a user who just said no.
  bool get raisesOsDialog => this == turnOn;
}

/// Everything the decision reads.
@immutable
class PrePromptFacts with ValueEquality {
  /// Creates the facts.
  const PrePromptFacts({
    required this.trigger,
    required this.permission,
    required this.timesShown,
    required this.daysSinceLastShown,
    required this.hasVehicle,
    required this.isOnboarding,
  });

  /// Which moment this is.
  final PrePromptTrigger trigger;

  /// What the OS says now.
  final NotificationPermission permission;

  /// How many times the sheet has been shown, ever.
  final int timesShown;

  /// Since the last time, or null if never shown.
  final int? daysSinceLastShown;

  /// Whether a vehicle exists. Reminders mean nothing before one does.
  final bool hasVehicle;

  /// Whether the user is on the first-run path.
  final bool isOnboarding;

  @override
  List<Object?> get props => [
    trigger,
    permission,
    timesShown,
    daysSinceLastShown,
    hasVehicle,
    isOnboarding,
  ];
}

/// Whether to present the pre-prompt sheet.
bool shouldShowPrePrompt(PrePromptFacts facts) {
  if (!facts.hasVehicle || facts.isOnboarding) return false;

  // Granted stops it permanently. A later OS-level revoke does NOT restart it:
  // the user turned it off on purpose, and asking again is the app arguing with
  // them. `denied` after at least one show is that case; `denied` with zero
  // shows cannot happen, because only this sheet raises the dialog.
  if (facts.permission != NotificationPermission.neverAsked) return false;

  if (facts.timesShown >= kPrePromptMaxShows) return false;

  // The cooldown applies to the SHEET, not to a trigger. All three triggers
  // share one budget — §4.4.5 counts "across all triggers and all vehicles" —
  // so a user who adds a second car does not get three more asks.
  final since = facts.daysSinceLastShown;
  if (since != null && since < kPrePromptCooldownDays) return false;

  return true;
}

/// The new `timesShown` after the user answers.
///
/// Both answers count. The cadence rules are about the SHEET having been shown,
/// not about what was said — counting only declines would let somebody who taps
/// "Turn on reminders" and then dismisses the OS dialog see the sheet forever.
///
/// Takes no answer. It had one and never read it, which promised the count
/// depended on what the user tapped when it deliberately does not.
int nextPrePromptShowCount(int timesShown) => timesShown + 1;
