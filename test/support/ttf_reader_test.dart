// The reader's own tests.
//
// It parses bytes, and a bug in it makes every font assertion in the suite
// vacuously true — the worst kind of failure, because the gate reports green.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'ttf_reader.dart';

/// Builds a minimal sfnt carrying one `cmap` with a format-12 subtable.
///
/// The shipped Vazirmatn's `cmap` has two subtables and both are format 4, so
/// `_readFormat12` had never executed against anything. A synthetic font is
/// cheaper than finding a real one and it pins the arithmetic exactly.
Uint8List _fontWithFormat12(List<(int start, int end, int startGlyph)> groups) {
  final subtable = BytesBuilder();
  final sub = ByteData(16 + groups.length * 12)
    ..setUint16(0, 12) // format
    ..setUint16(2, 0) // reserved
    ..setUint32(4, 16 + groups.length * 12) // length
    ..setUint32(8, 0) // language
    ..setUint32(12, groups.length);
  for (var i = 0; i < groups.length; i++) {
    final at = 16 + i * 12;
    sub
      ..setUint32(at, groups[i].$1)
      ..setUint32(at + 4, groups[i].$2)
      ..setUint32(at + 8, groups[i].$3);
  }
  subtable.add(sub.buffer.asUint8List());

  // cmap header: version, numTables, then one encoding record.
  const cmapHeader = 4 + 8;
  final cmap = ByteData(cmapHeader)
    ..setUint16(0, 0)
    ..setUint16(2, 1)
    ..setUint16(4, 3) // platform: Windows
    ..setUint16(6, 10) // encoding: full Unicode
    ..setUint32(8, cmapHeader);

  final cmapTable = BytesBuilder()
    ..add(cmap.buffer.asUint8List())
    ..add(subtable.toBytes());
  final cmapBytes = cmapTable.toBytes();

  // sfnt header with one table record.
  const headerLength = 12 + 16;
  final header = ByteData(headerLength)
    ..setUint32(0, 0x00010000) // TrueType
    ..setUint16(4, 1) // numTables
    ..setUint16(6, 16)
    ..setUint16(8, 0)
    ..setUint16(10, 0);
  for (var i = 0; i < 4; i++) {
    header.setUint8(12 + i, 'cmap'.codeUnitAt(i));
  }
  header
    ..setUint32(12 + 4, 0) // checksum
    ..setUint32(12 + 8, headerLength) // offset
    ..setUint32(12 + 12, cmapBytes.length); // length

  return Uint8List.fromList([
    ...header.buffer.asUint8List(),
    ...cmapBytes,
  ]);
}

void main() {
  test('a format-12 cmap maps every code point in its groups', () {
    final reader = TtfReader(
      _fontWithFormat12([(0x0041, 0x0043, 10), (0x1F600, 0x1F601, 90)]),
    );

    expect(reader.tableTags, contains('cmap'));
    expect(reader.mappedCodePointCount, 5);

    for (final code in [0x41, 0x42, 0x43, 0x1F600, 0x1F601]) {
      expect(reader.hasGlyphFor(code), isTrue, reason: 'U+$code');
    }
    // Outside every group.
    expect(reader.hasGlyphFor(0x44), isFalse);
    expect(reader.hasGlyphFor(0x40), isFalse);
    // Above the BMP, which is the whole reason format 12 exists.
    expect(reader.hasGlyphFor(0x1F602), isFalse);
  });

  test('a WOFF2 file is reported, not parsed', () {
    // The REAL mockup font, not a synthetic header. `wOF2` sits where the sfnt
    // version goes and the WOFF2 header has a different shape, so reading a
    // table count from offset 4 gives part of the flavour field and the table
    // walk runs off the end of the buffer. The test that exists to say "this
    // is not a TTF" has to be able to say it rather than crash first — and a
    // hand-built 64-byte fixture is too benign to prove that, because its
    // zeros parse as "no tables".
    //
    // design/_fonts/Vazirmatn.woff2 belongs to the HTML mockup pipeline and is
    // exactly the file somebody would reach for by mistake.
    final woff2 = Uint8List.fromList(
      File('design/_fonts/Vazirmatn.woff2').readAsBytesSync(),
    );

    late TtfReader reader;
    expect(() => reader = TtfReader(woff2), returnsNormally);
    expect(reader.isWoff2, isTrue);
    expect(reader.tableTags, isEmpty);
    expect(reader.variationAxes, isEmpty);
    expect(reader.mappedCodePointCount, 0);
  });

  test('an OTTO-flavoured WOFF2 does not run the reader off the buffer', () {
    // This is the shape that actually crashes, and the shipped mockup file is
    // not it. A WOFF2 header is signature(4), flavour(4), length(4) — so
    // offset 4 holds the FLAVOUR, and reading a table count from there gives
    // 0x0001 for a TrueType-flavoured file (harmless: one garbage record) and
    // **0x4F54 = 20,308** for a CFF one. Twenty thousand 16-byte records walk
    // far past the end of any real font.
    final otto = Uint8List.fromList([
      ...'wOF2'.codeUnits,
      ...'OTTO'.codeUnits,
      ...List<int>.filled(56, 0),
    ]);

    late TtfReader reader;
    expect(() => reader = TtfReader(otto), returnsNormally);
    expect(reader.isWoff2, isTrue);
    expect(reader.tableTags, isEmpty);
  });

  test('a static font reports no variation axis', () {
    expect(TtfReader(_fontWithFormat12([(65, 65, 1)])).variationAxes, isEmpty);
  });
}
