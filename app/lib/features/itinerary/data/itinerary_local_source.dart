import 'package:drift/drift.dart';

import 'package:wanderlock/core/database/app_database.dart';

/// Drift access for the itinerary table.
///
/// Every write that changes more than one row runs in a transaction. A plan
/// half-reordered is worse than either the old order or the new one, and a
/// drag interrupted by the app being killed is exactly the case this is for.
class ItineraryLocalSource {
  const ItineraryLocalSource(this._db);

  final AppDatabase _db;

  Future<List<String>> readOrder() async {
    final rows = await (_db.select(
      _db.itineraryRows,
    )..orderBy([(row) => OrderingTerm(expression: row.position)])).get();
    return [for (final row in rows) row.checkpointId];
  }

  Stream<List<String>> watchOrder() {
    return (_db.select(_db.itineraryRows)
          ..orderBy([(row) => OrderingTerm(expression: row.position)]))
        .watch()
        .map((rows) => [for (final row in rows) row.checkpointId]);
  }

  /// Appends, unless it is already on the plan.
  ///
  /// The read and the write share a transaction so two quick taps cannot both
  /// see an absent row and both append it.
  Future<void> add(String checkpointId) {
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.itineraryRows)
                ..where((row) => row.checkpointId.equals(checkpointId)))
              .getSingleOrNull();
      if (existing != null) return;

      final count = await _count();
      await _db
          .into(_db.itineraryRows)
          .insert(
            ItineraryRowsCompanion.insert(
              checkpointId: checkpointId,
              position: count,
            ),
          );
    });
  }

  /// Removes, then closes the gap it left.
  ///
  /// Renumbering here rather than tolerating a hole keeps [readOrder] and the
  /// stored positions telling the same story — a hole is invisible in a sorted
  /// read and then surprises the next insert, which would land on a number
  /// already taken.
  Future<void> remove(String checkpointId) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.itineraryRows,
      )..where((row) => row.checkpointId.equals(checkpointId))).go();
      await _renumber(await readOrder());
    });
  }

  Future<void> reorder(List<String> checkpointIds) {
    return _db.transaction(() => _renumber(checkpointIds));
  }

  Future<void> clear() => _db.delete(_db.itineraryRows).go();

  Future<int> _count() async {
    final expression = _db.itineraryRows.checkpointId.count();
    final query = _db.selectOnly(_db.itineraryRows)..addColumns([expression]);
    final row = await query.getSingle();
    return row.read(expression) ?? 0;
  }

  /// Writes ranks 0..n-1 in the order given.
  ///
  /// Assumes it is already inside a transaction — every caller here opens one,
  /// because a partial renumber is the one state this table must never be
  /// observed in.
  Future<void> _renumber(List<String> checkpointIds) async {
    for (var index = 0; index < checkpointIds.length; index++) {
      await (_db.update(_db.itineraryRows)
            ..where((row) => row.checkpointId.equals(checkpointIds[index])))
          .write(ItineraryRowsCompanion(position: Value(index)));
    }
  }
}
