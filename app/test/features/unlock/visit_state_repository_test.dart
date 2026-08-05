import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/unlock/data/visit_state_local_source.dart';
import 'package:wanderlock/features/unlock/data/visit_state_remote_source.dart';
import 'package:wanderlock/features/unlock/data/visit_state_repository_impl.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';
import 'package:wanderlock/features/unlock/domain/visit_state_repository.dart';

VisitState _visit(String checkpointId, {VisitStatus? status}) => VisitState(
  checkpointId: checkpointId,
  status: status ?? VisitStatus.visited,
  visitedAt: DateTime.utc(2026, 8, 5, 12),
  verifiedBy: VerifyMethod.gps,
);

class _FakeRemote implements VisitStateRemoteSource {
  _FakeRemote.returning(this._result);
  _FakeRemote.failing(this._error);

  List<VisitState>? _result;
  Object? _error;

  @override
  Future<List<VisitState>> fetchAll() async {
    if (_error != null) {
      Error.throwWithStackTrace(_error!, StackTrace.current);
    }
    return _result!;
  }
}

void main() {
  late AppDatabase db;
  late VisitStateLocalSource local;

  VisitStateRepositoryImpl repositoryFor(
    String userId, {
    VisitStateRemoteSource? remote,
  }) => VisitStateRepositoryImpl(
    local: local,
    userIdOf: () => userId,
    remote: remote,
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = VisitStateLocalSource(db);
  });

  tearDown(() => db.close());

  test('a fresh install has unlocked nothing', () async {
    expect(await repositoryFor('alice').readAll(), isEmpty);
  });

  test('visits are keyed by checkpoint id', () async {
    final repository = repositoryFor('alice');
    await repository.cacheAll([
      _visit('dinh-doc-lap'),
      _visit('cho-ben-thanh'),
    ]);

    final visits = await repository.readAll();
    expect(visits.keys, containsAll(['dinh-doc-lap', 'cho-ben-thanh']));
    expect(visits['dinh-doc-lap']!.isVisited, isTrue);
  });

  test('only visited counts as unlocked', () async {
    final repository = repositoryFor('alice');
    await repository.cacheAll([
      _visit('seen-only', status: VisitStatus.revealed),
    ]);

    expect((await repository.readAll())['seen-only']!.isVisited, isFalse);
  });

  // A second account on the same phone must start from nothing. Inheriting
  // the first account's unlocks would hand someone a finished map they never
  // walked.
  test('one account cannot see another account\'s unlocks', () async {
    await repositoryFor('alice').cacheAll([_visit('dinh-doc-lap')]);

    expect(await repositoryFor('bob').readAll(), isEmpty);
    expect(await repositoryFor('alice').readAll(), hasLength(1));
  });

  test('syncing one account leaves the other alone', () async {
    await repositoryFor('alice').cacheAll([_visit('dinh-doc-lap')]);
    await repositoryFor('bob').cacheAll([_visit('cho-binh-tay')]);

    expect((await repositoryFor('alice').readAll()).keys, ['dinh-doc-lap']);
    expect((await repositoryFor('bob').readAll()).keys, ['cho-binh-tay']);
  });

  test('losing the network keeps the unlocks already earned', () async {
    await repositoryFor('alice').cacheAll([_visit('dinh-doc-lap')]);

    final offline = repositoryFor(
      'alice',
      remote: _FakeRemote.failing(Exception('no route to host')),
    );

    expect(await offline.refresh(), VisitSyncOutcome.servedFromCache);
    expect(await offline.readAll(), hasLength(1));
  });

  // Unlike the checkpoint list, an empty answer here is real information: a
  // new device learning that this account has unlocked nothing yet.
  test(
    'an empty server response is accepted, not treated as failure',
    () async {
      await repositoryFor('alice').cacheAll([_visit('dinh-doc-lap')]);

      final repository = repositoryFor(
        'alice',
        remote: _FakeRemote.returning([]),
      );

      expect(await repository.refresh(), VisitSyncOutcome.synced);
      expect(await repository.readAll(), isEmpty);
    },
  );

  test('no session means no sync and no data loss', () async {
    await repositoryFor('alice').cacheAll([_visit('dinh-doc-lap')]);

    final signedOut = repositoryFor(
      '',
      remote: _FakeRemote.returning([_visit('should-not-be-written')]),
    );

    expect(await signedOut.refresh(), VisitSyncOutcome.servedFromCache);
    expect(await repositoryFor('alice').readAll(), hasLength(1));
  });

  test('the server is the authority on what is unlocked', () async {
    final repository = repositoryFor(
      'alice',
      remote: _FakeRemote.returning([_visit('cho-binh-tay')]),
    );
    await repository.cacheAll([_visit('dinh-doc-lap')]);

    expect(await repository.refresh(), VisitSyncOutcome.synced);
    expect((await repository.readAll()).keys, ['cho-binh-tay']);
  });
}
