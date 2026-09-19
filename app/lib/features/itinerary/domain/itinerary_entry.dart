/// One place the user put on their own plan, at the position they put it.
///
/// Built from plain values, like every other lens entity, so `itinerary` never
/// imports `checkpoint`.
///
/// The distinction that matters: [isVisited] is read from `visit_state` and is
/// **not ours to write**, while [position] is the user's own arrangement and
/// **is** ours to store. An itinerary is the one lens that keeps state of its
/// own — but it is a preference about what to do next, never a record of what
/// has been done. Rule 1 of the project only forbids a second record of the
/// latter.
class ItineraryEntry {
  const ItineraryEntry({
    required this.checkpointId,
    required this.name,
    required this.position,
    required this.isVisited,
  });

  final String checkpointId;
  final String name;

  /// Zero-based rank in the user's plan. Contiguous after every edit — see
  /// [ItineraryRepository.reorder] for why gaps are not tolerated.
  final int position;

  /// From `visit_state`. A visited stop stays on the plan rather than
  /// vanishing: crossing something off is the reward, and a list that empties
  /// itself as you go leaves nothing to show for the walk.
  final bool isVisited;

  ItineraryEntry copyWith({int? position, bool? isVisited}) => ItineraryEntry(
    checkpointId: checkpointId,
    name: name,
    position: position ?? this.position,
    isVisited: isVisited ?? this.isVisited,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryEntry &&
          other.checkpointId == checkpointId &&
          other.name == name &&
          other.position == position &&
          other.isVisited == isVisited;

  @override
  int get hashCode => Object.hash(checkpointId, name, position, isVisited);

  @override
  String toString() => 'ItineraryEntry($checkpointId, at $position)';
}
