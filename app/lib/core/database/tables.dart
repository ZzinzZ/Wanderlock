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

/// The user's own ordering of places — the itinerary lens.
///
/// The only table in the app a lens writes to, and the reason that does not
/// break rule 1: a row here says "I plan to go", never "I have been". What has
/// been is [VisitStateRows], it arrives from the server, and nothing in this
/// table can change it.
///
/// Stores an id and a rank, nothing else. Name, position and visited flag all
/// have owners already; duplicating them here would be a second copy to keep
/// in step, and the composition layer can join them back for free.
///
/// Local only in v1 — there is no `userId` because there is no sync. When F9
/// lifts this to the server, that column arrives with the migration that needs
/// it rather than sitting here unused and always holding the same value.
class ItineraryRows extends Table {
  TextColumn get checkpointId => text()();

  /// Zero-based, contiguous, rewritten wholesale on every reorder. Not unique
  /// at the schema level: a reorder writes the new ranks inside one
  /// transaction, and a uniqueness constraint would reject the halfway state
  /// where two rows briefly share a number.
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {checkpointId};
}

/// Where the fog lens has been cleared by moving through the city.
///
/// Belongs to the fog lens alone, and is deliberately not unlock state: a row
/// here reveals map, it never opens a checkpoint. See `TrailPoint`.
class ExploredPointRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  DateTimeColumn get recordedAt => dateTime()();
}

/// One-off facts about this install, such as whether the welcome has been
/// shown. A table rather than a second storage library: drift is already the
/// app's local store (docs/10-libraries.md), and two stores is two things to
/// migrate, back up and reason about.
class AppFlagRows extends Table {
  TextColumn get key => text()();

  BoolColumn get value => boolean()();

  @override
  Set<Column> get primaryKey => {key};
}
