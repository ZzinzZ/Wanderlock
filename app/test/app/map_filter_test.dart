import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/app/lenses/map_filter.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';
import 'package:wanderlock/features/unlock/application/visit_state_providers.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// The map filter exists to make 272 pins readable. The danger it introduces
/// is that hiding a pin starts to look like losing a visit — so these check
/// the two sides separately: what is drawn narrows, what is unlocked does not.
const _checkpoints = [
  Checkpoint(
    id: 'a-market',
    name: 'Chợ A',
    category: CheckpointCategory.market,
    latitude: 10.77,
    longitude: 106.69,
    radiusMeters: 60,
  ),
  Checkpoint(
    id: 'b-market',
    name: 'Chợ B',
    category: CheckpointCategory.market,
    latitude: 10.78,
    longitude: 106.70,
    radiusMeters: 60,
  ),
  Checkpoint(
    id: 'c-park',
    name: 'Công viên C',
    category: CheckpointCategory.park,
    latitude: 10.79,
    longitude: 106.71,
    radiusMeters: 60,
  ),
];

const _routeJson = '''
{"routes": [
  {"id": "markets", "name": "Chợ", "summary": "", "kind": "set",
   "categories": ["market"]},
  {"id": "parks", "name": "Công viên", "summary": "", "kind": "set",
   "categories": ["park"]}
]}''';

ProviderContainer _container({Map<String, VisitState> visits = const {}}) {
  return ProviderContainer(
    overrides: [
      checkpointsProvider.overrideWith((ref) => Stream.value(_checkpoints)),
      visitStateProvider.overrideWith((ref) => Stream.value(visits)),
      questRouteDefinitionsProvider.overrideWith(
        (ref) async => QuestRouteBundledSource.parse(_routeJson),
      ),
    ],
  );
}

Future<void> _settle(ProviderContainer container) async {
  container.listen(checkpointsProvider, (_, _) {});
  container.listen(visitStateProvider, (_, _) {});
  await container.read(questRouteDefinitionsProvider.future);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('with no filter the map draws every place', () async {
    final container = _container();
    await _settle(container);

    expect(container.read(visibleCheckpointsProvider), hasLength(3));
    expect(container.read(activeFilterNameProvider), isNull);
  });

  test('a filter narrows the map to that group', () async {
    final container = _container();
    await _settle(container);

    container.read(mapFilterProvider.notifier).show('markets');

    expect(container.read(visibleCheckpointsProvider).map((c) => c.id), [
      'a-market',
      'b-market',
    ]);
    expect(container.read(activeFilterNameProvider), 'Chợ');
  });

  // The whole point of the one-unlock-layer rule: a lens, or a filter, or a
  // view of any kind, changes what you see and never what you have.
  test('filtering a place out does not take away the visit', () async {
    final container = _container(
      visits: {
        'c-park': VisitState(
          checkpointId: 'c-park',
          status: VisitStatus.visited,
          visitedAt: DateTime.utc(2026),
          verifiedBy: VerifyMethod.gps,
        ),
      },
    );
    await _settle(container);

    container.read(mapFilterProvider.notifier).show('markets');

    expect(
      container.read(visibleCheckpointsProvider).map((c) => c.id),
      isNot(contains('c-park')),
      reason: 'the park is filtered off the map',
    );
    expect(
      container.read(visitedCheckpointIdsProvider),
      contains('c-park'),
      reason: 'and is still a place the player has been',
    );
    expect(
      container
          .read(stampsProvider)
          .where((s) => s.isOwned)
          .map((s) => s.checkpointId),
      contains('c-park'),
      reason: 'its stamp stays in the album',
    );
    expect(
      container.read(fogHolesProvider),
      hasLength(1),
      reason: 'and its fog stays cleared',
    );
  });

  test('clearing the filter brings everything back', () async {
    final container = _container();
    await _settle(container);

    container.read(mapFilterProvider.notifier).show('parks');
    expect(container.read(visibleCheckpointsProvider), hasLength(1));

    container.read(mapFilterProvider.notifier).clear();
    expect(container.read(visibleCheckpointsProvider), hasLength(3));
  });

  // Content can lose a quest between releases. An empty map would read as a
  // broken app rather than as a filter pointing at nothing.
  test(
    'a filter naming a quest that no longer exists shows everything',
    () async {
      final container = _container();
      await _settle(container);

      container.read(mapFilterProvider.notifier).show('a-quest-that-went-away');

      expect(container.read(visibleCheckpointsProvider), hasLength(3));
    },
  );
}
