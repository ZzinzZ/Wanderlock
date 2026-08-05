import 'package:wanderlock/features/unlock/data/visit_state_local_source.dart';
import 'package:wanderlock/features/unlock/data/visit_state_remote_source.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';
import 'package:wanderlock/features/unlock/domain/visit_state_repository.dart';

/// Offline-first unlock layer.
///
/// Reads come from Drift, so a lens can ask what is unlocked while drawing a
/// frame without waiting on anything.
class VisitStateRepositoryImpl implements VisitStateRepository {
  const VisitStateRepositoryImpl({
    required this.local,
    required this.userIdOf,
    this.remote,
  });

  final VisitStateLocalSource local;
  final VisitStateRemoteSource? remote;

  /// Read per call rather than held: the anonymous session is established
  /// after launch, and a repository built at startup would pin an empty id.
  final String Function() userIdOf;

  @override
  Stream<Map<String, VisitState>> watchAll() => local.watchAll(userIdOf());

  @override
  Future<Map<String, VisitState>> readAll() => local.readAll(userIdOf());

  @override
  Future<void> cacheAll(List<VisitState> visits) =>
      local.replaceAll(userIdOf(), visits);

  @override
  Future<VisitSyncOutcome> refresh() async {
    final userId = userIdOf();
    final source = remote;
    if (source == null || userId.isEmpty) {
      return VisitSyncOutcome.servedFromCache;
    }

    final List<VisitState> fetched;
    try {
      fetched = await source.fetchAll();
    } on Object {
      return VisitSyncOutcome.servedFromCache;
    }

    // An empty list IS meaningful here, unlike the checkpoint list: a user
    // who has unlocked nothing yet legitimately has no rows, and a new device
    // must be able to learn that. The protection against wrongly clearing a
    // full cache is that an unreachable server throws rather than returning
    // empty, and that path is handled above.
    await local.replaceAll(userId, fetched);
    return VisitSyncOutcome.synced;
  }
}
