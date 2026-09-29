import 'dart:math' as math;

/// How much map one arrival clears — a product decision, and all that is
/// left here since the fog moved to a Flutter canvas. See `fog_overlay.dart`.
class FogReveal {
  const FogReveal._();

  /// How much one arrival opens up, as a multiple of the check-in radius. Fog
  /// is about the neighbourhood you have seen, not the doorway you stood in,
  /// and a 40–80 m hole reads as a pinprick at city zoom.
  static const double revealMultiplier = 4;

  /// Floor for [revealMultiplier], in metres, so a temple gate and a plaza do
  /// not open wildly different amounts of city.
  ///
  /// **Must stay well clear of the marker’s own width.** The marker is a
  /// fixed 141 logical pixels; a hole scales with zoom, and at the opening
  /// zoom the earlier 260 m came to 139 pixels — every clearing hid under
  /// its own pin. 900 m is about three and a half marker widths.
  static const double minimumRevealMeters = 900;

  /// The reveal radius for a checkpoint whose check-in radius is [radiusMeters].
  static double radiusMeters(int radiusMeters) =>
      math.max(radiusMeters * revealMultiplier, minimumRevealMeters);
}
