import 'package:drift/drift.dart';

/// Local mirror of `public.checkpoints`.
///
/// Position is two reals rather than a geometry: SQLite has no PostGIS, and
/// all the client does with a position is draw it. Whether a check-in counts
/// is the server's decision, and duplicating that maths here would be a second
/// source of truth for the one thing the client may not decide.
class CheckpointRows extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  IntColumn get radiusMeters => integer()();

  /// The enum's name, not its index: reordering the Dart enum must not
  /// reinterpret rows already on disk.
  TextColumn get category => text()();

  BoolColumn get requiresQrFallback =>
      boolean().withDefault(const Constant(false))();

  TextColumn get address => text().nullable()();

  TextColumn get photoUrl => text().nullable()();

  /// When this row was last written from the server, so the app can say how
  /// stale its copy is.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of `public.visit_state` — the unlock layer.
///
/// Read-only as far as the client is concerned: rows arrive from the server
/// after a verified check-in and are cached so every lens can read them
/// without asking again. Nothing in the app writes a visit on its own
/// authority, and there is no queue of unverified ones — unlocking needs the
/// network by design, so a pending request can never be mistaken for a grant.
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
/// The only table a lens writes to, and that does not break rule 1: a row here
/// says "I plan to go", never "I have been". What has been is
/// [VisitStateRows], and nothing in this table can change it.
///
/// An id and a rank, nothing else. Name, position and visited flag all have
/// owners already, and the composition layer joins them back for free.
///
/// Local only in v1: no `userId`, because there is no sync yet.
class ItineraryRows extends Table {
  TextColumn get checkpointId => text()();

  /// Zero-based, contiguous, rewritten wholesale on every reorder. Not unique
  /// at the schema level: one transaction rewrites every rank, and a unique
  /// constraint would reject the halfway state where two rows briefly match.
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
/// local store, and two stores is two things to migrate and reason about.
class AppFlagRows extends Table {
  TextColumn get key => text()();

  BoolColumn get value => boolean()();

  @override
  Set<Column> get primaryKey => {key};
}
