// The App Store screenshot set, shot from the same captures the parity sweep
// uses.
//
// Run it directly — it is not named `*_test.dart` because it WRITES into
// `store/screenshots/`, and a file that rewrites tracked artifacts has no
// business in the lane that runs on every push:
//
//     flutter test test/store/shoot_store.dart
//     bash tools/capture_store_screenshots.sh    # the same thing, with the tidy-up
//
// It replaces a script that drove a booted simulator with AppleScript clicks at
// coordinates measured from the window position. That script worked and cost
// two things it should not have: it could only reach a screen it could tap its
// way to on a fresh install — Costs, History and Trips are empty until the user
// logs something, and an empty state is an honest screen but a poor
// advertisement — and its first run produced three identical Home shots for the
// RTL locales because every mirrored tap landed on empty space and nothing said
// so.
//
// These captures already have the fixture the artboards were drawn around: a
// vehicle with a history behind it, four different due states, real fill-ups
// and real costs. Photographing them needs no taps, no simulator and no
// window geometry, so the failure mode above cannot happen — and
// `test/policy/store_screenshots_test.dart` still refuses a set with a
// duplicate in it, because a check that has been earned is not removed when the
// thing that earned it is fixed.
@Tags(['store'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../parity/parity_screens.dart';
import '../parity/support/parity_capture.dart';

/// Where the shots land, and what the policy test walks.
const _out = 'store/screenshots';

/// Where a capture lands before it is renamed into place.
const _staging = 'build/store';

/// The ten screens the listing tells its story with, in order.
///
/// Ten rather than Apple's minimum of three. Three screens can show that the
/// app exists; only a full set can show what it does with a car that has a
/// history behind it, which is the whole product — a first-run app with no
/// data has nothing to say and looks like every other logbook on the store.
///
/// The ids are the parity registry's, so a screen that is renamed there breaks
/// this list rather than silently dropping out of the set.
const List<(String, String)> _story = [
  ('home', 'home'),
  ('reminders.list', 'reminders'),
  ('log.fillup', 'log-fillup'),
  ('costs.fuel', 'consumption'),
  ('costs', 'costs'),
  ('history', 'history'),
  ('report.service', 'service-record'),
  ('trips.list', 'trips'),
  ('vehicles', 'vehicles'),
  ('settings', 'settings'),
];

/// A display class: the folder it ships in and the surface it is shot on.
typedef _Class = ({String dir, ParityDevice device});

/// The two families `TARGETED_DEVICE_FAMILY = "1,2"` promises.
///
/// The status bar and home indicator are the real ones for each family rather
/// than the reference's: an iPad has no notch and no home bar to speak of, and
/// giving it the phone's 54pt inset draws a band of empty surface across the
/// top of every iPad shot.
const List<_Class> _classes = [
  (
    dir: '6.9-inch',
    device: (
      physical: Size(1320, 2868),
      logical: Size(440, 956),
      dpr: 3,
      statusBar: 62,
      homeBar: 34,
    ),
  ),
  (
    dir: '13-inch',
    device: (
      physical: Size(2048, 2732),
      logical: Size(1024, 1366),
      dpr: 2,
      statusBar: 24,
      homeBar: 20,
    ),
  ),
];

/// The six shipped locales and the direction each is drawn in.
///
/// All six, not the four the App Store accepts as listing languages. The
/// listing can only carry `en`, `de`, `fr` and `ar` — Apple does not offer
/// Persian or Kurdish Sorani — but the repo is where a person checks that the
/// Sorani build looks right, and a locale with no screenshots is a locale
/// nobody looks at.
const List<(String, bool)> _locales = [
  ('en', false),
  ('de', false),
  ('fr', false),
  ('fa', true),
  ('ar', true),
  ('ckb', true),
];

void main() {
  setUpAll(loadParityFonts);

  final byId = {for (final screen in kParityScreens) screen.id: screen.capture};

  for (final (locale, rtl) in _locales) {
    for (final klass in _classes) {
      for (final (index, (id, slug)) in _story.indexed) {
        final capture = byId[id];
        // NOT a null-assertion. A renamed screen in the registry would
        // otherwise fail as a null dereference three frames inside the harness,
        // and the useful sentence — which id, out of which list — would be
        // nowhere in the output.
        if (capture == null) {
          test('$id is a screen the parity registry knows', () {
            fail('no capture registered for "$id"');
          });
          continue;
        }

        final position = '${index + 1}'.padLeft(2, '0');
        testWidgets('$locale ${klass.dir} $position-$slug', (tester) async {
          final config = (
            theme: 'light',
            dir: rtl ? 'rtl' : 'ltr',
            locale: Locale(locale),
            mode: ThemeMode.light,
            device: klass.device,
            outDir: _staging,
          );
          await capture(tester, config);

          final shot = File('$_staging/$id-light-${config.dir}.png');
          expect(
            shot.existsSync(),
            isTrue,
            reason: 'the capture wrote no file',
          );
          // `dart:io` inside `runAsync`, like every other file touch in this
          // harness: a widget test runs in a fake-async zone, and awaiting a
          // real file future there never returns.
          await tester.runAsync(() async {
            final target = Directory('$_out/$locale/${klass.dir}');
            await target.create(recursive: true);
            await shot.rename('${target.path}/$position-$slug.png');
          });
        });
      }
    }
  }
}
