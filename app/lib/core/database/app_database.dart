import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:wanderlock/core/database/tables.dart';

part 'app_database.g.dart';

/// The local database. One per app, shared by every feature.
///
/// It lives in `core/` rather than inside a feature because several features
/// read from it, and a database owned by one feature would be a cross-feature
/// import waiting to happen.
@DriftDatabase(tables: [CheckpointRows, VisitStateRows])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database.
  AppDatabase() : super(driftDatabase(name: _databaseName));

  /// In-memory instance for tests. No file, no platform channels.
  AppDatabase.forTesting(super.executor);

  static const _databaseName = 'wanderlock';

  @override
  int get schemaVersion => 1;
}
