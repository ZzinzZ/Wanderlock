import 'package:wanderlock/features/unlock/domain/check_in_service.dart';
import 'package:wanderlock/features/unlock/domain/checkpoint_geofence.dart';
import 'package:wanderlock/features/unlock/domain/geo_distance.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// A stand-in for the server, used only in builds that have no server.
///
/// **Read this before assuming it is a hole in the security model.**
///
/// The rule is that the client must not decide it has arrived. This class does
/// decide — and it is allowed to exist because it is not shipped alongside a
/// real authority, it *replaces* one. It is constructed only when
/// `AppConfig.hasSupabase` is false, which is to say in a build that has no
/// account, no `visit_state` on any server, and nothing to cheat out of. There
/// is no configuration in which both this and the real service are reachable.
///
/// It is here so the lenses can be built, reviewed and demonstrated before the
/// backend is pointed at a real project. That is a real need: fog, the unlock
/// moment and the collection are the parts of this product a person can have
/// an opinion about, and none of them could be seen without something granting
/// a visit.
///
/// It deliberately applies the *same* rule the SQL applies — measure the
/// distance, compare against that checkpoint's own radius, refuse if it is
/// outside — so that swapping in the real service changes where the answer
/// comes from and not what the app does with it.
class StandInCheckInService implements CheckInService {
  const StandInCheckInService({required this.geofenceOf, this.now});

  /// Where the checkpoint is, according to content the app has cached.
  ///
  /// Returns null for an id it does not know, which the real service answers
  /// as `unknown_checkpoint`.
  final CheckpointGeofence? Function(String checkpointId) geofenceOf;

  /// Injectable so a test can assert on the recorded timestamp.
  final DateTime Function()? now;

  @override
  Future<CheckInOutcome> checkIn({
    required String checkpointId,
    required double latitude,
    required double longitude,
  }) async {
    final geofence = geofenceOf(checkpointId);
    if (geofence == null) return const CheckInRejected('unknown_checkpoint');

    final distance = metresBetween(
      fromLatitude: latitude,
      fromLongitude: longitude,
      toLatitude: geofence.latitude,
      toLongitude: geofence.longitude,
    );

    if (distance > geofence.radiusMeters) {
      return CheckInTooFar(
        distanceMeters: distance,
        radiusMeters: geofence.radiusMeters,
      );
    }

    return CheckInGranted(
      VisitState(
        checkpointId: checkpointId,
        status: VisitStatus.visited,
        visitedAt: (now ?? DateTime.now)(),
        verifiedBy: VerifyMethod.gps,
      ),
    );
  }
}
