/// A minimal TrueType/OpenType table reader, for the font gates.
///
/// The assertions EPIC-02 needs — the `wght` axis is intact, the Sorani letters
/// have glyphs, `GSUB`/`GPOS` survived — are all questions about the bytes in
/// `assets/fonts/`. Answering them in Dart means the gate runs in `flutter
/// test` on any machine, with no `fonttools` and no Python in the loop. A gate
/// that needs a tool nobody has installed is a gate that gets skipped.
library;

import 'dart:io';
import 'dart:typed_data';

/// One variation axis from the `fvar` table.
typedef VariationAxis = ({String tag, double min, double def, double max});

/// Reads the tables of an sfnt (`.ttf` / `.otf`) file.
class TtfReader {
  /// Wraps [bytes], which must be a whole font file.
  TtfReader(this.bytes) : _data = ByteData.sublistView(bytes) {
    final tableCount = _data.getUint16(4);
    for (var i = 0; i < tableCount; i++) {
      final record = 12 + i * 16;
      final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
      _tables[tag] = (
        offset: _data.getUint32(record + 8),
        length: _data.getUint32(record + 12),
      );
    }
  }

  /// The whole font file.
  final Uint8List bytes;
  final ByteData _data;
  final _tables = <String, ({int offset, int length})>{};

  /// The four-character tags of every table in the file.
  Set<String> get tableTags => _tables.keys.toSet();

  /// Whether the file begins with the WOFF2 signature, which Flutter's font
  /// loader cannot read.
  bool get isWoff2 => String.fromCharCodes(bytes.sublist(0, 4)) == 'wOF2';

  /// The variation axes declared in `fvar`, or empty if the font is static.
  ///
  /// A subsetter that *instances* a variable font freezes it to one weight and
  /// removes this table — after which `FontWeight` and the platform's bold-text
  /// accessibility flag both stop working, failing only for the user who turned
  /// bold text on, who is nobody in review.
  List<VariationAxis> get variationAxes {
    final fvar = _tables['fvar'];
    if (fvar == null) return const [];

    final axesArrayOffset = fvar.offset + _data.getUint16(fvar.offset + 4);
    final axisCount = _data.getUint16(fvar.offset + 8);
    final axisSize = _data.getUint16(fvar.offset + 10);

    return [
      for (var i = 0; i < axisCount; i++)
        () {
          final axis = axesArrayOffset + i * axisSize;
          double fixed(int at) => _data.getInt32(at) / 65536.0;
          return (
            tag: String.fromCharCodes(bytes.sublist(axis, axis + 4)),
            min: fixed(axis + 4),
            def: fixed(axis + 8),
            max: fixed(axis + 12),
          );
        }(),
    ];
  }

  /// Whether `cmap` maps [codePoint] to a glyph other than `.notdef`.
  bool hasGlyphFor(int codePoint) => _cmap.containsKey(codePoint);

  /// The number of code points the font maps.
  int get mappedCodePointCount => _cmap.length;

  late final Map<int, int> _cmap = _readCmap();

  Map<int, int> _readCmap() {
    final cmap = _tables['cmap'];
    if (cmap == null) return const {};

    // Prefer a format 12 (full Unicode) subtable, then format 4 (BMP).
    var best = -1;
    var bestFormat = -1;
    final subtableCount = _data.getUint16(cmap.offset + 2);
    for (var i = 0; i < subtableCount; i++) {
      final record = cmap.offset + 4 + i * 8;
      final platform = _data.getUint16(record);
      final encoding = _data.getUint16(record + 2);
      final isUnicode =
          platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10));
      if (!isUnicode) continue;

      final subtable = cmap.offset + _data.getUint32(record + 4);
      final format = _data.getUint16(subtable);
      if ((format == 12 || format == 4) && format > bestFormat) {
        best = subtable;
        bestFormat = format;
      }
    }
    if (best < 0) return const {};

    return bestFormat == 12 ? _readFormat12(best) : _readFormat4(best);
  }

  Map<int, int> _readFormat12(int subtable) {
    final groups = _data.getUint32(subtable + 12);
    final map = <int, int>{};
    for (var i = 0; i < groups; i++) {
      final group = subtable + 16 + i * 12;
      final start = _data.getUint32(group);
      final end = _data.getUint32(group + 4);
      final startGlyph = _data.getUint32(group + 8);
      for (var code = start; code <= end; code++) {
        map[code] = startGlyph + (code - start);
      }
    }
    return map;
  }

  Map<int, int> _readFormat4(int subtable) {
    final segCountX2 = _data.getUint16(subtable + 6);
    final segCount = segCountX2 ~/ 2;
    final endCodes = subtable + 14;
    final startCodes = endCodes + segCountX2 + 2;
    final idDeltas = startCodes + segCountX2;
    final idRangeOffsets = idDeltas + segCountX2;

    final map = <int, int>{};
    for (var segment = 0; segment < segCount; segment++) {
      final end = _data.getUint16(endCodes + segment * 2);
      final start = _data.getUint16(startCodes + segment * 2);
      if (start > end) continue;

      final delta = _data.getInt16(idDeltas + segment * 2);
      final rangeOffset = _data.getUint16(idRangeOffsets + segment * 2);

      for (var code = start; code <= end && code != 0xFFFF; code++) {
        final int glyph;
        if (rangeOffset == 0) {
          glyph = (code + delta) & 0xFFFF;
        } else {
          final at =
              idRangeOffsets + segment * 2 + rangeOffset + (code - start) * 2;
          if (at + 1 >= bytes.length) continue;
          final raw = _data.getUint16(at);
          glyph = raw == 0 ? 0 : (raw + delta) & 0xFFFF;
        }
        if (glyph != 0) map[code] = glyph;
      }
    }
    return map;
  }
}

/// The path to the bundled Arabic-script font.
const vazirmatnPath = 'assets/fonts/Vazirmatn[wght].ttf';

/// The bundled font, read and parsed once.
///
/// `_cmap` is `late final` per INSTANCE, so a fresh `TtfReader` per assertion
/// re-reads 241 KB and rebuilds the whole code-point map. SPEC.md §17's
/// per-locale gate promises to loop over every codepoint in the fa/ar/ckb ARB
/// files, which multiplies that by the size of the string set.
final TtfReader vazirmatn = TtfReader(
  Uint8List.fromList(File(vazirmatnPath).readAsBytesSync()),
);
