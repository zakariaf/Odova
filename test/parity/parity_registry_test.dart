// One list of the screens the sweep photographs, held against three others.
//
// Every feature epic wrote its own `<screen>_parity_test.dart`, and that
// catches per-screen drift and nothing else. What it cannot catch is a screen
// nobody wrote one for: `costs.fuel`, `trips.list`, `trips.edit` and the six
// `settings.*` screens each had a reference image, a route and no capture, and
// nothing in the suite said so — a missing file is not a failing test.
//
// This is the file that makes an absence loud. It compares the registry against
// the reference set on disk, against the router's own screen table, and against
// itself; a screen can only be missing from the sweep by being deleted from all
// four at once.
@Tags(['parity'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';

import 'parity_screens.dart';

/// The screen ids the committed reference set depicts.
///
/// Read off the filenames rather than declared, because the references are the
/// authority: a list typed here would be a second opinion about what was
/// designed, and the two would drift in the direction that made the test pass.
Set<String> referencedScreens() => Directory('design/reference/calm')
    .listSync()
    .whereType<File>()
    .map((f) => f.uri.pathSegments.last)
    .where((n) => n.endsWith('.png'))
    .map((n) => n.replaceFirst(RegExp(r'-(light|dark)-(ltr|rtl)\.png$'), ''))
    .toSet();

void main() {
  test('the registry names exactly the referenced screens', () {
    final registered = kParityScreens.map((s) => s.id).toSet();
    final referenced = referencedScreens();

    expect(
      registered.difference(referenced),
      isEmpty,
      reason: 'the sweep captures a screen the reference set does not depict',
    );
    expect(
      referenced.difference(registered),
      isEmpty,
      reason: 'a referenced screen is photographed by nothing',
    );
  });

  test('every registry entry has four reference images', () {
    // A half-shot screen. Three of four combinations is the shape a regenerate
    // leaves behind when it is interrupted, and the missing one is always the
    // one nobody looks at — dark RTL.
    final missing = <String>[];
    for (final screen in kParityScreens) {
      for (final theme in const ['light', 'dark']) {
        for (final dir in const ['ltr', 'rtl']) {
          final path = 'design/reference/calm/${screen.id}-$theme-$dir.png';
          if (!File(path).existsSync()) missing.add(path);
        }
      }
    }

    expect(missing, isEmpty, reason: 'a screen is only half referenced');
  });

  test('every screen the router can reach is in the registry', () {
    // `kScreenRoutes` is itself checked against `design/calm/screens.html` by
    // `route_table_test.dart`, so this closes the loop: artboard to route to
    // capture. A screen added in EPIC-19 with no reference fails there and a
    // screen with a reference and no capture fails here.
    expect(
      kScreenRoutes.keys.toSet().difference(
        kParityScreens.map((s) => s.id).toSet(),
      ),
      isEmpty,
      reason: 'a routed screen is not photographed',
    );
  });

  test('no id is registered twice', () {
    // A duplicate would silently halve the sweep: two entries write the same
    // filename and the second wins, so one screen is captured twice and
    // another not at all — with the file count still reading 112.
    final ids = kParityScreens.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });
}
