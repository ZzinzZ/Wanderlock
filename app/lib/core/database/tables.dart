import 'package:drift/drift.dart';

/// Local mirror of `public.checkpoints`.
///
/// Position is stored as two reals rather than a geometry: SQLite has no
/// PostGIS, and the only thing the client does offline with a position is draw
/// it and measure a straight-line distance. Whether a check-in counts is
/// decided by the server, which does have PostGIS — see the check-in edge
/// function. Duplicating that maths here would be a second source of truth for
/// the one decision the client is not allowed to make.
class CheckpointRows extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  IntColumn get radiusMeters => integer()();

  /// Stored as the enum's name, not its index: reordering the Dart enum must
  /// not silently reinterpret rows already on disk.
  TextColumn get category => text()();

  BoolColumn get requiresQrFallback =>
      boolean().withDefault(const Constant(false))();

  TextColumn get address => text().nullable()();

  TextColumn get photoUrl => text().nullable()();

  /// When this row was last written from the server. Lets the app tell a user
  /// how stale the offline map is.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of `public.visit_state` — the unlock layer.
///
/// Read-only as far as the client is concerned. Rows arrive from the server
/// after a verified check-in and are cached so every lens can read them
/// offline. Nothing in the app writes a visit here on its own authority; the
/// offline check-in queue that F4 adds is a separate table, so that a request
/// waiting to be verified can never be mistaken for a granted unlock.
class VisitStateRows extends Table {
  TextColumn get userId => text()();

  TextColumn get checkpointId => text()();

  TextColumn get status => text()();

  DateTimeColumn get visitedAt => dateTime()();

  TextColumn get verifiedBy => text()();

  @override
  Set<Column> get primaryKey => {userId, checkpointId};
}
