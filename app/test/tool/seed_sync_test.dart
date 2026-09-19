// Covers the two decisions in tool/seed_content.dart that can destroy data.
//
// The seed script upserts, so adding and editing a place has always been safe.
// Removing one was not expressible at all until `--prune`, and a prune deletes
// a checkpoint row, which cascades into visit_state. That makes these two pure
// functions the last thing standing between a content edit and the permanent
// loss of somebody's unlock history — worth testing without a database in the
// way.
//
// The script lives outside lib/ on purpose: it is a developer tool that runs
// with the service role key and never ships inside the app.
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/seed_content.dart';

void main() {
  group('planSync', () {
    test('a place the server holds and the file dropped is an orphan', () {
      final plan = planSync(
        ['ben-thanh-market', 'thien-hau-temple'],
        ['ben-thanh-market', 'thien-hau-temple', 'landmark-81'],
      );

      expect(plan.orphans, ['landmark-81']);
      expect(plan.isClean, isFalse);
    });

    test('a place the file adds is not an orphan — the upsert creates it', () {
      final plan = planSync(
        ['ben-thanh-market', 'giac-lam-pagoda'],
        ['ben-thanh-market'],
      );

      expect(plan.orphans, isEmpty);
      expect(plan.isClean, isTrue);
      expect(plan.upsert, ['ben-thanh-market', 'giac-lam-pagoda']);
    });

    test('matching lists leave nothing to prune', () {
      final plan = planSync(['a', 'b'], ['b', 'a']);

      expect(plan.orphans, isEmpty);
      expect(plan.isClean, isTrue);
    });

    test('an empty server is clean rather than a full delete', () {
      expect(planSync(['a', 'b'], const []).orphans, isEmpty);
    });

    // An empty content file means every place on the server is orphaned. The
    // script must still say so plainly rather than treat "nothing authored" as
    // "nothing to do" — the guard against acting on it is --prune, not this.
    test('an empty file orphans everything the server holds', () {
      expect(planSync(const [], ['a', 'b']).orphans, ['a', 'b']);
    });

    test('orphans come back sorted, so the report is stable', () {
      expect(planSync(const [], ['c', 'a', 'b']).orphans, ['a', 'b', 'c']);
    });
  });

  group('orphansWithVisits', () {
    test('a checkpoint nobody visited may be pruned', () {
      expect(orphansWithVisits({'landmark-81': 0}), isEmpty);
    });

    test('a checkpoint somebody visited blocks the prune', () {
      expect(orphansWithVisits({'landmark-81': 1}), ['landmark-81']);
    });

    test('only the visited ones block, not their untouched neighbours', () {
      expect(orphansWithVisits({'a': 0, 'b': 3, 'c': 0, 'd': 12}), ['b', 'd']);
    });

    test('nothing to check blocks nothing', () {
      expect(orphansWithVisits(const {}), isEmpty);
    });
  });
}
