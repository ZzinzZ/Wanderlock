import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// What a [CheckpointRepository.refresh] actually did.
///
/// Returned rather than thrown, because none of these is an error the user
/// needs to see: a walker with a cached map is fine either way. The caller
/// uses it to decide whether to show "showing offline data", nothing more.
enum RefreshOutcome {
  /// The server answered and the cache was replaced.
  refreshed,

  /// The server could not be reached, or answered with nothing. The cache is
  /// untouched and still being served.
  servedFromCache,

  /// This build has no Supabase configuration, so there was nothing to call.
  noRemoteConfigured,
}

/// Reads the pilot's checkpoints.
///
/// Offline first: [watchAll] serves whatever is cached and never waits on a
/// network call, so opening the app in a basement still draws the map. Fresh
/// content arrives through [cacheAll] and the stream re-emits.
abstract interface class CheckpointRepository {
  /// Emits the cached checkpoints immediately, then again on every change.
  Stream<List<Checkpoint>> watchAll();

  /// One-shot read of the cache.
  Future<List<Checkpoint>> readAll();

  /// Replaces the cache with [checkpoints].
  ///
  /// Must be safe to run twice with the same input: content is re-fetched on
  /// every launch, and a seed that duplicated rows would put the same place on
  /// the map twice.
  Future<void> cacheAll(List<Checkpoint> checkpoints);

  /// Pulls fresh content from the server into the cache.
  ///
  /// Never throws and never empties the cache. Losing the network mid-walk is
  /// the normal case this app is built for, not an error state.
  Future<RefreshOutcome> refresh();
}
