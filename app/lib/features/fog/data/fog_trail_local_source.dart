import 'package:drift/drift.dart';

import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

/// The trail, on the device.
///
/// Local only, and on purpose: where someone has wandered is theirs, and
/// nothing about it needs a server to be trusted — it opens no checkpoint.
class FogTrailLocalSource implements FogTrailRepository {
  const FogTrailLocalSource(this._db);

  final AppDatabase _db;

  @override
  Stream<List<TrailPoint>> watch() {
    return (_db.select(
      _db.exploredPointRows,
    )..orderBy([(row) => OrderingTerm(expression: row.id)])).watch().map(
      (rows) => [
        for (final row in rows)
          TrailPoint(latitude: row.latitude, longitude: row.longitude),
      ],
    );
  }

  @override
  Future<void> append(List<TrailPoint> points) async {
    if (points.isEmpty) return;
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAll(_db.exploredPointRows, [
        for (final point in points)
          ExploredPointRowsCompanion.insert(
            latitude: point.latitude,
            longitude: point.longitude,
            recordedAt: now,
          ),
      ]);
    });
  }
}
