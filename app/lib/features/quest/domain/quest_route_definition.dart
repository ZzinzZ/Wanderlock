/// A route as it is authored, before it knows anything about the user.
///
/// Deliberately separate from [QuestRoute]: this is the content — an ordered
/// list of checkpoint ids — while [QuestRoute] is that content joined to
/// `visit_state`. Keeping them apart is what lets the quest feature parse and
/// test its own content without importing `checkpoint` or `unlock`, which the
/// dependency rule forbids.
class QuestRouteDefinition {
  const QuestRouteDefinition({
    required this.id,
    required this.name,
    required this.summary,
    required this.checkpointIds,
  });

  final String id;
  final String name;
  final String summary;

  /// In authored order. Ids that match no checkpoint are dropped when the
  /// route is assembled, not here — this layer reports what was written.
  final List<String> checkpointIds;

  @override
  String toString() => 'QuestRouteDefinition($id, ${checkpointIds.length})';
}
