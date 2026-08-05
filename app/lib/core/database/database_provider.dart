import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/database/app_database.dart';

/// The one database instance for the whole app.
///
/// Opened lazily and closed with the container, so tests can override it with
/// an in-memory database and never touch the filesystem.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
