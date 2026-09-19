import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:wanderlock/core/database/tables.dart';

part 'app_database.g.dart';

/// The local database. One per app, shared by every feature.
///
/// It lives in `core/` rather than inside a feature because several features
/// read from it, and a database owned by one feature would be a cross-feature
/// import waiting to happen.
@DriftDatabase(
  tables: [
    CheckpointRows,
    VisitStateRows,
    ItineraryRows,
    ExploredPointRows,
    AppFlagRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database.
  AppDatabase() : super(driftDatabase(name: _databaseName));

  /// In-memory instance for tests. No file, no platform channels.
  AppDatabase.forTesting(super.executor);

  static const _databaseName = 'wanderlock';

  @override
  int get schemaVersion => 4;

  /// Schema 1 → 2 adds the itinerary.
  ///
  /// Creating the one new table is the whole migration: nothing existing is
  /// touched, so an upgrade cannot lose a cached checkpoint or — far more
  /// importantly — a row of `visit_state`. An unlock that survived a walk in
  /// the sun must survive an app update.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(itineraryRows);
      }
      if (from < 3) {
        await m.createTable(exploredPointRows);
      }
      if (from < 4) {
        await m.createTable(appFlagRows);
      }
    },
  );
}
