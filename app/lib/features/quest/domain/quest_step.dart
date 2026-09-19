/// One stop on a route.
///
/// Like [Stamp] in the collection lens and [FogHole] in the fog lens, a step
/// is built from plain values rather than from a `Checkpoint`: a lens may not
/// import another feature, so the composition layer hands it the name and the
/// visited flag it needs and keeps the entity to itself.
///
/// [isDone] is **derived from `visit_state`, never stored**. A quest that kept
/// its own record of which steps were finished would be a second answer to
/// "has this person been here", and the two would drift apart the first time a
/// check-in synced from another device.
class QuestStep {
  const QuestStep({
    required this.checkpointId,
    required this.name,
    required this.isDone,
  });

  final String checkpointId;
  final String name;

  /// True when `visit_state` says the checkpoint behind this step is visited.
  final bool isDone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestStep &&
          other.checkpointId == checkpointId &&
          other.name == name &&
          other.isDone == isDone;

  @override
  int get hashCode => Object.hash(checkpointId, name, isDone);

  @override
  String toString() => 'QuestStep($checkpointId, done: $isDone)';
}
