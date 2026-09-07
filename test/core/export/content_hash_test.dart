// SPEC.md §6 §2.6's `content_hash`.
import 'package:odova/core/export/content_hash.dart';
import 'package:test/test.dart';

String _doc(String hash) =>
    '{\n  "format": "odova.backup",\n  "content_hash": "$hash",\n'
    '  "vehicles": []\n}';

void main() {
  test('the placeholder and the digest are the same length', () {
    // The whole trick. Write 64 zeros, hash the document that contains them,
    // overwrite in place — no byte offset moves, so the hash describes exactly
    // the file on disk rather than a shorter one that never existed.
    final hashed = withContentHash(_doc(kContentHashPlaceholder));

    expect(hashed.length, _doc(kContentHashPlaceholder).length);
    expect(hashed, isNot(contains(kContentHashPlaceholder)));
  });

  test('a verifier recomputes the same value', () {
    final hashed = withContentHash(_doc(kContentHashPlaceholder));
    expect(contentHashMatches(hashed), isTrue);
  });

  test('one changed byte fails the check', () {
    // The failure this catches is a truncated download or a half-written
    // file, which is the failure that actually happens to a backup.
    final hashed = withContentHash(_doc(kContentHashPlaceholder));
    final tampered = hashed.replaceFirst('"vehicles": []', '"vehicles": [1]');

    expect(contentHashMatches(tampered), isFalse);
  });

  test('a document with no placeholder is refused, not silently hashed', () {
    // Hashing it and then not carrying the hash is worse than no hash at all,
    // because it looks like one.
    expect(
      () => withContentHash('{"format": "odova.backup"}'),
      throwsArgumentError,
    );
  });

  test('the hash is over UTF-8 bytes, not UTF-16 code units', () {
    // A hash of Dart's internal representation would differ from one computed
    // by any other tool over the same file, which defeats writing it down.
    // `ö` is one UTF-16 unit and two UTF-8 bytes.
    expect(
      contentHashOf('ö'),
      'sha256:'
      '6dbd11fd012e225b28a5d94a9b432bc491344f3e92158661be2ae5ae2b8b1ad8',
    );
  });
}
