// SPEC.md §6 §6's four naming rules.
//
// A filename is the one string in this app that leaves it. It passes through
// email, Windows, USB sticks and every cloud drive; it has to sort
// chronologically in a file list, because that list is the only index this app
// has; and an RTL filename in an LTR file manager renders in ways nobody
// enjoys. Every assertion here is one of those four sentences.
@TestOn('vm')
library;

import 'package:odova/features/backup/domain/export_filename.dart';
import 'package:test/test.dart';

void main() {
  test('the backup filename is local time, to the minute', () {
    // LOCAL, not UTC. The user recognises "the evening I sold the car"; they
    // do not recognise the same moment written in UTC.
    expect(
      backupFileName(DateTime(2026, 9, 2, 18, 41)),
      'odova-backup-2026-09-02-1841.json',
    );
  });

  test('it carries no vehicle name, even on a one-car phone', () {
    // A backup is the whole store, and naming it after one vehicle would be a
    // promise the file does not keep.
    expect(backupFileName(DateTime(2026, 9, 2, 18, 41)), isNot(contains('_')));
    expect(isSafeExportFileName(backupFileName(DateTime(2026, 9, 2))), isTrue);
  });

  test('backup filenames sort chronologically as plain strings', () {
    // Which is why the date is `YYYY-MM-DD` and the time is zero-padded: a
    // file manager sorts by name, and the user is scrolling that list looking
    // for "the one from before I did the thing".
    final names = [
      backupFileName(DateTime(2026, 9, 2, 9, 5)),
      backupFileName(DateTime(2026, 9, 2, 18, 41)),
      backupFileName(DateTime(2026, 10, 1, 8)),
      backupFileName(DateTime(2027)),
    ];

    expect(names, orderedEquals([...names]..sort()));
  });

  test('every export filename is ASCII lowercase with hyphens', () {
    final names = [
      backupFileName(DateTime(2026, 9, 2, 18, 41)),
      exportFileName(
        what: 'fillups',
        vehicleSlug: vehicleFileSlug('Golf', position: 1),
        local: DateTime(2026, 9, 2),
        extension: 'csv',
      ),
      exportFileName(
        what: 'costs',
        vehicleSlug: 'all',
        local: DateTime(2026, 9, 2),
        extension: 'csv',
      ),
      exportFileName(
        what: 'service-history',
        vehicleSlug: vehicleFileSlug('VW Käfer', position: 2),
        local: DateTime(2026, 9, 2),
        extension: 'pdf',
      ),
    ];

    for (final name in names) {
      expect(isSafeExportFileName(name), isTrue, reason: name);
      expect(name, isNot(contains(' ')));
      expect(name, name.toLowerCase());
    }
    expect(names[1], 'odova-fillups-golf-2026-09-02.csv');
    expect(names[3], 'odova-service-history-vw-kafer-2026-09-02.pdf');
  });

  test('a name written only in Arabic script falls back by list position', () {
    // Transliterating it would invent a spelling nobody asked for; leaving it
    // empty would collide with every other export. The number is the vehicle's
    // place in the garage, so the user can still match the file to the car.
    expect(vehicleFileSlug('پژو ۲۰۶', position: 2), 'vehicle-2');
    expect(vehicleFileSlug('سيارة', position: 1), 'vehicle-1');
    expect(vehicleFileSlug('   ', position: 3), 'vehicle-3');
  });

  test('a Latin name keeps its letters, minus the accents', () {
    expect(vehicleFileSlug('VW Käfer', position: 1), 'vw-kafer');
    expect(vehicleFileSlug('Citroën 2CV', position: 1), 'citroen-2cv');
    expect(vehicleFileSlug("O'Brien's van", position: 1), 'o-brien-s-van');
    expect(vehicleFileSlug('Škoda Octavia', position: 1), 'skoda-octavia');
  });

  test('a collision appends -2, then -3', () {
    // Only where Odova controls the destination. Where the OS owns it the OS
    // handles collisions, and second-guessing produces `file-2 (1).json`.
    const name = 'odova-backup-2026-09-02-1841.json';

    expect(withoutCollision(name, {}), name);
    expect(
      withoutCollision(name, {name}),
      'odova-backup-2026-09-02-1841-2.json',
    );
    expect(
      withoutCollision(name, {name, 'odova-backup-2026-09-02-1841-2.json'}),
      'odova-backup-2026-09-02-1841-3.json',
    );
  });
}
