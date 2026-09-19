import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';
import 'package:wanderlock/features/unlock/application/visit_state_providers.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// Quests as collections: a set named by category gathers every place of that
/// kind, is played in any order, and completes from `visit_state` like any
/// other lens.
void main() {
  Checkpoint place(String id, CheckpointCategory category) => Checkpoint(
    id: id,
    name: id,
    latitude: 10.77,
    longitude: 106.69,
    radiusMeters: 60,
    category: category,
  );

  final checkpoints = [
    place('cho-tan-dinh', CheckpointCategory.market),
    place('cho-ben-thanh', CheckpointCategory.market),
    place('tao-dan', CheckpointCategory.park),
    place('dinh-doc-lap', CheckpointCategory.monument),
  ];

  const json = '''
{"routes": [
  {"id": "markets", "kind": "set", "name": "Chợ", "categories": ["market"]},
  {"id": "mixed", "kind": "set", "name": "Trộn", "categories": ["park"],
   "steps": [{"checkpointId": "dinh-doc-lap"}]},
  {"id": "empty", "kind": "set", "name": "Rỗng", "categories": ["food"]},
  {"id": "walk", "name": "Tuyến", "steps": [
    {"checkpointId": "cho-ben-thanh"}, {"checkpointId": "tao-dan"}]}
]}''';

  ProviderContainer containerWith(Set<String> visited) => ProviderContainer(
    overrides: [
      checkpointsProvider.overrideWith((ref) => Stream.value(checkpoints)),
      visitStateProvider.overrideWith(
        (ref) => Stream.value({
          for (final id in visited)
            id: VisitState(
              checkpointId: id,
              status: VisitStatus.visited,
              visitedAt: DateTime.utc(2026, 9, 19),
              verifiedBy: VerifyMethod.gps,
            ),
        }),
      ),
      questRouteDefinitionsProvider.overrideWith(
        (ref) async => QuestRouteBundledSource.parse(json),
      ),
    ],
  );

  Future<List<String>> idsOf(ProviderContainer container, String quest) async {
    // Listened to, not just read: an unwatched stream provider is disposed
    // before it emits, and the read never completes.
    container.listen(checkpointsProvider, (_, _) {});
    container.listen(visitStateProvider, (_, _) {});
    await container.read(questRouteDefinitionsProvider.future);
    await Future<void>.delayed(Duration.zero);
    return container
        .read(questRoutesProvider)
        .singleWhere((route) => route.id == quest)
        .steps
        .map((step) => step.checkpointId)
        .toList();
  }

  test('a set named by category gathers every place of that kind', () async {
    final container = containerWith({});
    addTearDown(container.dispose);
    expect(await idsOf(container, 'markets'), [
      'cho-tan-dinh',
      'cho-ben-thanh',
    ]);
  });

  test('listed ids come first, then the category', () async {
    final container = containerWith({});
    addTearDown(container.dispose);
    expect(await idsOf(container, 'mixed'), ['dinh-doc-lap', 'tao-dan']);
  });

  test('a set with nothing in it is not shown', () async {
    final container = containerWith({});
    addTearDown(container.dispose);
    await idsOf(container, 'markets');
    expect(
      container.read(questRoutesProvider).map((route) => route.id),
      isNot(contains('empty')),
    );
  });

  test('a set has no "next stop"; a route does', () async {
    final container = containerWith({});
    addTearDown(container.dispose);
    await idsOf(container, 'markets');
    final routes = container.read(questRoutesProvider);
    expect(routes.singleWhere((r) => r.id == 'markets').nextStep, isNull);
    expect(
      routes.singleWhere((r) => r.id == 'walk').nextStep?.checkpointId,
      'cho-ben-thanh',
    );
  });

  test('one visit counts in every quest that holds the place', () async {
    final container = containerWith({'cho-ben-thanh'});
    addTearDown(container.dispose);
    await idsOf(container, 'markets');
    final routes = container.read(questRoutesProvider);
    expect(routes.singleWhere((r) => r.id == 'markets').doneCount, 1);
    expect(routes.singleWhere((r) => r.id == 'walk').doneCount, 1);
  });
}
