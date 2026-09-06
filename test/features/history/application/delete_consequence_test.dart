// SPEC.md §11: "What a delete takes with it. `dialog.confirmDelete` names it
// explicitly."
//
// Five bodies, and the reason they are five rather than one is the point:
//
//   | A fill-up mid-chain          | "…the consumption figure for 18 Aug –
//   |                              |  1 Sep will be recalculated."
//   | A fill-up that opens a chain | "Two consumption figures will be removed."
//   | A service that reset items   | "…will go back to being due from the job
//   |                              |  before this one."
//   | A trip with attached costs   | "Its 2 expenses stay…"
//   | A standalone reading         | "Delete this reading?"
//
// A generic "Are you sure?" is a dialog the user learns to tap through, and
// then the day it says something that mattered they tap through that too.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/history/application/delete_consequence.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

late AppLocalizations l10n;

Future<void> _load(WidgetTester tester, [String tag = 'en']) async {
  l10n = await AppLocalizations.delegate.load(Locale(tag));
}

String body(DeleteSubject subject, {String Function(int)? count}) =>
    deleteConsequenceBody(
      subject: subject,
      l10n: l10n,
      formatCount: count ?? (n) => '$n',
    );

void main() {
  testWidgets('a fill-up mid-chain names the segment that is recalculated', (
    tester,
  ) async {
    await _load(tester);
    final text = body(
      const DeleteFillUp(
        recalculatedSegmentLabel: '18 Aug – 1 Sep',
      ),
    );

    expect(text, contains('18 Aug – 1 Sep'));
    expect(text, contains('recalculated'));
  });

  testWidgets('a fill-up that OPENS a chain says figures are removed instead', (
    tester,
  ) async {
    // Not "recalculated". Removing the fill that opens a chain does not
    // produce a different number, it produces no number — and a user told a
    // figure will be recalculated goes looking for the new one.
    await _load(tester);
    final text = body(const DeleteFillUp(removedFigureCount: 2));

    expect(text, contains('2'));
    expect(text, contains('removed'));
    expect(text, isNot(contains('recalculated')));
  });

  testWidgets('a service that reset reminders names them, joined', (
    tester,
  ) async {
    await _load(tester);
    final text = body(
      const DeleteService(resetItemNames: ['Oil and filter', 'Inspection']),
    );

    expect(text, contains('Oil and filter'));
    expect(text, contains('Inspection'));
  });

  testWidgets('a service that reset nothing does not invent a consequence', (
    tester,
  ) async {
    await _load(tester);
    expect(
      body(const DeleteService()),
      isNot(contains('due from')),
      reason: 'SPEC.md §2: never guess in a way that looks like fact',
    );
  });

  testWidgets('a trip promises its expenses SURVIVE, with the count', (
    tester,
  ) async {
    // §11: "Costs are never deleted as a side effect of deleting the thing
    // they were grouped under." The sentence exists to stop a user cancelling
    // a trip deletion because they think it takes the receipts with it.
    await _load(tester);
    final text = body(const DeleteTrip(attachedExpenseCount: 2));

    expect(text, contains('2'));
    expect(text, contains('stay'));
  });

  testWidgets('a trip with no attached costs says nothing about costs', (
    tester,
  ) async {
    await _load(tester);
    expect(body(const DeleteTrip()), isNot(contains('stay')));
  });

  testWidgets('a standalone reading gets the plain question', (tester) async {
    await _load(tester);
    expect(body(const DeleteReading()), isNotEmpty);
  });

  testWidgets('the ONLY reading is refused, not confirmed', (tester) async {
    // §11: "Blocked outright if it is the vehicle's only reading: 'This is the
    // only odometer reading for the Golf. Every car needs one.'" A refusal is
    // not a confirmation with a scarier body — it has no Delete button at all.
    await _load(tester);
    expect(
      deleteBlockedReason(
        subject: const DeleteReading(isOnlyReading: true, vehicleName: 'Golf'),
        l10n: l10n,
      ),
      contains('Golf'),
    );
    expect(
      deleteBlockedReason(subject: const DeleteReading(), l10n: l10n),
      isNull,
    );
  });

  testWidgets(
    'a reading that starts a correction is blocked, naming its date',
    (tester) async {
      await _load(tester);
      expect(
        deleteBlockedReason(
          subject: const DeleteReading(correctionStartsOn: '12 Mar 2023'),
          l10n: l10n,
        ),
        contains('12 Mar 2023'),
      );
    },
  );

  testWidgets('every body renders in all six locales', (tester) async {
    // Not a smoke test: a placeholder missing from one ARB throws at format
    // time, in that locale only, in a dialog the user reaches once a month.
    for (final tag in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      await _load(tester, tag);
      for (final subject in <DeleteSubject>[
        const DeleteFillUp(recalculatedSegmentLabel: '18 Aug – 1 Sep'),
        const DeleteFillUp(removedFigureCount: 2),
        const DeleteService(resetItemNames: ['Oil and filter']),
        const DeleteTrip(attachedExpenseCount: 2),
        const DeleteReading(),
      ]) {
        expect(body(subject), isNotEmpty, reason: '$tag / $subject');
      }
      expect(
        deleteBlockedReason(
          subject: const DeleteReading(isOnlyReading: true, vehicleName: 'X'),
          l10n: l10n,
        ),
        isNotNull,
        reason: tag,
      );
    }
  });
}
