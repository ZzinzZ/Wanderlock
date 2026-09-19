/// A route as it is authored, before it knows anything about the user.
///
/// Deliberately separate from [QuestRoute]: this is the content — an ordered
/// list of checkpoint ids — while [QuestRoute] is that content joined to
/// `visit_state`. Keeping them apart is what lets the quest feature parse and
/// test its own content without importing `checkpoint` or `unlock`, which the
/// dependency rule forbids.
/// How a quest is played.
enum QuestKind {
  /// Stops in an authored order, with one "next stop" at a time.
  route,

  /// A collection to complete in any order — every market, every park.
  set;

  /// Anything unknown reads as a route: that is what every quest was before
  /// sets existed, so an older file means what it always meant.
  static QuestKind parse(String? value) =>
      value == 'set' ? QuestKind.set : QuestKind.route;
}

class QuestRouteDefinition {
  const QuestRouteDefinition({
    required this.id,
    required this.name,
    required this.summary,
    required this.checkpointIds,
    this.kind = QuestKind.route,
    this.categories = const [],
  });

  final QuestKind kind;

  /// Checkpoint categories whose every place belongs to this quest, by name.
  ///
  /// Lets a set be "all the markets" rather than a hand-kept list of sixty
  /// ids: a market added to the content file joins the set with no edit here.
  /// Resolved against the content where the quest is assembled — this layer
  /// cannot see checkpoints.
  final List<String> categories;

  final String id;
  final String name;
  final String summary;

  /// In authored order. Ids that match no checkpoint are dropped when the
  /// route is assembled, not here — this layer reports what was written.
  final List<String> checkpointIds;

  @override
  String toString() =>
      'QuestRouteDefinition($id, ${kind.name}, ${checkpointIds.length})';
}
