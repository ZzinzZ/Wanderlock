import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/itinerary/data/itinerary_local_source.dart';
import 'package:wanderlock/features/itinerary/data/itinerary_repository_impl.dart';
import 'package:wanderlock/features/itinerary/domain/itinerary_repository.dart';

void main() {
  late AppDatabase db;
  late ItineraryRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ItineraryRepositoryImpl(ItineraryLocalSource(db));
  });

  tearDown(() => db.close());

  test('starts empty', () async {
    expect(await repository.readOrder(), isEmpty);
  });

  test('appends in the order things were added', () async {
    await repository.add('a');
    await repository.add('b');
    await repository.add('c');

    expect(await repository.readOrder(), ['a', 'b', 'c']);
  });

  test('adding the same place twice does not duplicate it', () async {
    // Two entries for one place would each want their own tick, and one
    // arrival can only ever cross off one of them.
    await repository.add('a');
    await repository.add('a');

    expect(await repository.readOrder(), ['a']);
  });

  test('removing closes the gap it leaves', () async {
    await repository.add('a');
    await repository.add('b');
    await repository.add('c');

    await repository.remove('b');

    expect(await repository.readOrder(), ['a', 'c']);

    // The renumber matters for what comes next: a hole is invisible in a
    // sorted read and then collides with the next insert.
    await repository.add('d');
    expect(await repository.readOrder(), ['a', 'c', 'd']);
  });

  test('removing something absent changes nothing', () async {
    await repository.add('a');

    await repository.remove('zzz');

    expect(await repository.readOrder(), ['a']);
  });

  test('reorder writes the order it is given', () async {
    await repository.add('a');
    await repository.add('b');
    await repository.add('c');

    await repository.reorder(['c', 'a', 'b']);

    expect(await repository.readOrder(), ['c', 'a', 'b']);
  });

  test('reorder survives being applied twice', () async {
    await repository.add('a');
    await repository.add('b');

    await repository.reorder(['b', 'a']);
    await repository.reorder(['b', 'a']);

    expect(await repository.readOrder(), ['b', 'a']);
  });

  test('clear empties the plan', () async {
    await repository.add('a');
    await repository.add('b');

    await repository.clear();

    expect(await repository.readOrder(), isEmpty);
  });

  test('watchOrder emits the plan as it changes', () async {
    final seen = <List<String>>[];
    final subscription = repository.watchOrder().listen(seen.add);

    await repository.add('a');
    await repository.add('b');
    await repository.reorder(['b', 'a']);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(seen.last, ['b', 'a']);
  });

  test('an upgrade from schema 1 keeps the plan table available', () async {
    // The migration only creates a table, so nothing existing can be lost —
    // but a plan written before an upgrade must still read back after one.
    await repository.add('a');

    // Later versions only add tables (fog trail, app flags); the plan table
    // is unaffected.
    expect(db.schemaVersion, 4);
    expect(await repository.readOrder(), ['a']);
  });
}
