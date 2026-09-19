import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/database/database_provider.dart';
import 'package:wanderlock/features/fog/data/fog_trail_local_source.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

final fogTrailRepositoryProvider = Provider<FogTrailRepository>(
  (ref) => FogTrailLocalSource(ref.watch(appDatabaseProvider)),
);

/// The trail as fog holes, ready to be merged with the checkpoint holes.
final fogTrailHolesProvider = Provider<List<FogHole>>((ref) {
  final points = ref.watch(fogTrailControllerProvider);
  return [
    for (final point in points)
      FogHole(
        latitude: point.latitude,
        longitude: point.longitude,
        revealRadiusMeters: FogTrail.revealRadiusMeters,
      ),
  ];
});

/// The trail, held in memory and written through to the store.
///
/// Loaded from the database once; after that every step is appended here and
/// to the store, and nothing reads the store back. Called on every camera
/// frame while panning and on every GPS fix, so it does its own thinning:
/// [FogTrail.extend] keeps one point per step and fills gaps, and only what it
/// returns is kept.
class FogTrailController extends Notifier<List<TrailPoint>> {
  @override
  List<TrailPoint> build() {
    _resume = null;
    Future.microtask(resume);
    return const [];
  }

  /// Shared, because a pan fires many calls before the first read comes back
  /// and each must wait for the same one.
  Future<TrailPoint?>? _resume;

  Future<TrailPoint?> _load() async {
    final stored = await ref.read(fogTrailRepositoryProvider).readAll();
    state = [...stored, ...state];
    return state.isEmpty ? null : state.last;
  }

  /// Where the stored trail ends, or null on a fresh install.
  Future<TrailPoint?> resume() => _resume ??= _load();

  Future<void> record(double latitude, double longitude) async {
    await resume();

    final next = TrailPoint(latitude: latitude, longitude: longitude);
    final added = FogTrail.extend(state.isEmpty ? null : state.last, next);
    if (added.isEmpty) return;

    state = [...state, ...added];
    await ref.read(fogTrailRepositoryProvider).append(added);
  }
}

final fogTrailControllerProvider =
    NotifierProvider<FogTrailController, List<TrailPoint>>(
      FogTrailController.new,
    );
