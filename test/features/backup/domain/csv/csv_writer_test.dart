// SPEC.md §6 §8.1's mechanics, and the escape that is not in RFC 4180.
@TestOn('vm')
library;

import 'package:csv/csv.dart';
import 'package:odova/features/backup/domain/csv/csv_writer.dart';
import 'package:test/test.dart';

/// Parses [text] with a real parser, not this project's own writer.
///
/// The delimiter and the line ending are the package's defaults, which are
/// RFC 4180's — and that is the point: a file this app writes has to be
/// readable by a parser that was told nothing about it.
///
/// A round trip through the code that produced the file proves the two halves
/// agree with each other and nothing about whether either is right. `csv` is a
/// dev dependency for exactly this.
List<List<dynamic>> _parse(String text) =>
    const CsvToListConverter(shouldParseNumbers: false).convert(text);

void main() {
  test('a plain field is not quoted', () {
    // Quoting a field that does not need it is legal and makes the file harder
    // for a human to read — and a human reading it is most of why §6 §8.1
    // chose CSV over anything cleverer.
    expect(csvField('Golf'), 'Golf');
    expect(csvField(''), '');
  });

  test('RFC 4180: a comma, a quote, a CR or an LF forces quotes', () {
    expect(csvField('a,b'), '"a,b"');
    expect(csvField('say "hi"'), '"say ""hi"""');
    expect(csvField('one\ntwo'), '"one\ntwo"');
    expect(csvField('one\rtwo'), '"one\rtwo"');
  });

  test('the hostile cell round-trips through a real parser', () {
    // `a,b"c\nd` — a comma, a quote and an embedded newline in one field.
    const hostile = 'a,b"c\nd';

    final parsed = _parse(csvRow(['before', hostile, 'after']));

    expect(parsed.single, ['before', hostile, 'after']);
  });

  test('a formula cell survives as TEXT, unedited', () {
    // A vehicle somebody named `=cmd()` is a vehicle whose CSV runs something
    // on another machine. It is the user's own data, so the cell is PREFIXED
    // rather than altered — dropping the character would silently edit what
    // they typed.
    for (final hostile in const ['=cmd()', '+1+1', '-2+3', '@SUM(A1)']) {
      final parsed = _parse(csvRow([hostile]));

      expect(parsed.single.single, "'$hostile", reason: hostile);
      // And the original is recoverable, character for character.
      expect(
        (parsed.single.single as String).substring(1),
        hostile,
        reason: hostile,
      );
    }
  });

  test('a leading tab or CR is a formula leader too', () {
    // A spreadsheet strips leading whitespace before deciding, so `\t=cmd()`
    // is `=cmd()` by the time it matters.
    expect(csvField('\t=cmd()'), startsWith("'"));
    expect(csvField('\r=cmd()'), startsWith('"\''));
  });

  test('a minus sign inside a field is not a formula', () {
    // Only the LEADING character decides. Prefixing every cell containing a
    // hyphen would apostrophise every ISO date in the file.
    expect(csvField('Shell A-8'), 'Shell A-8');
    expect(csvField('2026-09-02'), '2026-09-02');
  });

  test('the file starts with the BOM Excel looks for', () {
    // Half this audience opens CSVs in Excel, and without it a German note
    // becomes mojibake in the one program most of them have.
    final bytes = csvHeaderBytes(['date', 'vehicle']);

    expect(bytes.take(3), kUtf8Bom);
    expect(bytes.length, greaterThan(3));
  });

  test('rows end CRLF, not LF', () {
    expect(csvRow(['a']), 'a\r\n');
  });

  test('numbers are ASCII with a DOT, whatever the locale', () {
    // A German-locale formatter would write `1.234,56` into a
    // comma-separated file.
    expect(csvNumber(1234.56, decimals: 2), '1234.56');
    expect(csvNumber(0), '0');
    expect(csvNumber(-3.5, decimals: 1), '-3.5');
  });

  test('booleans are words, not ones and zeros', () {
    expect(csvBool(value: true), 'true');
    expect(csvBool(value: false), 'false');
  });

  test('an RTL note carries no bidi controls and comes back unchanged', () {
    // The note is the one field a user can paste anything into, and the
    // isolates the app's own formatters add would break sorting in every
    // spreadsheet that opened the file.
    const note = 'روغن موتور عوض شد';

    final parsed = _parse(csvRow(['x', note]));

    expect(parsed.single.last, note);
    expect(
      parsed.single.last as String,
      isNot(matches(RegExp('[\u200e\u200f\u061c\u202a-\u202e\u2066-\u2069]'))),
    );
  });
}
