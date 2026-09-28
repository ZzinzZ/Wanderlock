import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/core/database/app_database.dart';
import 'package:wanderlock/features/fog/data/fog_trail_local_source.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

void main() {
  late AppDatabase db;
  late FogTrailLocalSource source;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = FogTrailLocalSource(db);
  });

  tearDown(() => db.close());

  test('a fresh install has explored nothing', () async {
    expect(await source.readAll(), isEmpty);
  });

  test('the trail reads back in the order it was walked', () async {
    const a = TrailPoint(latitude: 10.77, longitude: 106.69);
    const b = TrailPoint(latitude: 10.78, longitude: 106.70);
    const c = TrailPoint(latitude: 10.79, longitude: 106.71);

    await source.append([a, b]);
    await source.append([c]);

    expect(await source.readAll(), [a, b, c]);
  });

  test('appending nothing writes nothing', () async {
    await source.append(const []);
    expect(await source.readAll(), isEmpty);
  });
}
