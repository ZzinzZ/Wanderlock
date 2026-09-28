/// Stores the user's own ordering of places.
///
/// Deals in ids and positions only — no names, no coordinates, no visit flags.
/// Everything else about a place already has an owner, and copying any of it
/// here would be a second copy to keep in step. The composition layer joins
/// these ids back to checkpoints when it builds the list for the screen.
///
/// Local only in v1. The itinerary is a plan for an afternoon, not a record of
/// anything earned, so losing it with the app is a smaller cost than a sync
/// path that could conflict with `visit_state` in the same table. F9 can lift
/// it to the server later without any caller noticing — that is what this
/// interface is for.
abstract interface class ItineraryRepository {
  /// Checkpoint ids in the user's order. Empty until they add something.
  Future<List<String>> readOrder();

  /// Emits the order on every change, so the screen never has to re-read.
  Stream<List<String>> watchOrder();

  /// Appends to the end. Adding a place already on the plan does nothing
  /// rather than adding a duplicate: two entries for one place would each want
  /// their own tick, and one arrival can only cross off one of them.
  Future<void> add(String checkpointId);

  Future<void> remove(String checkpointId);

  /// Writes a whole new order.
  ///
  /// Positions are rewritten from zero to length-1 on every call rather than
  /// nudged. A drag that only moved one row still renumbers all of them, which
  /// is more writes and far fewer ways to end up with two rows claiming the
  /// same position after an interrupted edit.
  Future<void> reorder(List<String> checkpointIds);

  /// Empties the plan. Offered because a plan for last Saturday is worse than
  /// no plan, and removing eight rows one at a time is how a user learns to
  /// leave the stale one there.
  Future<void> clear();
}
