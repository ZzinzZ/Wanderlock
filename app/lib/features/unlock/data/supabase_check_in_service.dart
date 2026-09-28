import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wanderlock/features/unlock/domain/check_in_service.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// Asks the `check-in` edge function to verify an arrival.
///
/// The request carries a checkpoint id and a position and nothing else. In
/// particular it does not carry a user id: the function reads that from the
/// verified JWT, because a body field naming the user would let anyone unlock
/// anyone's map.
///
/// The distance is measured in SQL, in the same transaction that writes the
/// visit, and only the service role may run it. A client with a valid session
/// that calls the function directly is refused by the database — verified, not
/// assumed. So this class cannot grant anything by getting its own arithmetic
/// wrong; the worst it can do is misreport an answer it was given.
class SupabaseCheckInService implements CheckInService {
  const SupabaseCheckInService(this._clientOf);

  final SupabaseClient? Function() _clientOf;

  // design-token-ignore: a network timeout is not a design value
  static const _timeout = Duration(seconds: 15);

  static const String functionName = 'check-in';

  @override
  Future<CheckInOutcome> checkIn({
    required String checkpointId,
    required double latitude,
    required double longitude,
  }) async {
    final client = _clientOf();
    if (client == null) return const CheckInUnavailable();

    final FunctionResponse response;
    try {
      response = await client.functions
          .invoke(
            functionName,
            body: <String, Object?>{
              'checkpointId': checkpointId,
              'lat': latitude,
              'lon': longitude,
            },
          )
          .timeout(_timeout);
    } on Object {
      // Unreachable is not refused. A walker underground who is genuinely
      // standing in the right place must not be told they are somewhere else;
      // the queued retry that F4 adds belongs to this branch.
      return const CheckInUnavailable();
    }

    final body = response.data;
    if (body is! Map) return const CheckInRejected('malformed_response');
    final data = body.cast<String, Object?>();

    if (response.status == 200 && data['visit'] is Map) {
      final visit = (data['visit']! as Map).cast<String, Object?>();
      return CheckInGranted(
        VisitState(
          checkpointId: visit['checkpoint_id']! as String,
          status: VisitStatus.parse(visit['status']! as String),
          visitedAt: DateTime.parse(visit['visited_at']! as String),
          verifiedBy: VerifyMethod.parse(visit['verified_by']! as String),
        ),
      );
    }

    final error = data['error'];
    if (error == 'too_far') {
      return CheckInTooFar(
        distanceMeters: (data['distanceMeters']! as num).toDouble(),
        radiusMeters: (data['radiusMeters']! as num).toInt(),
      );
    }

    return CheckInRejected(error is String ? error : 'unknown_error');
  }
}
