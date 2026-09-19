/// One collectable place in the album.
///
/// A stamp is **not stored anywhere**. It is a view of a checkpoint through
/// `visit_state`, assembled on demand by the composition layer, and that is
/// deliberate: the moment the collection kept its own list of what is owned,
/// there would be two answers to "has this person been here" and they would
/// eventually disagree.
///
/// Like [FogHole] in the fog lens, it is built from plain values rather than
/// from a `Checkpoint`, because a lens may not import another feature.
class Stamp {
  const Stamp({
    required this.checkpointId,
    required this.name,
    required this.isOwned,
    this.photoUrl,
  });

  final String checkpointId;
  final String name;

  /// True when `visit_state` says this checkpoint is visited. Derived, never
  /// written.
  final bool isOwned;

  /// The landmark photograph, once one has cleared licensing. Null until then,
  /// and the tile draws its own placeholder rather than borrowing an
  /// illustration — the art direction is explicit that a landmark is a real
  /// photograph or nothing.
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stamp &&
          other.checkpointId == checkpointId &&
          other.name == name &&
          other.isOwned == isOwned &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(checkpointId, name, isOwned, photoUrl);

  @override
  String toString() => 'Stamp($checkpointId, owned: $isOwned)';
}
