import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/itinerary/application/itinerary_providers.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';
import 'package:wanderlock/features/unlock/application/visit_state_providers.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// The architecture argument, as a test.
///
/// Rule 1 of the project: every lens reads one `visit_state`, and no lens
/// keeps its own copy. This file is the "+ test" half of the F5 requirement
/// that the rule be verified "by reading the code **and** a test" — it changes
/// exactly one thing, the unlock layer's answer, and checks that all four
/// lenses moved together with nothing else touched.
///
/// If someone ever gives a lens its own store, this is what should go red.
Checkpoint _checkpoint(String id, String name) => Checkpoint(
  id: id,
  name: name,
  latitude: 10.77,
  longitude: 106.69,
  radiusMeters: 60,
  category: CheckpointCategory.monument,
);

VisitState _visited(String id) => VisitState(
  checkpointId: id,
  status: VisitStatus.visited,
  visitedAt: DateTime.utc(2026, 9, 8, 12),
  verifiedBy: VerifyMethod.gps,
);

/// The pilot content, cut down to the three places this file talks about.
final _checkpoints = [
  _checkpoint('independence-palace', 'Dinh Độc Lập'),
  _checkpoint('central-post-office', 'Bưu điện Trung tâm Sài Gòn'),
  _checkpoint('ben-thanh-market', 'Chợ Bến Thành'),
];

/// A route over the first two, so the third can prove a non-route unlock is
/// still seen by the other lenses.
const _routeJson = '''
{"routes": [
  {"id": "r", "name": "Tuyến thử", "summary": "",
   "steps": [{"checkpointId": "independence-palace"},
             {"checkpointId": "central-post-office"}]}
]}''';

ProviderContainer _containerWith({
  required Map<String, VisitState> visits,
  List<String> itinerary = const [],
}) {
  return ProviderContainer(
    overrides: [
      checkpointsProvider.overrideWith((ref) => Stream.value(_checkpoints)),
      visitStateProvider.overrideWith((ref) => Stream.value(visits)),
      itineraryOrderProvider.overrideWith((ref) => Stream.value(itinerary)),
      questRouteDefinitionsProvider.overrideWith(
        (ref) async => QuestRouteBundledSource.parse(_routeJson),
      ),
    ],
  );
}

Future<void> _settle(ProviderContainer container) async {
  // Every derived provider watches at least one async source; one turn of the
  // loop is enough for the seeded values above to land.
  container.listen(checkpointsProvider, (_, _) {});
  container.listen(visitStateProvider, (_, _) {});
  container.listen(itineraryOrderProvider, (_, _) {});
  await container.read(questRouteDefinitionsProvider.future);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('with nothing unlocked, every lens agrees there is nothing', () async {
    final container = _containerWith(
      visits: const {},
      itinerary: ['independence-palace'],
    );
    addTearDown(container.dispose);
    await _settle(container);

    expect(container.read(fogHolesProvider), isEmpty);
    expect(container.read(stampsProvider).where((s) => s.isOwned), isEmpty);
    expect(container.read(questRouteProvider)!.doneCount, 0);
    expect(container.read(itineraryEntriesProvider).single.isVisited, isFalse);
  });

  test('one arrival moves every lens at once', () async {
    // The single change. Nothing else in the container differs from the test
    // above — no lens is told anything, none is asked to refresh.
    final container = _containerWith(
      visits: {'independence-palace': _visited('independence-palace')},
      itinerary: ['independence-palace'],
    );
    addTearDown(container.dispose);
    await _settle(container);

    expect(
      container.read(fogHolesProvider),
      hasLength(1),
      reason: 'the fog did not clear where the unlock landed',
    );
    expect(
      container.read(stampsProvider).where((s) => s.isOwned).map((s) => s.name),
      ['Dinh Độc Lập'],
      reason: 'the stamp was not earned',
    );

    final route = container.read(questRouteProvider)!;
    expect(route.doneCount, 1, reason: 'the quest step did not complete');
    expect(
      route.nextStep?.checkpointId,
      'central-post-office',
      reason: 'the route did not move on',
    );

    expect(
      container.read(itineraryEntriesProvider).single.isVisited,
      isTrue,
      reason: 'the plan did not tick the stop off',
    );
  });

  test('an unlock outside the route still reaches the other lenses', () async {
    // Ben Thanh is on nobody's route. Fog and the album must still see it —
    // which is what "one arrival, every way of playing" means when the ways
    // of playing disagree about which places matter.
    final container = _containerWith(
      visits: {'ben-thanh-market': _visited('ben-thanh-market')},
    );
    addTearDown(container.dispose);
    await _settle(container);

    expect(container.read(fogHolesProvider), hasLength(1));
    expect(
      container.read(stampsProvider).where((s) => s.isOwned).map((s) => s.name),
      ['Chợ Bến Thành'],
    );
    expect(container.read(questRouteProvider)!.doneCount, 0);
  });

  test('a revealed-but-not-visited state unlocks nothing', () async {
    // Only `visited` counts. A lens that treated any row as an unlock would
    // be reading the record without reading what it says.
    final container = _containerWith(
      visits: {
        'independence-palace': VisitState(
          checkpointId: 'independence-palace',
          status: VisitStatus.revealed,
          visitedAt: DateTime.utc(2026, 9, 8, 12),
          verifiedBy: VerifyMethod.gps,
        ),
      },
      itinerary: ['independence-palace'],
    );
    addTearDown(container.dispose);
    await _settle(container);

    expect(container.read(fogHolesProvider), isEmpty);
    expect(container.read(questRouteProvider)!.doneCount, 0);
    expect(container.read(itineraryEntriesProvider).single.isVisited, isFalse);
  });

  group('the composition layer drops what it cannot resolve', () {
    test('an itinerary id with no checkpoint is skipped, and the rest '
        'renumber', () async {
      final container = _containerWith(
        visits: const {},
        itinerary: ['independence-palace', 'deleted-place', 'ben-thanh-market'],
      );
      addTearDown(container.dispose);
      await _settle(container);

      final entries = container.read(itineraryEntriesProvider);
      expect(entries.map((e) => e.checkpointId), [
        'independence-palace',
        'ben-thanh-market',
      ]);
      // No gap where the missing place was, so the screen numbers 1 and 2.
      expect(entries.map((e) => e.position), [0, 1]);
    });
  });
}
