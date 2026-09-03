// The database as a provider, closed when the scope is.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/data/db/app_database.dart';

/// The application database.
///
/// `ref.onDispose(db.close)` is not optional bookkeeping: an unclosed
/// connection holds the WAL open, and on a hot restart in development a second
/// connection to the same file then contends with the first.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
