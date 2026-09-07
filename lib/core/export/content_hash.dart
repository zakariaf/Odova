// The `content_hash` field: sha256 over the document that contains it.
//
// SPEC.md §6 §2.6. The trick is that the hash covers a document the hash is
// inside, which is only possible because the placeholder and the digest are
// the same LENGTH: write 64 zeros, hash the whole thing, overwrite the zeros
// in place. No byte offset moves, so the hash describes exactly the file on
// disk rather than a shorter one that never existed.
//
// It is an integrity check, not a signature. §2 has no server and no key, so
// anybody can recompute it after editing the file — and that is fine: the
// failure it catches is a truncated download or a half-written file, which is
// the failure that actually happens to a backup.
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// What a `content_hash` field holds before the digest is written into it.
///
/// `sha256:` plus sixty-four zeros, and the LENGTH is the whole trick: the
/// hash covers a document the hash is inside, which only works because the
/// placeholder and the digest are the same size. No byte offset moves.
///
/// In `lib/core/export/` rather than in the backup feature because BOTH the
/// backup writer and the pre-migration safety copy stamp it, and they live in
/// different layers — the feature and `lib/data` — so neither can own it. The
/// safety copy wrote `null` here until the review pass over EPIC-15, which
/// made every escape-route file import with a "this has been edited" warning.
const String kContentHashPlaceholder =
    'sha256:0000000000000000000000000000000000000000000000000000000000000000';

/// The `sha256:…` digest of [document], which must contain the placeholder.
///
/// Over the UTF-8 BYTES, not the string: a hash of Dart's UTF-16 would differ
/// from one computed by any other tool over the same file, which defeats the
/// point of writing it down.
String contentHashOf(String document) {
  final digest = sha256.convert(utf8.encode(document));
  return 'sha256:$digest';
}

/// [document] with its placeholder replaced by the real hash.
///
/// Throws if the placeholder is absent: a document without it would be hashed
/// and then not carry the hash, which is worse than no hash at all because it
/// looks like one.
String withContentHash(String document) {
  if (!document.contains(kContentHashPlaceholder)) {
    throw ArgumentError.value(
      document.length,
      'document',
      'has no content_hash placeholder to overwrite',
    );
  }
  final hash = contentHashOf(document);
  assert(
    hash.length == kContentHashPlaceholder.length,
    'the hash and its placeholder must be the same length, or every byte '
    'after it moves and the digest describes a document that never existed',
  );
  return document.replaceFirst(kContentHashPlaceholder, hash);
}

/// Whether [document]'s `content_hash` matches its contents.
///
/// Recomputed by putting the placeholder BACK, which is the only way to hash
/// the same bytes the writer hashed.
bool contentHashMatches(String document) {
  // The whitespace is optional because it is not part of the format: a file
  // written compactly and one written with a space between key and value are
  // the same document, and a reader that only accepted one of them would
  // refuse to verify a file some other tool re-serialised.
  final match = RegExp(
    r'"content_hash":\s*"(sha256:[0-9a-f]{64})"',
  ).firstMatch(document);
  if (match == null) return false;

  final claimed = match.group(1)!;
  final restored = document.replaceFirst(claimed, kContentHashPlaceholder);
  return contentHashOf(restored) == claimed;
}
