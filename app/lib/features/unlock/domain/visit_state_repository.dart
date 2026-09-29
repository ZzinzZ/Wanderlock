import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// Reads the unlock layer.
///
/// **There is no way to record a visit here, and that is the point.** The
/// server grants a visit after verifying where the user is; the client asks
/// and caches the answer. A local write path would let anyone unlock a
/// checkpoint by editing a phone, and every lens would believe it.
abstract interface class VisitStateRepository {
  /// Every visit this user has, keyed by checkpoint id — a map because
  /// every lens asks the same question once per checkpoint while drawing.
  Stream<Map<String, VisitState>> watchAll();

  Future<Map<String, VisitState>> readAll();

  /// Replaces the cache with what the server says. If it no longer lists a
  /// visit, neither do we: a visit on one phone alone is not a visit.
  Future<void> cacheAll(List<VisitState> visits);

  /// Stores one visit the authority has just granted — [cacheAll] narrowed
  /// to a row, so the three-second animation does not wait on a round trip.
  /// Still a cache write, not a decision, and safe to run twice.
  Future<void> cacheGranted(VisitState visit);

  /// Pulls the user's visits from the server. Never throws and never empties
  /// the cache: someone with no signal keeps seeing what they unlocked.
  Future<VisitSyncOutcome> refresh();
}

enum VisitSyncOutcome {
  /// The server answered and the cache was replaced.
  synced,

  /// Unreachable, not signed in, or nothing configured. The cache stands.
  servedFromCache,
}
