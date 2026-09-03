// Bidi isolation, applied at the last possible moment.
//
// SPEC.md §5: an isolate is a RENDERING device. One that reaches storage, an
// export or a semantics label is a bug — a screen reader either voices U+2068
// or silently swallows it, and both are wrong. So there are two functions here
// and they are used at opposite ends: [isolate] on the way to a pixel, and
// [stripBidi] on the way to anywhere else.

/// First Strong Isolate. Takes its direction from the first strong character
/// in the run, which is what a mixed `VW Golf TDI 2.0` needs.
///
/// Written as an escape, like every control in this file: a literal U+202E in
/// source reorders the code a reviewer reads, which is the same class of
/// problem these characters exist to solve on screen.
const firstStrongIsolate = '\u2068';

/// Pop Directional Isolate.
const popDirectionalIsolate = '\u2069';

/// Every bidi control character.
const bidiControls = <String>{
  '\u200E', '\u200F', '\u061C', // LRM, RLM, ALM
  '\u2066', '\u2067', '\u2068', '\u2069', // LRI, RLI, FSI, PDI
  '\u202A', '\u202B', '\u202C', '\u202D', '\u202E', // the embeddings
};

/// Left-to-right isolate.
const leftToRightIsolate = '\u2066';

/// Right-to-left isolate.
const rightToLeftIsolate = '\u2067';

/// Wraps [text] so it cannot reorder against the paragraph around it.
///
/// FSI rather than LRI or RLI: the run's own direction is whatever its first
/// strong character says, so one function serves a Latin workshop name inside
/// a Persian sentence AND a Persian note inside an English one.
String isolate(String text) => '$firstStrongIsolate$text$popDirectionalIsolate';

/// Wraps [text] as a left-to-right run, whatever it starts with.
///
/// For a code: a VIN, a plate, a filename, a version string. These are LTR
/// even on an RTL screen, and first-strong would flip a plate that begins with
/// a Persian digit. Prefer a KNOWN direction wherever there is one — first
/// strong mis-guesses on leading punctuation and on leading digits, which are
/// directionally weak.
String isolateLtr(String text) =>
    '$leftToRightIsolate$text$popDirectionalIsolate';

/// Wraps [text] as a right-to-left run, whatever it starts with.
String isolateRtl(String text) =>
    '$rightToLeftIsolate$text$popDirectionalIsolate';

/// Removes every bidi control from [text].
///
/// Used on the way OUT of the render layer: into a semantics label, into an
/// export, into a filename, into anything compared or sorted. Isolation is for
/// pixels.
String stripBidi(String text) {
  var result = text;
  for (final control in bidiControls) {
    result = result.replaceAll(control, '');
  }
  return result;
}

/// Whether [text] carries any bidi control.
bool hasBidiControls(String text) => bidiControls.any(text.contains);
