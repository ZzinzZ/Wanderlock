import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// Drift-backed cache of the unlock layer.
///
/// Rows are scoped to one user id. The column exists locally even though a
/// phone normally holds one account, because a second account signing in must
/// not inherit the first one's unlocks — that would hand out a finished map
/// to someone who never walked it.
class VisitStateLocalSource {
  const VisitStateLocalSource(this._db);

  final AppDatabase _db;

  Stream<Map<String, VisitState>> watchAll(String userId) {
    final query = _db.select(_db.visitStateRows)
      ..where((row) => row.userId.equals(userId));
    return query.watch().map(_toMap);
  }

  Future<Map<String, VisitState>> readAll(String userId) async {
    final query = _db.select(_db.visitStateRows)
      ..where((row) => row.userId.equals(userId));
    return _toMap(await query.get());
  }

  /// Replaces this user's visits in one transaction.
  ///
  /// Scoped delete, not a table wipe: another account's cached visits are
  /// none of this sync's business.
  Future<void> replaceAll(String userId, List<VisitState> visits) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.visitStateRows,
      )..where((row) => row.userId.equals(userId))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.visitStateRows,
          visits.map((visit) => _toRow(userId, visit)),
        );
      });
    });
  }

  static Map<String, VisitState> _toMap(List<VisitStateRow> rows) {
    return {
      for (final row in rows)
        row.checkpointId: VisitState(
          checkpointId: row.checkpointId,
          status: VisitStatus.parse(row.status),
          visitedAt: row.visitedAt,
          verifiedBy: VerifyMethod.parse(row.verifiedBy),
        ),
    };
  }

  static VisitStateRowsCompanion _toRow(String userId, VisitState visit) =>
      VisitStateRowsCompanion.insert(
        userId: userId,
        checkpointId: visit.checkpointId,
        status: visit.status.name,
        visitedAt: visit.visitedAt,
        verifiedBy: visit.verifiedBy.name,
      );
}
