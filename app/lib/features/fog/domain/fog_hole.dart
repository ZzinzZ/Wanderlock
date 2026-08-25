/// A place in the fog that has been cleared.
///
/// Deliberately not a `Checkpoint`. The fog lens must not know what a
/// checkpoint is — lenses share state through `unlock` and never through each
/// other — so the composition layer hands fog the only three numbers it needs.
/// The same type serves a walked trail later, which has no checkpoint at all.
class FogHole {
  const FogHole({
    required this.latitude,
    required this.longitude,
    required this.revealRadiusMeters,
  });

  final double latitude;
  final double longitude;

  /// How much map this arrival opened up.
  final double revealRadiusMeters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FogHole &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.revealRadiusMeters == revealRadiusMeters;

  @override
  int get hashCode => Object.hash(latitude, longitude, revealRadiusMeters);

  @override
  String toString() => 'FogHole($latitude, $longitude, $revealRadiusMeters m)';
}
