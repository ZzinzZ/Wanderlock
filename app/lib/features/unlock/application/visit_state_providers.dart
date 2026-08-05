import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/core/config/supabase_connection.dart';
import 'package:wanderlock/core/database/database_provider.dart';
import 'package:wanderlock/features/unlock/data/visit_state_local_source.dart';
import 'package:wanderlock/features/unlock/data/visit_state_remote_source.dart';
import 'package:wanderlock/features/unlock/data/visit_state_repository_impl.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';
import 'package:wanderlock/features/unlock/domain/visit_state_repository.dart';

/// The signed-in user, or an empty string before the session exists.
///
/// Empty rather than null so callers cannot forget the case: an empty id
/// matches no cached rows, which is the correct answer for "nobody is signed
/// in yet".
String currentUserId() =>
    SupabaseConnection.clientOrNull?.auth.currentUser?.id ?? '';

final visitStateRepositoryProvider = Provider<VisitStateRepository>((ref) {
  return VisitStateRepositoryImpl(
    local: VisitStateLocalSource(ref.watch(appDatabaseProvider)),
    userIdOf: currentUserId,
    remote: AppConfig.hasSupabase
        ? SupabaseVisitStateRemoteSource(() => SupabaseConnection.clientOrNull)
        : null,
  );
});

/// What this user has unlocked, keyed by checkpoint id.
///
/// **Every lens reads this provider and no lens keeps its own copy.** Fog
/// clears where a checkpoint is visited, a stamp is owned where a checkpoint
/// is visited, a quest step is done where a checkpoint is visited. One
/// arrival, every way of playing — held together by there being exactly one
/// answer to the question.
final visitStateProvider = StreamProvider<Map<String, VisitState>>((ref) {
  return ref.watch(visitStateRepositoryProvider).watchAll();
});

/// Convenience for the question every lens asks while drawing.
bool isCheckpointVisited(Ref ref, String checkpointId) {
  final visits = ref.watch(visitStateProvider).value;
  return visits?[checkpointId]?.isVisited ?? false;
}
