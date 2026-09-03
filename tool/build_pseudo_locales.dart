// Derives the two pseudo-locales from the template.
//
// SPEC.md §5 testing items 2 and 3. They are GENERATED, never hand-edited:
// a hand-maintained pseudo-locale drifts from the template, and a pseudo-locale
// that is missing a key is a pseudo-locale that cannot report a hard-coded
// string — which is the one thing it exists to do.
//
// They are written to test/fixtures/, NOT to lib/l10n/arb/. Anything in
// `arb-dir` is compiled by gen-l10n into the shipping binary and joins
// `AppLocalizations.supportedLocales` — so a user picking a language could land
// in one. CLAUDE.md's naming rule for synthetic fixtures applies:
// `*.fixture.json`.
//
// `dart run tool/build_pseudo_locales.dart`
import 'dart:convert';
import 'dart:io';

/// Latin letters mapped to accented look-alikes.
///
/// Every one is still readable, on purpose: the point is to see at a glance
/// that a string CAME FROM the translation layer, not to make it unreadable.
const _accents = <String, String>{
  'a': 'á',
  'b': 'ḅ',
  'c': 'ç',
  'd': 'ḍ',
  'e': 'ḗ',
  'f': 'ƒ',
  'g': 'ḡ',
  'h': 'ħ',
  'i': 'ī',
  'j': 'ĵ',
  'k': 'ķ',
  'l': 'ŀ',
  'm': 'ḿ',
  'n': 'ǹ',
  'o': 'ǿ',
  'p': 'ƥ',
  'q': ' q',
  'r': 'ř',
  's': 'ŝ',
  't': 'ţ',
  'u': 'ǔ',
  'v': 'ṽ',
  'w': 'ẇ',
  'x': 'ẋ',
  'y': 'ẏ',
  'z': 'ż',
  'A': 'Á',
  'B': 'Ḅ',
  'C': 'Ç',
  'D': 'Ḍ',
  'E': 'Ḗ',
  'F': 'Ƒ',
  'G': 'Ḡ',
  'H': 'Ħ',
  'I': 'Ī',
  'J': 'Ĵ',
  'K': 'Ķ',
  'L': 'Ŀ',
  'M': 'Ḿ',
  'N': 'Ǹ',
  'O': 'Ǿ',
  'P': 'Ƥ',
  'Q': 'Q',
  'R': 'Ř',
  'S': 'Ŝ',
  'T': 'Ţ',
  'U': 'Ǔ',
  'V': 'Ṽ',
  'W': 'Ẇ',
  'X': 'Ẋ',
  'Y': 'Ẏ',
  'Z': 'Ż',
};

/// The pad that makes a string ~40% longer.
///
/// German runs about 30% longer than English and French about 20%, so 40% is
/// the headroom a layout needs to survive the worst of the six.
const _pad = 'ǃ';

/// Applies [literal] to the human-readable parts of an ICU message and leaves
/// the syntax alone.
///
/// Written because the naive version — transform everything outside `{}` —
/// mangles a plural: the category names `one`, `other` and `=0` sit OUTSIDE
/// braces and are syntax, so accenting them produces `ǿǹḗ{...}`, which ICU
/// cannot parse, and reversing them produces `eno {...}`, which it cannot
/// either. A pseudo-locale that does not load is a pseudo-locale that reports
/// nothing.
String transformIcu(String message, String Function(String) literal) {
  final out = StringBuffer();
  var i = 0;

  while (i < message.length) {
    final open = message.indexOf('{', i);
    if (open < 0) {
      out.write(literal(message.substring(i)));
      break;
    }
    out.write(literal(message.substring(i, open)));

    final close = _matchingBrace(message, open);
    final inner = message.substring(open + 1, close);
    final complex = RegExp(
      r'^\s*([A-Za-z][A-Za-z0-9]*)\s*,\s*(plural|select)\s*,(.*)$',
      dotAll: true,
    ).firstMatch(inner);

    if (complex == null) {
      // A simple placeholder: `{value}`. Untouched, name and all.
      out.write(message.substring(open, close + 1));
    } else {
      out.write('{${complex.group(1)}, ${complex.group(2)},');
      final body = complex.group(3)!;
      var j = 0;
      while (j < body.length) {
        final branch = body.indexOf('{', j);
        if (branch < 0) {
          out.write(body.substring(j));
          break;
        }
        // The category name and the whitespace before it are syntax.
        out.write(body.substring(j, branch));
        final branchClose = _matchingBrace(body, branch);
        out.write(
          '{${transformIcu(body.substring(branch + 1, branchClose), literal)}}',
        );
        j = branchClose + 1;
      }
      out.write('}');
    }
    i = close + 1;
  }
  return out.toString();
}

int _matchingBrace(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == '{') depth++;
    if (s[i] == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  throw FormatException('unbalanced brace in "$s"');
}

/// `en-XA`: accented, bracketed and 40% longer.
///
/// Catches a hard-coded string — anything that comes back unaccented never
/// went through the translation layer — and catches truncation at the same
/// time.
String pseudoAccented(String message) {
  String accent(String run) =>
      run.split('').map((c) => _accents[c] ?? c).join();
  final padding = _pad * ((message.length * 0.4).ceil().clamp(1, 40));
  return '[${transformIcu(message, accent)} $padding]';
}

/// `ar-XB`: forced RTL, with the Latin reversed.
///
/// Catches a hard-coded `left`/`right` without anybody having to read Arabic.
String pseudoRtl(String message) {
  String reverse(String run) => run.split('').reversed.join();
  // U+200F RLM: the paragraph is RTL whatever its first strong character is,
  // which is what makes a layout that did not mirror visible at a glance.
  return '‏${transformIcu(message, reverse)}';
}

void main() {
  final template =
      jsonDecode(File('lib/l10n/arb/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;

  for (final (locale, transform) in [
    ('en_XA', pseudoAccented),
    ('ar_XB', pseudoRtl),
  ]) {
    final out = <String, dynamic>{'@@locale': locale};
    for (final key in template.keys.where((k) => !k.startsWith('@'))) {
      out[key] = transform(template[key]! as String);
    }
    File('test/fixtures/app_$locale.fixture.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(out)}\n',
    );
    stdout.writeln('wrote test/fixtures/app_$locale.fixture.json');
  }
}
