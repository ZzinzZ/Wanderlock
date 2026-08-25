import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// The one door into the unlock layer.
///
/// The client says where it thinks it is and asks. It never decides. Every
/// implementation of this interface answers on behalf of something with
/// authority the phone does not have — which is why the return type is an
/// outcome rather than a boolean the caller could talk itself into.
abstract interface class CheckInService {
  Future<CheckInOutcome> checkIn({
    required String checkpointId,
    required double latitude,
    required double longitude,
  });
}

/// What the authority answered.
///
/// Sealed so a new answer — a mock-location refusal, a QR challenge — forces
/// every screen that handles unlocks to say what it does about it, instead of
/// falling through a default branch into "granted".
sealed class CheckInOutcome {
  const CheckInOutcome();
}

/// Unlocked. [visit] is the record the authority wrote, not one we made up.
class CheckInGranted extends CheckInOutcome {
  const CheckInGranted(this.visit);

  final VisitState visit;
}

/// Refused: the position given is outside this checkpoint's radius.
class CheckInTooFar extends CheckInOutcome {
  const CheckInTooFar({
    required this.distanceMeters,
    required this.radiusMeters,
  });

  final double distanceMeters;
  final int radiusMeters;
}

/// Refused for a reason the user cannot fix by walking: no session, an unknown
/// checkpoint, a malformed request.
class CheckInRejected extends CheckInOutcome {
  const CheckInRejected(this.reason);

  /// The authority's machine-readable reason, for logs and for choosing a
  /// message. Never shown raw.
  final String reason;
}

/// Nobody could be asked — offline, or no authority configured in this build.
///
/// Deliberately distinct from [CheckInRejected]: a refusal is an answer, and
/// this is the absence of one. Telling a walker in a basement that they were
/// "denied" would be a lie about what happened.
class CheckInUnavailable extends CheckInOutcome {
  const CheckInUnavailable();
}
