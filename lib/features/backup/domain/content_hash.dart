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
import 'package:odova/features/backup/domain/backup_format.dart';

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
  final match = RegExp(
    '"content_hash": "(sha256:[0-9a-f]{64})"',
  ).firstMatch(document);
  if (match == null) return false;

  final claimed = match.group(1)!;
  final restored = document.replaceFirst(claimed, kContentHashPlaceholder);
  return contentHashOf(restored) == claimed;
}
