import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// What a [CheckpointRepository.refresh] actually did. Returned rather than
/// thrown: none of these is an error, and the caller only uses it to decide
/// whether to say it is showing offline data.
enum RefreshOutcome {
  /// The server answered and the cache was replaced.
  refreshed,

  /// The server could not be reached, or answered with nothing. The cache is
  /// untouched and still being served.
  servedFromCache,

  /// This build has no Supabase configuration, so there was nothing to call.
  noRemoteConfigured,
}

/// Reads the pilot's checkpoints, cache first: [watchAll] never waits on a
/// network call, and fresh content arrives through [cacheAll].
abstract interface class CheckpointRepository {
  /// Emits the cached checkpoints immediately, then again on every change.
  Stream<List<Checkpoint>> watchAll();

  /// One-shot read of the cache.
  Future<List<Checkpoint>> readAll();

  /// Replaces the cache with [checkpoints]. Must be safe to run twice:
  /// content is re-fetched on every launch.
  Future<void> cacheAll(List<Checkpoint> checkpoints);

  /// Pulls fresh content into the cache. Never throws and never empties it:
  /// losing signal mid-walk is the normal case, not an error state.
  Future<RefreshOutcome> refresh();

  /// Fills an empty cache from the content bundled in the binary, so a first
  /// launch with no server still draws a map. Returns true when it wrote.
  ///
  /// Does nothing when the cache holds rows: the bundle is a floor, never an
  /// authority, and must not overwrite what a server said.
  Future<bool> seedFromBundleIfEmpty();
}
