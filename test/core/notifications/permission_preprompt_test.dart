// The one OS dialog, spent at a moment of intent.
//
// SPEC.md §4.4.5. On both platforms the permission dialog can be raised exactly
// ONCE. A reflex "Don't allow" at launch ends the conversation permanently, and
// there is no second ask — so the pre-prompt exists to keep that one shot for a
// moment when the answer means something.
//
// Every rule here is about not spending it. The sheet appears after the user
// has proved they want to track something, at most once a month, at most three
// times ever, and never on the onboarding path. Only "Turn on reminders" raises
// the real dialog; "Not now" costs nothing and is deliberately cheap, because
// §6.4 makes the whole app work with notifications denied forever.
import 'package:odova/core/notifications/permission_preprompt.dart';
import 'package:test/test.dart';

PrePromptFacts facts({
  PrePromptTrigger trigger = PrePromptTrigger.firstServiceRecord,
  NotificationPermission permission = NotificationPermission.neverAsked,
  int timesShown = 0,
  int? daysSinceLastShown,
  bool hasVehicle = true,
  bool isOnboarding = false,
}) => PrePromptFacts(
  trigger: trigger,
  permission: permission,
  timesShown: timesShown,
  daysSinceLastShown: daysSinceLastShown,
  hasVehicle: hasVehicle,
  isOnboarding: isOnboarding,
);

void main() {
  group('the three triggers', () {
    test('all three can show it', () {
      for (final trigger in PrePromptTrigger.values) {
        expect(
          shouldShowPrePrompt(facts(trigger: trigger)),
          isTrue,
          reason: trigger.name,
        );
      }
    });

    test('the settings row shows it too, even though the user asked', () {
      // §4.4.5: "the sheet still runs, because the OS dialog is the same one
      // shot". Skipping it there would spend the shot on a tap that might have
      // been exploratory.
      expect(
        shouldShowPrePrompt(facts(trigger: PrePromptTrigger.settingsRow)),
        isTrue,
      );
    });
  });

  group('never', () {
    test('before a vehicle exists', () {
      expect(shouldShowPrePrompt(facts(hasVehicle: false)), isFalse);
    });

    test('on the onboarding path', () {
      // The one place a user is guaranteed to be interrupted already, and the
      // one where "reminders" means nothing yet.
      expect(shouldShowPrePrompt(facts(isOnboarding: true)), isFalse);
    });

    test('once permission has been granted', () {
      expect(
        shouldShowPrePrompt(
          facts(permission: NotificationPermission.granted),
        ),
        isFalse,
      );
    });

    test('after an OS-level revoke, which does not restart it', () {
      // §4.4.5: "a later OS-level revoke does not restart it." The user turned
      // it off on purpose; asking again is the app arguing with them.
      expect(
        shouldShowPrePrompt(
          facts(permission: NotificationPermission.denied, timesShown: 1),
        ),
        isFalse,
      );
    });
  });

  group('the cadence', () {
    test('at most once per 30 days', () {
      expect(
        shouldShowPrePrompt(facts(timesShown: 1, daysSinceLastShown: 29)),
        isFalse,
      );
      expect(
        shouldShowPrePrompt(facts(timesShown: 1, daysSinceLastShown: 30)),
        isTrue,
      );
    });

    test('at most three times ever, across all triggers', () {
      for (final trigger in PrePromptTrigger.values) {
        expect(
          shouldShowPrePrompt(
            facts(trigger: trigger, timesShown: 3, daysSinceLastShown: 999),
          ),
          isFalse,
          reason: '${trigger.name} must not be a fourth door',
        );
      }
    });

    test('the third is still allowed', () {
      expect(
        shouldShowPrePrompt(facts(timesShown: 2, daysSinceLastShown: 999)),
        isTrue,
      );
    });
  });

  group('what each button does', () {
    test('only Turn on reminders raises the OS dialog', () {
      expect(PrePromptAnswer.turnOn.raisesOsDialog, isTrue);
      expect(PrePromptAnswer.notNow.raisesOsDialog, isFalse);
    });

    test('the show count rises whatever the answer was', () {
      // The 30-day and three-times rules are about the SHEET having appeared,
      // not about what was said — counting only declines would let a user who
      // taps "Turn on" and then dismisses the OS dialog see it forever. The
      // function takes no answer at all now, which is the signature saying so.
      expect(nextPrePromptShowCount(1), 2);
      expect(nextPrePromptShowCount(0), 1);
    });
  });

  test('the counter is device state, not file state', () {
    // §4.4.5: "the counter and the last-shown date survive an import (they are
    // device state, not file state) and are not reset by a vehicle delete."
    // Asserted as a property of the DECISION: it reads no vehicle id and no
    // record, so there is nothing an import could carry that changes it.
    expect(
      shouldShowPrePrompt(facts(timesShown: 3, daysSinceLastShown: 9999)),
      isFalse,
      reason: 'no amount of elapsed time revives a spent third ask',
    );
  });
}
