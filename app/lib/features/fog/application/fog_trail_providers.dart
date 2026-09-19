import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/database/database_provider.dart';
import 'package:wanderlock/features/fog/data/fog_trail_local_source.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

final fogTrailRepositoryProvider = Provider<FogTrailRepository>(
  (ref) => FogTrailLocalSource(ref.watch(appDatabaseProvider)),
);

final _trailPointsProvider = StreamProvider<List<TrailPoint>>(
  (ref) => ref.watch(fogTrailRepositoryProvider).watch(),
);

/// The trail as fog holes, ready to be merged with the checkpoint holes.
final fogTrailHolesProvider = Provider<List<FogHole>>((ref) {
  final points = ref.watch(_trailPointsProvider).value ?? const [];
  return [
    for (final point in points)
      FogHole(
        latitude: point.latitude,
        longitude: point.longitude,
        revealRadiusMeters: FogTrail.revealRadiusMeters,
      ),
  ];
});

/// Records where the explorer is.
///
/// Called on every camera frame while panning and on every GPS fix, so it
/// does its own thinning: [FogTrail.extend] keeps one point per step and
/// fills gaps, and only what it returns reaches the database.
class FogTrailController extends Notifier<TrailPoint?> {
  /// The last point recorded, held in memory so a pan does not wait on a
  /// database read per frame.
  @override
  TrailPoint? build() => null;

  /// Resumes from the stored trail once, so the first move after a restart
  /// joins up with where the last session ended. Shared, because a pan fires
  /// many calls before the read comes back and each must wait for the same one.
  Future<TrailPoint?>? _resume;

  Future<TrailPoint?> _resumeFromStore() async {
    final stored = await ref.read(fogTrailRepositoryProvider).watch().first;
    if (state == null && stored.isNotEmpty) state = stored.last;
    return state;
  }

  /// Where the stored trail ends, or null on a fresh install.
  Future<TrailPoint?> resume() => _resume ??= _resumeFromStore();

  Future<void> record(double latitude, double longitude) async {
    await resume();

    final next = TrailPoint(latitude: latitude, longitude: longitude);
    final added = FogTrail.extend(state, next);
    if (added.isEmpty) return;

    state = added.last;
    await ref.read(fogTrailRepositoryProvider).append(added);
  }
}

final fogTrailControllerProvider =
    NotifierProvider<FogTrailController, TrailPoint?>(FogTrailController.new);
