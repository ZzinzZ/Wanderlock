import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_icons.dart';
import 'package:wanderlock/features/collection/domain/stamp.dart';
import 'package:wanderlock/features/fog/domain/fog_geometry.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';
import 'package:wanderlock/features/itinerary/application/itinerary_providers.dart';
import 'package:wanderlock/features/itinerary/domain/itinerary_entry.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';
import 'package:wanderlock/features/quest/domain/quest_route.dart';
import 'package:wanderlock/features/quest/domain/quest_route_definition.dart';
import 'package:wanderlock/features/quest/domain/quest_step.dart';
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

/// The authored routes, read once from the bundle.
final questRouteDefinitionsProvider =
    FutureProvider<List<QuestRouteDefinition>>(
      (ref) => const QuestRouteBundledSource().readAll(),
    );

/// Every quest, joined to content and to `visit_state`.
///
/// Scope v1 first shipped a single route; since 2026-09-19 it ships many —
/// the original ordered route plus one set per kind of place (docs/08).
///
/// A set may name categories instead of ids: its steps are then every
/// checkpoint of those categories, plus any ids it also lists. A step whose id
/// matches no checkpoint is dropped here rather than drawn as a blank row —
/// the id is authored by hand, and a typo should cost a missing stop, not a
/// crash. A quest left with no steps is dropped too.
final questRoutesProvider = Provider<List<QuestRoute>>((ref) {
  final definitions =
      ref.watch(questRouteDefinitionsProvider).value ?? const [];
  final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
  final visited = ref.watch(_visitedIdsProvider);
  final byId = <String, Checkpoint>{
    for (final checkpoint in checkpoints) checkpoint.id: checkpoint,
  };

  final routes = <QuestRoute>[];
  for (final definition in definitions) {
    final ids = <String>[
      ...definition.checkpointIds,
      for (final checkpoint in checkpoints)
        if (definition.categories.contains(checkpoint.category.name) &&
            !definition.checkpointIds.contains(checkpoint.id))
          checkpoint.id,
    ];
    final steps = <QuestStep>[
      for (final id in ids)
        if (byId[id] case final checkpoint?)
          QuestStep(
            checkpointId: id,
            name: checkpoint.name,
            isDone: visited.contains(id),
          ),
    ];
    if (steps.isEmpty) continue;
    routes.add(
      QuestRoute(
        id: definition.id,
        name: definition.name,
        summary: definition.summary,
        steps: steps,
        kind: definition.kind,
      ),
    );
  }
  return routes;
});

/// Which building sticker a checkpoint wears, by id — for lenses that hold
/// only ids (a stamp, a quest step) and may not import the checkpoint feature.
final landmarkLookupProvider = Provider<String Function(String)>((ref) {
  final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
  final byId = <String, Checkpoint>{
    for (final checkpoint in checkpoints) checkpoint.id: checkpoint,
  };
  return (id) {
    final checkpoint = byId[id];
    return checkpoint == null
        ? LandmarkArt.palace
        : CheckpointIcons.landmarkOf(checkpoint);
  };
});

/// The user's plan, in their order, with names and ticks joined on.
///
/// An id with no matching checkpoint is dropped for the same reason as above.
/// Here it is a likelier case than a typo: content can lose a place between
/// releases, and a plan made last month should quietly shrink rather than
/// render a row with no name.
final itineraryEntriesProvider = Provider<List<ItineraryEntry>>((ref) {
  final order = ref.watch(itineraryOrderProvider).value ?? const [];
  final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
  final visited = ref.watch(_visitedIdsProvider);
  final byId = <String, Checkpoint>{
    for (final checkpoint in checkpoints) checkpoint.id: checkpoint,
  };

  final entries = <ItineraryEntry>[];
  for (final id in order) {
    final checkpoint = byId[id];
    if (checkpoint == null) continue;
    entries.add(
      ItineraryEntry(
        checkpointId: id,
        name: checkpoint.name,
        // Rebuilt from the surviving rows, so a dropped place cannot leave a
        // gap in what the screen numbers.
        position: entries.length,
        isVisited: visited.contains(id),
      ),
    );
  }
  return entries;
});

/// Whether a place is already on the plan — for the add button on the sheet.
final isOnItineraryProvider = Provider.family<bool, String>((
  ref,
  checkpointId,
) {
  final order = ref.watch(itineraryOrderProvider).value ?? const [];
  return order.contains(checkpointId);
});
