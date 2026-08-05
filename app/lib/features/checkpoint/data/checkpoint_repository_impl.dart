import 'package:wanderlock/features/checkpoint/data/checkpoint_local_source.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint_repository.dart';

/// Cache-only implementation.
///
/// Every read is served from Drift, so the app never blocks on the network to
/// draw the map. The remote source that fills the cache arrives with the
/// Supabase wiring; until then [cacheAll] is the only way content gets in,
/// which is what the seed script and the tests use.
class CheckpointRepositoryImpl implements CheckpointRepository {
  const CheckpointRepositoryImpl(this._local);

  final CheckpointLocalSource _local;

  @override
  Stream<List<Checkpoint>> watchAll() => _local.watchAll();

  @override
  Future<List<Checkpoint>> readAll() => _local.readAll();

  @override
  Future<void> cacheAll(List<Checkpoint> checkpoints) =>
      _local.replaceAll(checkpoints);
}
