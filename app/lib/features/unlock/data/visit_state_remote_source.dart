import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// Reads this user's visits from Supabase.
///
/// Read only, and enforced by more than convention: `visit_state` grants
/// `SELECT` to `authenticated` and nothing else, and carries no insert policy.
/// A write attempted from here is refused by the database twice over.
abstract interface class VisitStateRemoteSource {
  Future<List<VisitState>> fetchAll();
}

class SupabaseVisitStateRemoteSource implements VisitStateRemoteSource {
  const SupabaseVisitStateRemoteSource(this._clientOf);

  final SupabaseClient? Function() _clientOf;

  // design-token-ignore: a network timeout is not a design value
  static const _timeout = Duration(seconds: 10);

  static const _columns = 'checkpoint_id, status, visited_at, verified_by';

  @override
  Future<List<VisitState>> fetchAll() async {
    final client = _clientOf();
    if (client == null) {
      throw StateError('Supabase is not connected yet');
    }

    // No user filter. Row level security already restricts this to the
    // signed-in user, and filtering here as well would suggest the client is
    // what keeps one account's data away from another.
    final rows = await client
        .from('visit_state')
        .select(_columns)
        .timeout(_timeout);
    return rows.map(_fromJson).toList();
  }

  static VisitState _fromJson(Map<String, dynamic> json) => VisitState(
    checkpointId: json['checkpoint_id'] as String,
    status: VisitStatus.parse(json['status'] as String),
    visitedAt: DateTime.parse(json['visited_at'] as String),
    verifiedBy: VerifyMethod.parse(json['verified_by'] as String),
  );
}
