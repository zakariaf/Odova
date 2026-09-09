/// Reads a PNG's IHDR, without an imaging dependency.
///
/// Three tests wanted this and each grew its own copy: the parity sweep, the
/// app-icon gate and the store-screenshot gate. Three places to fix if the
/// offsets are ever wrong, in a repo that otherwise puts this sort of thing
/// here.
///
/// SPEC.md §2 makes every added package something to audit for a network path,
/// and an IHDR is a fixed sixteen bytes at a fixed offset: eight of signature,
/// then a length and the `IHDR` tag, then width, height, bit depth and colour
/// type. Reading it by hand is cheaper than the audit.
library;

import 'dart:io';
import 'dart:typed_data';

/// A PNG's header, as far as anything here needs it.
typedef PngHeader = ({int width, int height, int colourType});

/// Parses [bytes]' IHDR.
///
/// Colour type is 0 greyscale, 2 truecolour, 3 indexed, 4 greyscale+alpha,
/// 6 truecolour+alpha. Apple rejects a marketing icon carrying either of the
/// two with alpha, as ITMS-90717.
PngHeader pngHeaderOf(Uint8List bytes) {
  int at(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  return (width: at(16), height: at(20), colourType: bytes[25]);
}

/// Parses [file]'s IHDR, reading only the header.
///
/// The first 26 bytes, not the whole file. The store screenshot set is 8 MB of
/// PNG and the gate over it wants 144 bytes of that; reading each file whole to
/// look at two integers is the kind of waste that makes a suite slow for no
/// reason anybody can point at.
PngHeader pngHeaderIn(File file) {
  final handle = file.openSync();
  try {
    return pngHeaderOf(handle.readSync(26));
  } finally {
    handle.closeSync();
  }
}
