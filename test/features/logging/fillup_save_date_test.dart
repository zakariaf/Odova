// The fill-up form can save.
//
// It could not. `FillUpDraft.occurredOn` defaults to `''`, had no public setter
// at all, and nothing ever set it — so `FillUpSave` parsed an empty string, got
// null, and returned SPEC.md §3's clock-suspicion refusal ("a row dated by a
// phone that cannot say what day it is is indistinguishable from a real one
// afterwards"). The UI renders that failure as "Couldn't save. Your phone may
// be out of space.", which is what a person saw on a device with 60 GB free.
//
// The Date row showed a real date throughout, because the row reads the
// modal's `_occurredOn` and the draft is a different object. `_ExpenseSteps`
// and `_ServiceSteps` are handed that value explicitly; `_FillUpSteps` reads
// `draft.occurredOn`, and nobody noticed the third one was missing.
//
// **§10's future-date rule was dead for the same reason.** `problems()` parses
// the same empty string, so `on > now` was unreachable and "Pick today or a day
// in the past" could never fire — including for a date arriving from an
// unvalidated `?on` query parameter.
//
// Nothing caught it because every fill-up save test drives `FillUpSave`
// directly with a draft it constructs itself, and constructs it with a date.
// The seam between the modal and the draft is the one thing none of them
// crossed.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

void main() {
  testWidgets('a fill-up entered on the form is written', (tester) async {
    tester.useDevice(Device.tallForm);
    final db = homeDatabase();
    await seedItems(db, [homeItem('Oil and filter')]);
    await SettingsRepository(db).save(homeSettings(golfId));

    await pumpShell(
      tester,
      Routes.log(LogType.fillUp),
      liveStreams: true,
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '77570');
    await tester.enterText(fields.at(1), '50');
    await tester.enterText(fields.at(2), '1.89');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save fill-up'));
    await tester.pumpAndSettle();

    // The CONFIRMATION, and specifically not the refusal. Asserting only that
    // the route popped would pass against the failure too: the modal stays put
    // and shows a red bar, which is still "no fill-up screen" to a finder
    // looking for the wrong thing.
    expect(find.text('Fill-up saved'), findsOneWidget);
    expect(find.textContaining('out of space'), findsNothing);
  });

  testWidgets('and a future date is refused', (tester) async {
    // §10: "Pick today or a day in the past." The rule was DEAD for the same
    // reason the save was: `problems()` parses `occurredOn`, and an empty
    // string parses to null, so `on > now` was never evaluated. `?on` is not
    // validated on the way in, so the route itself could carry one.
    tester.useDevice(Device.tallForm);
    final db = homeDatabase();
    await seedItems(db, [homeItem('Oil and filter')]);
    await SettingsRepository(db).save(homeSettings(golfId));

    await pumpShell(
      tester,
      Routes.log(LogType.fillUp, on: '2027-01-01'),
      liveStreams: true,
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '77570');
    await tester.enterText(fields.at(1), '50');
    await tester.enterText(fields.at(2), '1.89');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save fill-up'));
    await tester.pumpAndSettle();

    expect(find.text('Pick today or a day in the past.'), findsOneWidget);
    expect(find.text('Fill-up saved'), findsNothing);
  });

  test('the draft can be dated at all', () {
    // The unit half. `occurredOn` was a constructor parameter with a default
    // and no `with*` method beside the five that do have one — so the field was
    // unreachable from the form by construction, not by an oversight at one
    // call site.
    const draft = FillUpDraft();
    expect(draft.occurredOn, isEmpty);
    expect(draft.withDate('2026-09-08').occurredOn, '2026-09-08');
  });
}
