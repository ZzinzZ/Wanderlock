import 'package:wanderlock/features/itinerary/data/itinerary_local_source.dart';
import 'package:wanderlock/features/itinerary/domain/itinerary_repository.dart';

/// The only implementation in v1, and it is local.
///
/// Thin on purpose. There is no remote source to fall back to and no cache to
/// reconcile, so this adds nothing to the local source but the interface —
/// which is the point: when F9 gives the itinerary a server, the merge policy
/// lands here and every caller stays as it is.
class ItineraryRepositoryImpl implements ItineraryRepository {
  const ItineraryRepositoryImpl(this._local);

  final ItineraryLocalSource _local;

  @override
  Future<List<String>> readOrder() => _local.readOrder();

  @override
  Stream<List<String>> watchOrder() => _local.watchOrder();

  @override
  Future<void> add(String checkpointId) => _local.add(checkpointId);

  @override
  Future<void> remove(String checkpointId) => _local.remove(checkpointId);

  @override
  Future<void> reorder(List<String> checkpointIds) =>
      _local.reorder(checkpointIds);

  @override
  Future<void> clear() => _local.clear();
}
