import 'package:drift/drift.dart';

import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// Drift-backed cache of the checkpoint list.
///
/// Nothing above the data layer sees a Drift type: rows are mapped to the
/// domain entity here, so swapping the local store later touches this file
/// only.
class CheckpointLocalSource {
  const CheckpointLocalSource(this._db);

  final AppDatabase _db;

  Stream<List<Checkpoint>> watchAll() {
    final query = _db.select(_db.checkpointRows)
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<List<Checkpoint>> readAll() async {
    final query = _db.select(_db.checkpointRows)
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  /// Replaces the cache in one transaction.
  ///
  /// Delete-then-insert rather than upsert, so a checkpoint withdrawn on the
  /// server disappears here too. Running it twice with the same input leaves
  /// the table identical, which is what the seed script's idempotence rests on.
  Future<void> replaceAll(List<Checkpoint> checkpoints, {DateTime? cachedAt}) {
    final stamp = cachedAt ?? DateTime.now();
    return _db.transaction(() async {
      await _db.delete(_db.checkpointRows).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.checkpointRows,
          checkpoints.map((c) => _toRow(c, stamp)),
        );
      });
    });
  }

  static Checkpoint _toDomain(CheckpointRow row) => Checkpoint(
    id: row.id,
    name: row.name,
    latitude: row.latitude,
    longitude: row.longitude,
    radiusMeters: row.radiusMeters,
    category: CheckpointCategory.parse(row.category),
    requiresQrFallback: row.requiresQrFallback,
    address: row.address,
    photoUrl: row.photoUrl,
  );

  static CheckpointRowsCompanion _toRow(Checkpoint c, DateTime cachedAt) =>
      CheckpointRowsCompanion.insert(
        id: c.id,
        name: c.name,
        latitude: c.latitude,
        longitude: c.longitude,
        radiusMeters: c.radiusMeters,
        category: c.category.name,
        requiresQrFallback: Value(c.requiresQrFallback),
        address: Value(c.address),
        photoUrl: Value(c.photoUrl),
        cachedAt: cachedAt,
      );
}
