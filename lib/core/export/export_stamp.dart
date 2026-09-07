// Who wrote a file, and when.
//
// Four values that always travel together and always mean the same thing: the
// envelope of SPEC.md §6's backup document. `BackupWriter` takes them and so
// does the pre-migration safety copy, and having them as four loose parameters
// is how one of the two call sites ended up passing none of them.
//
// That is not hypothetical. `writeMigrationSafetyCopy` gained the four with
// placeholder defaults — `nowUtcMs = 0, appVersion = ''` — so that its only
// production caller would not have to change, and it did not change. Every
// real pre-migration safety copy was stamped `1970-01-01T00:00:00Z`, written
// by an app with no name and no version, on the ONE file §6.4.4 calls the
// escape route.
//
// Required, in one object, so the compiler asks.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// The envelope's identity fields.
@immutable
class ExportStamp with ValueEquality {
  /// Creates a stamp.
  const ExportStamp({
    required this.nowUtcMs,
    required this.appVersion,
    required this.appBuild,
    required this.platform,
    this.localOffset = Duration.zero,
  });

  /// The instant of the export, in UTC milliseconds.
  final int nowUtcMs;

  /// The app version that wrote the file.
  final String appVersion;

  /// The build number that wrote the file.
  final String appBuild;

  /// `android` or `ios`.
  final String platform;

  /// The writer's own offset from UTC, for `exported_at_local`.
  ///
  /// Defaulted, and only here: the safety copy is written during a migration
  /// on a device whose timezone database may not be loaded yet, and a wrong
  /// offset on a file nobody reads by hand is a smaller lie than a crash on
  /// cold launch.
  final Duration localOffset;

  @override
  List<Object?> get props => [
    nowUtcMs,
    appVersion,
    appBuild,
    platform,
    localOffset,
  ];
}
