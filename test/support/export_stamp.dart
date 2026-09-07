// A real export stamp for tests.
//
// One constant, because the alternative is each test inventing four values and
// the production caller inventing none — which is what happened: EPIC-05's
// safety copy took `nowUtcMs`, `appVersion`, `appBuild` and `platform` as four
// parameters with placeholder defaults, `bootstrap()` passed none, and every
// real escape route on every phone was stamped `1970-01-01T00:00:00Z` by an
// app with no name. Making them one required value is what fixed it; this is
// what the tests pass.
import 'package:odova/core/export/export_stamp.dart';

/// A pinned stamp: 2026-09-02T18:41Z, version 1.0.0, build 42, Android.
const ExportStamp kTestExportStamp = ExportStamp(
  nowUtcMs: 1788374460000,
  appVersion: '1.0.0',
  appBuild: '42',
  platform: 'android',
);
