import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/core/config/supabase_connection.dart';
import 'package:wanderlock/core/database/database_provider.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_bundled_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_local_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_remote_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_repository_impl.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint_repository.dart';

final checkpointRepositoryProvider = Provider<CheckpointRepository>((ref) {
  final local = CheckpointLocalSource(ref.watch(appDatabaseProvider));

  // No Supabase configured means a cache-only build. That is a legitimate
  // mode, not a broken one: the app still draws whatever it has.
  //
  // The client is passed as a getter rather than a value because the
  // connection is established after launch — capturing it here would pin a
  // null forever.
  final remote = AppConfig.hasSupabase
      ? SupabaseCheckpointRemoteSource(() => SupabaseConnection.clientOrNull)
      : null;

  return CheckpointRepositoryImpl(
    local,
    remote,
    const CheckpointBundledSource(),
  );
});

/// The checkpoint list, always sourced from the local cache.
///
/// A stream rather than a future, so a background refresh redraws the screen
/// without the UI having to ask again.
final checkpointsProvider = StreamProvider<List<Checkpoint>>((ref) {
  return ref.watch(checkpointRepositoryProvider).watchAll();
});

/// Pulls fresh content and remembers what happened.
///
/// Held apart from [checkpointsProvider] on purpose: whether the network
/// worked must never decide whether checkpoints are shown. The list comes from
/// the cache regardless; this only drives the "offline" banner.
class CheckpointRefresher extends Notifier<RefreshOutcome?> {
  @override
  RefreshOutcome? build() => null;

  Future<RefreshOutcome> refresh() async {
    final outcome = await ref.read(checkpointRepositoryProvider).refresh();
    state = outcome;
    return outcome;
  }
}

final checkpointRefreshProvider =
    NotifierProvider<CheckpointRefresher, RefreshOutcome?>(
      CheckpointRefresher.new,
    );

/// Fills an empty cache from the bundled pilot content, then asks the server.
///
/// Ordered that way on purpose: the bundle draws the map in milliseconds so
/// nobody watches an empty screen, and the server — when there is one —
/// replaces it moments later. A build with no Supabase simply stops after the
/// first step and is fully usable.
final contentBootstrapProvider = FutureProvider<RefreshOutcome>((ref) async {
  final repository = ref.watch(checkpointRepositoryProvider);
  await repository.seedFromBundleIfEmpty();
  return repository.refresh();
});
