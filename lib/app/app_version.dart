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
