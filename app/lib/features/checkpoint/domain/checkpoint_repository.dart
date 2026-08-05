import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

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
}
