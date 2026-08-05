import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// Reads the unlock layer.
///
/// **There is no way to record a visit here, and that is the point.** A visit
/// is granted by the server after it verifies where the user actually is; the
/// client's job is to ask and then to cache the answer. Adding a local write
/// path would make it possible to unlock a checkpoint by editing a phone, and
/// every lens would believe it.
///
/// The check-in request that F4 introduces goes through its own queue, kept
/// deliberately separate so a request awaiting verification can never be
/// mistaken for a granted unlock.
abstract interface class VisitStateRepository {
  /// Every visit this user has, keyed by checkpoint id.
  ///
  /// A map because every lens asks the same question — "is this one open?" —
  /// once per checkpoint while drawing.
  Stream<Map<String, VisitState>> watchAll();

  Future<Map<String, VisitState>> readAll();

  /// Replaces the cache with what the server says.
  ///
  /// The server is the authority. If it no longer lists a visit, neither do
  /// we: a visit that only exists on one phone is not a visit.
  Future<void> cacheAll(List<VisitState> visits);

  /// Pulls the user's visits from the server.
  ///
  /// Never throws and never empties the cache, for the same reason the
  /// checkpoint list does not: someone walking with no signal must keep
  /// seeing what they have already unlocked.
  Future<VisitSyncOutcome> refresh();
}

enum VisitSyncOutcome {
  /// The server answered and the cache was replaced.
  synced,

  /// Unreachable, not signed in, or nothing configured. The cache stands.
  servedFromCache,
}
