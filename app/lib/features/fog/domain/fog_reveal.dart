import 'dart:math' as math;

/// How much map one arrival clears.
///
/// This used to build the fog as a GeoJSON polygon with holes, handed to
/// MapLibre once so the GPU could pan and zoom it for free. That approach was
/// abandoned on 2026-09-19: a GL fill cannot be blurred, and a hard-edged hole
/// reads as a cut rather than as fog lifting. The fog is now painted in Flutter
/// in screen space — see `fog_overlay.dart`, which records the alternatives
/// tried and why each was dropped.
///
/// What survived the change is the only part that was never about rendering:
/// the size of a reveal, which is a product decision.
class FogReveal {
  const FogReveal._();

  /// How much map one arrival opens up, as a multiple of the check-in radius.
  ///
  /// Fog is about the neighbourhood you have seen, not the doorway you stood
  /// in. A check-in radius is 40–80 m — a hole that small reads as a pinprick
  /// at city zoom and the map never visibly opens.
  static const double revealMultiplier = 4;

  /// Floor for [revealMultiplier], in metres.
  ///
  /// A tight temple gate and a wide plaza should not open wildly different
  /// amounts of city just because their check-in radii differ by 40 m.
  ///
  /// **Raised from 260 m on 2026-09-08, because 260 m was invisible.** The
  /// checkpoint marker is a fixed 141 logical pixels wide, while the hole
  /// scales with zoom — and at the zoom the map opens on, 260 m came to 139
  /// pixels across. Every arrival opened a circle slightly smaller than the
  /// pin sitting on top of it, so the fog looked like it had never cleared at
  /// all. Nothing was wrong with the geometry or the rendering; the hole was
  /// simply hidden underneath its own marker.
  ///
  /// 900 m is about three and a half marker widths at that zoom, which reads
  /// as a neighbourhood opening rather than as a hole around a pin — and
  /// matches what [revealMultiplier] is already reaching for.
  static const double minimumRevealMeters = 900;

  /// The reveal radius for a checkpoint whose check-in radius is [radiusMeters].
  static double radiusMeters(int radiusMeters) =>
      math.max(radiusMeters * revealMultiplier, minimumRevealMeters);
}
