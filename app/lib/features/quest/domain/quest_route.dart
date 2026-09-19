import 'package:wanderlock/features/quest/domain/quest_route_definition.dart';
import 'package:wanderlock/features/quest/domain/quest_step.dart';

/// A curated sequence of places, and the progress through it.
///
/// Scope v1 ships exactly one route. The type is a list-of-steps rather than a
/// single hard-coded chain so that adding the second one is a content edit,
/// not a code change — see `content/quest-routes.json`.
///
/// **Nothing here is persisted.** Every field below is computed from the steps
/// handed in, and those carry a visited flag that came from `visit_state`.
/// That is the whole reason the quest lens costs so little: it is a reading of
/// data the unlock layer already owns.
class QuestRoute {
  const QuestRoute({
    required this.id,
    required this.name,
    required this.summary,
    required this.steps,
    this.kind = QuestKind.route,
  });

  final String id;
  final String name;
  final String summary;
  final List<QuestStep> steps;

  final QuestKind kind;

  bool get isSet => kind == QuestKind.set;

  /// How many stops have been reached.
  int get doneCount => steps.where((step) => step.isDone).length;

  int get totalCount => steps.length;

  bool get isComplete => totalCount > 0 && doneCount == totalCount;

  /// The step the user is being asked for next.
  ///
  /// The **first** unfinished step, not the first one after the last finished
  /// one: a route is an order suggested to the user, not an order imposed on
  /// them. Someone who happens to pass stop four before stop two has genuinely
  /// been to stop four, and the unlock layer has already recorded it — so the
  /// route points at what is still missing rather than pretending the visit
  /// did not happen.
  ///
  /// Null once every stop is done, and always null for a set: a collection
  /// has no order, so it has no "next".
  QuestStep? get nextStep {
    if (isSet) return null;
    for (final step in steps) {
      if (!step.isDone) return step;
    }
    return null;
  }

  /// Completion as 0..1, for the progress bar. Zero steps reads as zero rather
  /// than as a division by zero.
  double get progress => totalCount == 0 ? 0 : doneCount / totalCount;

  @override
  String toString() => 'QuestRoute($id, $doneCount/$totalCount)';
}
