// A CSV streamed to a file, and published by rename.
//
// The same two disciplines as the backup writer, for the same two reasons.
//
// STREAMED: a `StringBuffer` holding twelve thousand rows is several megabytes
// of UTF-16 on the cheapest device this ships to, and the peak arrives while
// the user is waiting for a share sheet. Each row is encoded and pushed.
//
// PUBLISHED BY RENAME: the name the user sees is created after the last byte
// is flushed. A half-written CSV under the right name is a file somebody keeps.
import 'dart:convert';
import 'dart:io';

import 'package:odova/features/backup/domain/csv/csv_writer.dart';

/// Writes [header] and [rows] to [file].
///
/// [rows] is an `Iterable` and not a `List` on purpose: the caller can build
/// rows lazily and this will never hold more than one of them.
Future<void> writeCsvFile(
  File file,
  List<String> header,
  Iterable<List<String>> rows,
) async {
  final pending = File('${file.path}.writing');
  final sink = pending.openWrite();
  try {
    sink.add(csvHeaderBytes(header));
    for (final row in rows) {
      if (row.length != header.length) {
        // A row with the wrong number of cells puts every value after the gap
        // under the wrong header, and a CSV has no way to notice. Louder than
        // the file it would produce.
        throw StateError(
          'a CSV row has ${row.length} cells and the header has '
          '${header.length} — every value after the gap would land under the '
          'wrong column',
        );
      }
      sink.add(utf8.encode(csvRow(row)));
    }
    await sink.flush();
  } finally {
    await sink.close();
  }

  await pending.rename(file.path);
}
