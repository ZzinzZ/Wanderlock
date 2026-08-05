@Tags(['live'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_local_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_remote_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_repository_impl.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint_repository.dart';

/// Exercises the whole chain against a real Supabase: server, then cache, then
/// a read with the server taken away.
///
/// Tagged `live` and excluded from CI, which has no Supabase. Run it against
/// the local stack:
///
/// ```
/// npx supabase start
/// dart run tool/seed_content.dart --allow-unverified
/// flutter test --tags live \
///   --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// This covers the data path rather than the pixels. It is the stricter half:
/// the widget tests already prove the screen renders a list, while only this
/// proves the list survives losing the network.
const _url = String.fromEnvironment('SUPABASE_URL');
const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

void main() {
  if (_url.isEmpty || _key.isEmpty) {
    test('skipped: no Supabase configured', () {}, skip: true);
    return;
  }

  late SupabaseClient client;
  late AppDatabase db;
  late CheckpointLocalSource local;

  setUpAll(() async {
    client = SupabaseClient(_url, _key);
    // Row level security grants reads to `authenticated` only, so an
    // unauthenticated client legitimately sees nothing.
    await client.auth.signInAnonymously();
  });

  tearDownAll(() async => client.dispose());

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = CheckpointLocalSource(db);
  });

  tearDown(() => db.close());

  test('checkpoints come back from the real server', () async {
    final rows = await SupabaseCheckpointRemoteSource(() => client).fetchAll();

    expect(rows, isNotEmpty);
    // Coordinates make the round trip through geography and back out of the
    // generated columns. A zero here would mean the geometry never parsed.
    for (final row in rows) {
      expect(row.latitude, isNot(0));
      expect(row.longitude, isNot(0));
      expect(row.radiusMeters, greaterThan(0));
    }
  });

  test('server then cache then offline keeps the same list', () async {
    final online = CheckpointRepositoryImpl(
      local,
      SupabaseCheckpointRemoteSource(() => client),
    );

    expect(await online.refresh(), RefreshOutcome.refreshed);
    final fromServer = await online.readAll();
    expect(fromServer, isNotEmpty);

    // The server is now unreachable. Nothing the user can see may change.
    final unreachable = SupabaseClient('http://127.0.0.1:1', _key);
    addTearDown(unreachable.dispose);
    final offline = CheckpointRepositoryImpl(
      local,
      SupabaseCheckpointRemoteSource(() => unreachable),
    );

    expect(await offline.refresh(), RefreshOutcome.servedFromCache);
    expect(await offline.readAll(), fromServer);
  });

  test('a client that never connected reads the cache, not an error', () async {
    await CheckpointRepositoryImpl(
      local,
      SupabaseCheckpointRemoteSource(() => client),
    ).refresh();

    // Mirrors the seconds between launch and the background connection
    // finishing: the source has no client yet.
    final notConnected = CheckpointRepositoryImpl(
      local,
      SupabaseCheckpointRemoteSource(() => null),
    );

    expect(await notConnected.refresh(), RefreshOutcome.servedFromCache);
    expect(await notConnected.readAll(), isNotEmpty);
  });
}
