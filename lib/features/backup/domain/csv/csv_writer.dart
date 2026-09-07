// RFC 4180, plus the one escape that is not in RFC 4180.
//
// SPEC.md §6 §8.1: UTF-8 with a BOM, CRLF, comma separator, dot decimal, ASCII
// digits, ISO dates, English headers. "One deterministic format that every
// spreadsheet, Google Sheets, LibreOffice and pandas read identically beats one
// convenient in Excel-with-a-German-locale and broken everywhere else."
//
// The BOM is the odd one and it is deliberate: Excel needs it to detect UTF-8,
// and half this audience opens CSVs in Excel. Without it a German note becomes
// mojibake in the one program most of these users have.
//
// FORMULA INJECTION is the escape RFC 4180 does not describe. A cell beginning
// `=`, `+`, `-`, `@`, tab or carriage return is executed as a formula by Excel,
// Google Sheets and LibreOffice — so a vehicle a user named `=cmd()` is a
// vehicle whose CSV runs something on somebody else's machine. It is the user's
// own data and it must arrive intact, so the cell is PREFIXED rather than
// altered: a parser reads back exactly what was typed, and the spreadsheet
// reads text.
import 'dart:convert';

/// The bytes Excel looks for to decide a file is UTF-8.
const List<int> kUtf8Bom = [0xEF, 0xBB, 0xBF];

/// RFC 4180's line ending. CRLF, not LF.
const String kCsvLineEnding = '\r\n';

/// The characters that make a leading cell a formula.
///
/// Tab and carriage return are on the list because a leading whitespace
/// character is stripped by the spreadsheet before it decides, so `\t=cmd()`
/// is `=cmd()` by the time it matters.
const Set<String> kFormulaLeaders = {'=', '+', '-', '@', '\t', '\r'};

/// One CSV field, quoted and escaped.
///
/// A field is quoted when it contains a comma, a quote, a CR or an LF — and
/// embedded quotes are doubled, which is RFC 4180's only escape. Everything
/// else is written as it stands: quoting a field that does not need it is
/// legal and makes the file harder for a human to read, and a human reading it
/// is most of why this format exists.
String csvField(String value) {
  final guarded = _neutraliseFormula(value);
  final needsQuotes =
      guarded.contains(',') ||
      guarded.contains('"') ||
      guarded.contains('\n') ||
      guarded.contains('\r');
  if (!needsQuotes) return guarded;
  return '"${guarded.replaceAll('"', '""')}"';
}

/// A leading formula character, defused with an apostrophe.
///
/// `'=cmd()` rather than `=cmd()`. The apostrophe is the convention every
/// spreadsheet understands as "this is text", and a parser that is not a
/// spreadsheet reads it back as part of the string — which is why the reader
/// side of this project's tests strips it before comparing. The alternative,
/// dropping the character, would silently edit the user's data.
String _neutraliseFormula(String value) =>
    value.isNotEmpty && kFormulaLeaders.contains(value[0]) ? "'$value" : value;

/// One CSV row, terminated.
String csvRow(List<String> fields) =>
    '${fields.map(csvField).join(',')}$kCsvLineEnding';

/// The header row, with the BOM in front of it.
///
/// The BOM belongs to the FILE and not to the row, so it is emitted once, here,
/// by the only function that knows it is writing the first line.
List<int> csvHeaderBytes(List<String> header) => [
  ...kUtf8Bom,
  ...utf8.encode(csvRow(header)),
];

/// A boolean as the spreadsheet-friendly word.
///
/// `true`/`false` and not `1`/`0`: a column of ones and zeros is a column
/// somebody has to look up the meaning of, and pandas reads both.
String csvBool({required bool value}) => value ? 'true' : 'false';

/// A number as a plain ASCII decimal with a DOT.
///
/// Never `NumberFormat`: the whole point of §8.1's format is that it does not
/// depend on the reader's locale, and a German-locale formatter would write
/// `1.234,56` into a comma-separated file.
String csvNumber(num value, {int decimals = 0}) =>
    value.toStringAsFixed(decimals);
