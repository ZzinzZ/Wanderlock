import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// Which places the map is currently drawing.
///
/// The pilot grew from twelve landmarks to 272, and at city zoom that is a
/// screen of dots with no shape to it — the owner's words: rối mắt. Section
/// 5.4 of the scope already answered this for the quest lens ("chỉ nổi bật
/// các điểm thuộc tuyến"), and the answer generalises: show one quest's places
/// at a time.
///
/// It costs nothing to define the groups, because the ten quest *sets* are
/// already groupings by kind of place — markets, parks, museums, places to
/// eat. Filtering by quest and filtering by category are the same act here.
///
/// **This is presentation only.** A filtered-out place is still unlocked, its
/// fog hole still cleared, its stamp still in the album. Nothing here reads or
/// writes `visit_state`, and a test pins that: hiding a pin must never look
/// like losing a visit.
class MapFilter extends Notifier<String?> {
  @override
  String? build() => null;

  /// Null shows every place.
  void show(String? questId) => state = questId;

  void clear() => state = null;
}

final mapFilterProvider = NotifierProvider<MapFilter, String?>(MapFilter.new);

/// The checkpoints the map should draw, after the filter.
///
/// Falls back to everything when the filter names a quest that no longer
/// exists — content can lose a quest between releases, and an empty map would
/// read as a broken app rather than as a stale filter.
final visibleCheckpointsProvider = Provider<List<Checkpoint>>((ref) {
  final all = ref.watch(checkpointsProvider).value ?? const <Checkpoint>[];
  final questId = ref.watch(mapFilterProvider);
  if (questId == null) return all;

  final route = ref
      .watch(questRoutesProvider)
      .where((route) => route.id == questId)
      .firstOrNull;
  if (route == null) return all;

  final ids = {for (final step in route.steps) step.checkpointId};
  return [
    for (final checkpoint in all)
      if (ids.contains(checkpoint.id)) checkpoint,
  ];
});

/// The name of the active filter, for the button that opens the sheet.
final activeFilterNameProvider = Provider<String?>((ref) {
  final questId = ref.watch(mapFilterProvider);
  if (questId == null) return null;
  return ref
      .watch(questRoutesProvider)
      .where((route) => route.id == questId)
      .firstOrNull
      ?.name;
});

/// How many places exist in total, for the "all" row of the filter sheet.
final allCheckpointCountProvider = Provider<int>(
  (ref) =>
      (ref.watch(checkpointsProvider).value ?? const <Checkpoint>[]).length,
);
