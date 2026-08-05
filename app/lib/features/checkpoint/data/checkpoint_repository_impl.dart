import 'package:wanderlock/features/checkpoint/data/checkpoint_local_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_remote_source.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint_repository.dart';

/// Offline-first checkpoint repository.
///
/// Reads always come from Drift, so drawing the map never waits on a network
/// call. [refresh] is the only thing that touches the network, and it is the
/// one place that decides what a failure means.
class CheckpointRepositoryImpl implements CheckpointRepository {
  const CheckpointRepositoryImpl(this._local, [this._remote]);

  final CheckpointLocalSource _local;

  /// Absent in tests and in any build without Supabase configured. The app
  /// still works: it serves whatever the cache holds.
  final CheckpointRemoteSource? _remote;

  @override
  Stream<List<Checkpoint>> watchAll() => _local.watchAll();

  @override
  Future<List<Checkpoint>> readAll() => _local.readAll();

  @override
  Future<void> cacheAll(List<Checkpoint> checkpoints) =>
      _local.replaceAll(checkpoints);

  @override
  Future<RefreshOutcome> refresh() async {
    if (_remote == null) return RefreshOutcome.noRemoteConfigured;

    final List<Checkpoint> fetched;
    try {
      fetched = await _remote.fetchAll();
    } on Object {
      // Any failure to reach the server is the same thing to a walking user:
      // keep showing the map they already have. Deliberately catching
      // everything rather than a specific network exception — a JSON shape
      // change or a TLS error must not black out a map that is already
      // cached and perfectly usable.
      return RefreshOutcome.servedFromCache;
    }

    // An empty response is treated as a failure, not as "the pilot was
    // deleted". Wiping a working offline map because a query came back empty
    // would be the worst possible reading of an ambiguous answer.
    if (fetched.isEmpty) return RefreshOutcome.servedFromCache;

    await _local.replaceAll(fetched);
    return RefreshOutcome.refreshed;
  }
}
