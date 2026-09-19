import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/database/database_provider.dart';
import 'package:wanderlock/features/itinerary/data/itinerary_local_source.dart';
import 'package:wanderlock/features/itinerary/data/itinerary_repository_impl.dart';
import 'package:wanderlock/features/itinerary/domain/itinerary_repository.dart';

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepositoryImpl(
    ItineraryLocalSource(ref.watch(appDatabaseProvider)),
  );
});

/// The user's chosen order, as ids.
///
/// Ids and not entries: this feature is not allowed to know what a checkpoint
/// is. The composition layer watches this and joins the names on.
final itineraryOrderProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(itineraryRepositoryProvider).watchOrder();
});

/// Edits the plan.
///
/// Every method writes and then returns; nothing is held in memory here. The
/// database is the single copy, [itineraryOrderProvider] is watching it, and
/// the screen redraws from that stream — so an edit cannot leave the list and
/// the store disagreeing, however the write went.
class ItineraryController {
  const ItineraryController(this._repository);

  final ItineraryRepository _repository;

  Future<void> add(String checkpointId) => _repository.add(checkpointId);

  Future<void> remove(String checkpointId) => _repository.remove(checkpointId);

  Future<void> clear() => _repository.clear();

  /// Applies a drag.
  ///
  /// Takes the whole new order rather than a from/to pair, so the store never
  /// has to reproduce the list widget's reorder semantics — and so a future
  /// caller that reorders some other way needs nothing new here.
  Future<void> reorder(List<String> checkpointIds) =>
      _repository.reorder(checkpointIds);
}

final itineraryControllerProvider = Provider<ItineraryController>((ref) {
  return ItineraryController(ref.watch(itineraryRepositoryProvider));
});
