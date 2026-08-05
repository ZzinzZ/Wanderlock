import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_local_source.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_repository_impl.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

Checkpoint _checkpoint(String id, {String? name, double lat = 10.777}) =>
    Checkpoint(
      id: id,
      name: name ?? 'Checkpoint $id',
      latitude: lat,
      longitude: 106.695,
      radiusMeters: 60,
      category: CheckpointCategory.monument,
    );

void main() {
  late AppDatabase db;
  late CheckpointRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CheckpointRepositoryImpl(CheckpointLocalSource(db));
  });

  tearDown(() => db.close());

  test('an empty cache reads as an empty list, not an error', () async {
    expect(await repository.readAll(), isEmpty);
  });

  test('cached checkpoints come back in a stable order', () async {
    await repository.cacheAll([
      _checkpoint('c', name: 'Cho Binh Tay'),
      _checkpoint('a', name: 'Ben Nha Rong'),
      _checkpoint('b', name: 'Lang Ong Ba Chieu'),
    ]);

    final names = (await repository.readAll()).map((c) => c.name).toList();
    expect(names, ['Ben Nha Rong', 'Cho Binh Tay', 'Lang Ong Ba Chieu']);
  });

  // SQLite sorts by code point, and Vietnamese letters with diacritics live far
  // above plain ASCII, so `Chùa` sorts before `Chợ` — not what a Vietnamese
  // reader expects. Pinned here so the day someone fixes it, this test tells
  // them what changed. Ordering for display belongs in the UI, not the cache.
  test('SQLite does not collate Vietnamese the way a reader would', () async {
    await repository.cacheAll([
      _checkpoint('a', name: 'Chợ Bình Tây'),
      _checkpoint('b', name: 'Chùa Vĩnh Nghiêm'),
    ]);

    final names = (await repository.readAll()).map((c) => c.name).toList();
    expect(names, ['Chùa Vĩnh Nghiêm', 'Chợ Bình Tây']);
  });

  // The seed runs on every launch. If caching twice doubled the rows, the same
  // place would appear twice on the map.
  test('caching the same content twice does not duplicate rows', () async {
    final content = [_checkpoint('a'), _checkpoint('b')];

    await repository.cacheAll(content);
    await repository.cacheAll(content);

    expect((await repository.readAll()).length, 2);
  });

  test('a checkpoint withdrawn upstream disappears from the cache', () async {
    await repository.cacheAll([_checkpoint('a'), _checkpoint('b')]);
    await repository.cacheAll([_checkpoint('a')]);

    expect((await repository.readAll()).map((c) => c.id), ['a']);
  });

  test('every field survives the round trip', () async {
    const original = Checkpoint(
      id: 'post-office',
      name: 'Bưu điện Trung tâm Sài Gòn',
      latitude: 10.7799557,
      longitude: 106.6999921,
      radiusMeters: 45,
      category: CheckpointCategory.architecture,
      requiresQrFallback: true,
      address: '2 Công trường Công xã Paris',
      photoUrl: 'https://example.test/post-office.jpg',
    );

    await repository.cacheAll([original]);

    expect((await repository.readAll()).single, original);
  });

  // Categories are stored by name so that reordering the Dart enum cannot
  // silently reinterpret rows already written to disk.
  test('an unknown category degrades instead of throwing', () {
    expect(CheckpointCategory.parse('museum'), CheckpointCategory.museum);
    expect(
      CheckpointCategory.parse('a-category-shipped-after-this-build'),
      CheckpointCategory.street,
    );
  });

  test('watchAll re-emits when the cache is replaced', () async {
    final emissions = <int>[];
    final subscription = repository.watchAll().listen(
      (list) => emissions.add(list.length),
    );

    await pumpEventQueue();
    await repository.cacheAll([_checkpoint('a')]);
    await pumpEventQueue();
    await repository.cacheAll([_checkpoint('a'), _checkpoint('b')]);
    await pumpEventQueue();

    await subscription.cancel();
    expect(emissions, [0, 1, 2]);
  });
}
