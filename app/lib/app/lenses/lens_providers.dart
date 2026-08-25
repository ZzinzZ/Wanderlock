import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/collection/domain/stamp.dart';
import 'package:wanderlock/features/fog/domain/fog_geometry.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';
import 'package:wanderlock/features/unlock/application/visit_state_providers.dart';
import 'package:wanderlock/features/unlock/domain/checkpoint_geofence.dart';

/// Which lens is on screen.
///
/// Switching it must not touch anything else. Nothing in this file writes
/// `visit_state`, and no lens keeps a copy of it, which is why a switch is
/// only ever a change of drawing.
class LensController extends Notifier<Lens> {
  @override
  Lens build() => Lens.initial;

  void select(Lens lens) => state = lens;
}

final lensProvider = NotifierProvider<LensController, Lens>(LensController.new);

/// The one place that joins content to unlock state.
///
/// Every derived view below is built here, in the composition layer, and
/// handed to a lens as plain numbers. That is what lets `fog` and
/// `collection` stay ignorant of each other and of `checkpoint`: they receive
/// what they need instead of reaching for it.
final _visitedIdsProvider = Provider<Set<String>>((ref) {
  final visits = ref.watch(visitStateProvider).value ?? const {};
  return {
    for (final entry in visits.entries)
      if (entry.value.isVisited) entry.key,
  };
});

/// Exposed for the marker layer, which paints a visited checkpoint differently.
final visitedCheckpointIdsProvider = _visitedIdsProvider;

/// Where the fog has been cleared.
///
/// Derived from `visit_state` on every rebuild rather than accumulated: fog
/// that remembered its own holes would be a second record of what is unlocked,
/// and the first thing to go out of step after a sync.
final fogHolesProvider = Provider<List<FogHole>>((ref) {
  final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
  final visited = ref.watch(_visitedIdsProvider);

  return [
    for (final checkpoint in checkpoints)
      if (visited.contains(checkpoint.id))
        FogHole(
          latitude: checkpoint.latitude,
          longitude: checkpoint.longitude,
          revealRadiusMeters: FogGeometry.revealRadiusMeters(
            checkpoint.radiusMeters,
          ),
        ),
  ];
});

/// The album, one stamp per checkpoint, owned where the checkpoint is visited.
final stampsProvider = Provider<List<Stamp>>((ref) {
  final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
  final visited = ref.watch(_visitedIdsProvider);

  return [
    for (final checkpoint in checkpoints)
      Stamp(
        checkpointId: checkpoint.id,
        name: checkpoint.name,
        isOwned: visited.contains(checkpoint.id),
        photoUrl: checkpoint.photoUrl,
      ),
  ];
});

/// Fills the seam `unlock` leaves for a checkpoint's position and radius.
///
/// Installed as an override on [checkpointGeofenceLookupProvider] in
/// `main.dart`. Written here because this is the layer allowed to see both
/// features at once.
CheckpointGeofence? Function(String) buildGeofenceLookup(Ref ref) {
  final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
  final byId = <String, Checkpoint>{
    for (final checkpoint in checkpoints) checkpoint.id: checkpoint,
  };

  return (checkpointId) {
    final checkpoint = byId[checkpointId];
    if (checkpoint == null) return null;
    return CheckpointGeofence(
      latitude: checkpoint.latitude,
      longitude: checkpoint.longitude,
      radiusMeters: checkpoint.radiusMeters,
    );
  };
}
