import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';
import 'package:wanderlock/features/quest/domain/quest_route.dart';
import 'package:wanderlock/features/quest/domain/quest_step.dart';

QuestStep _step(String id, {required bool isDone}) =>
    QuestStep(checkpointId: id, name: id, isDone: isDone);

QuestRoute _route(List<QuestStep> steps) =>
    QuestRoute(id: 'r', name: 'Tuyến thử', summary: '', steps: steps);

void main() {
  group('progress is derived, never stored', () {
    test('counts only the steps visit_state calls done', () {
      final route = _route([
        _step('a', isDone: true),
        _step('b', isDone: false),
        _step('c', isDone: true),
      ]);

      expect(route.doneCount, 2);
      expect(route.totalCount, 3);
      expect(route.progress, closeTo(2 / 3, 0.0001));
      expect(route.isComplete, isFalse);
    });

    test('is complete only when every step is done', () {
      expect(_route([_step('a', isDone: true)]).isComplete, isTrue);
      expect(_route([_step('a', isDone: false)]).isComplete, isFalse);
    });

    test('an empty route is not complete, and does not divide by zero', () {
      final route = _route(const []);

      expect(route.progress, 0);
      expect(route.isComplete, isFalse);
      expect(route.nextStep, isNull);
    });
  });

  group('nextStep', () {
    test('is the first step still missing', () {
      final route = _route([
        _step('a', isDone: true),
        _step('b', isDone: false),
        _step('c', isDone: false),
      ]);

      expect(route.nextStep?.checkpointId, 'b');
    });

    test('points at a gap left behind, not at the step after the last done '
        'one', () {
      // Someone who reached stop three before stop two really has been to
      // stop three — the unlock layer recorded it. The route must ask for
      // what is still missing rather than pretend the visit did not happen.
      final route = _route([
        _step('a', isDone: true),
        _step('b', isDone: false),
        _step('c', isDone: true),
      ]);

      expect(route.nextStep?.checkpointId, 'b');
    });

    test('is null once the route is finished', () {
      final route = _route([
        _step('a', isDone: true),
        _step('b', isDone: true),
      ]);

      expect(route.nextStep, isNull);
    });
  });

  group('parsing authored routes', () {
    test('reads a route in the order it was written', () {
      const raw = '''
      {"routes": [
        {"id": "r1", "name": "Lõi Sài Gòn xưa", "summary": "Đủ dấu: ế ỡ ộ ữ ẫ",
         "steps": [{"checkpointId": "b"}, {"checkpointId": "a"}]}
      ]}''';

      final routes = QuestRouteBundledSource.parse(raw);

      expect(routes, hasLength(1));
      expect(routes.single.name, 'Lõi Sài Gòn xưa');
      expect(routes.single.summary, 'Đủ dấu: ế ỡ ộ ữ ẫ');
      expect(routes.single.checkpointIds, ['b', 'a']);
    });

    test('drops a route with no usable steps rather than showing 0/0', () {
      const raw = '''
      {"routes": [
        {"id": "empty", "name": "Rỗng", "summary": "", "steps": []},
        {"id": "blank", "name": "Id trống", "summary": "",
         "steps": [{"checkpointId": ""}]},
        {"id": "ok", "name": "Được", "summary": "",
         "steps": [{"checkpointId": "a"}]}
      ]}''';

      final routes = QuestRouteBundledSource.parse(raw);

      expect(routes.map((r) => r.id), ['ok']);
    });

    test('a file with no routes is empty, not an error', () {
      expect(QuestRouteBundledSource.parse('{"routes": []}'), isEmpty);
      expect(QuestRouteBundledSource.parse('{}'), isEmpty);
    });
  });

  group('the bundled copy of the authored routes', () {
    final root = File('pubspec.yaml').absolute.parent.parent;
    final authored = File('${root.path}/content/quest-routes.json');
    final bundled = File('assets/content/quest-routes.json');

    test('is byte-for-byte the authored file', () {
      expect(
        authored.existsSync(),
        isTrue,
        reason: 'expected ${authored.path} to exist',
      );
      expect(bundled.existsSync(), isTrue);
      expect(
        bundled.readAsBytesSync(),
        authored.readAsBytesSync(),
        reason:
            'assets/content/quest-routes.json has drifted from '
            'content/quest-routes.json — copy the root file over it',
      );
    });

    test('every step names a checkpoint that exists', () {
      // A typo here costs a silently missing stop, because the composition
      // layer drops what it cannot resolve. Cheap to catch, invisible if not.
      final checkpoints = File(
        '${root.path}/content/checkpoints.json',
      ).readAsStringSync();
      final routes = QuestRouteBundledSource.parse(bundled.readAsStringSync());

      for (final route in routes) {
        for (final id in route.checkpointIds) {
          expect(
            checkpoints.contains('"$id"'),
            isTrue,
            reason:
                'route "${route.id}" names checkpoint "$id", which is not in '
                'content/checkpoints.json',
          );
        }
      }
    });

    test('ships exactly one route, as scope v1 specifies', () {
      expect(
        QuestRouteBundledSource.parse(bundled.readAsStringSync()),
        hasLength(1),
      );
    });
  });
}
