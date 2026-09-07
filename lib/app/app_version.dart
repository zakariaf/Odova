// The version string the About row and `settings.about` show.
//
// A constant with a test behind it, and not `package_info_plus`. That plugin
// reads the value the platform was built with, which is the honest source —
// and it is a dependency with a native side on both platforms, for one string
// that this repo already knows at build time. SPEC.md §2 refuses anything that
// opens a socket and `dependency-hygiene` asks what each package buys; this
// one buys a lookup we can do with a `const` and a gate.
//
// `version_matches_pubspec_test.dart` parses `pubspec.yaml` and asserts these
// two agree, so the drift this trades for is a red test rather than a wrong
// number in front of a user reporting a bug.

/// The marketing version — `0.1.0`, never the build number.
///
/// SPEC.md §13: "1.4.0 stays Latin digits regardless of `numerals` — a version
/// string, not a number." It is an identifier a support conversation quotes
/// back, and Eastern Arabic-Indic digits in a bug report help nobody.
const String kAppVersion = '0.1.0';

/// The build number — the `+312` half of `pubspec.yaml`'s version.
///
/// Shown beside the marketing version because they answer different
/// questions: a user quotes `1.4.0` and a store rejection quotes `312`.
const String kAppBuild = '1';

/// The backup format this build reads and writes.
///
/// ONE declaration, here, and `lib/features/backup/domain/backup_format.dart`
/// re-exports it. EPIC-14 left it here with a note saying task 15.1 would take
/// ownership; 15.1 found the better answer to be that `settings.about` and
/// `settings.backup` are different features, `structure_test` refuses one
/// importing the other, and a constant two features need belongs to the app.
///
/// Two copies is how the number on the About screen and the number in the file
/// drift apart, which is a support conversation nobody can resolve.
const int kSupportedFormatVersion = 1;
