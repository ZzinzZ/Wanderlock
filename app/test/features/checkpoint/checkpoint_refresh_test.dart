import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_local_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_remote_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_repository_impl.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint_repository.dart';

Checkpoint _checkpoint(String id) => Checkpoint(
  id: id,
  name: 'Checkpoint $id',
  latitude: 10.777,
  longitude: 106.695,
  radiusMeters: 60,
  category: CheckpointCategory.monument,
);

/// Stands in for the network so the offline paths can be exercised without
/// one. Real connectivity is verified separately against a live Supabase.
class _FakeRemote implements CheckpointRemoteSource {
  _FakeRemote.returning(this._result);
  _FakeRemote.failing(this._error);

  List<Checkpoint>? _result;
  Object? _error;
  int callCount = 0;

  @override
  Future<List<Checkpoint>> fetchAll() async {
    callCount++;
    // Rethrown this way rather than with `throw`, so the fake can carry any
    // object — the point of these tests is that the repository survives
    // whatever comes out of the network layer, not just tidy Exceptions.
    if (_error != null) {
      Error.throwWithStackTrace(_error!, StackTrace.current);
    }
    return _result!;
  }
}

void main() {
  late AppDatabase db;
  late CheckpointLocalSource local;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = CheckpointLocalSource(db);
  });

  tearDown(() => db.close());

  test('a successful refresh replaces the cache', () async {
    final remote = _FakeRemote.returning([_checkpoint('a'), _checkpoint('b')]);
    final repository = CheckpointRepositoryImpl(local, remote);

    expect(await repository.refresh(), RefreshOutcome.refreshed);
    expect((await repository.readAll()).length, 2);
  });

  // The Definition of Done for F2: turn the network off and the checkpoints
  // are still there.
  test('losing the network keeps serving the cached checkpoints', () async {
    await CheckpointRepositoryImpl(
      local,
      _FakeRemote.returning([_checkpoint('a'), _checkpoint('b')]),
    ).refresh();

    final offline = CheckpointRepositoryImpl(
      local,
      _FakeRemote.failing(Exception('no route to host')),
    );

    expect(await offline.refresh(), RefreshOutcome.servedFromCache);
    expect((await offline.readAll()).length, 2);
  });

  test('a network failure is never rethrown at the caller', () async {
    final repository = CheckpointRepositoryImpl(
      local,
      _FakeRemote.failing(StateError('malformed response')),
    );

    await expectLater(repository.refresh(), completes);
  });

  // An empty answer is ambiguous, and the destructive reading of it — "the
  // pilot was deleted" — would black out a map that is working fine.
  test('an empty response does not wipe a working cache', () async {
    await CheckpointRepositoryImpl(
      local,
      _FakeRemote.returning([_checkpoint('a')]),
    ).refresh();

    final repository = CheckpointRepositoryImpl(
      local,
      _FakeRemote.returning([]),
    );

    expect(await repository.refresh(), RefreshOutcome.servedFromCache);
    expect((await repository.readAll()).length, 1);
  });

  test('a build with no Supabase configured still reads its cache', () async {
    final repository = CheckpointRepositoryImpl(local);
    await repository.cacheAll([_checkpoint('a')]);

    expect(await repository.refresh(), RefreshOutcome.noRemoteConfigured);
    expect((await repository.readAll()).length, 1);
  });

  test('refreshing twice with the same content does not duplicate', () async {
    final remote = _FakeRemote.returning([_checkpoint('a'), _checkpoint('b')]);
    final repository = CheckpointRepositoryImpl(local, remote);

    await repository.refresh();
    await repository.refresh();

    expect(remote.callCount, 2);
    expect((await repository.readAll()).length, 2);
  });
}
