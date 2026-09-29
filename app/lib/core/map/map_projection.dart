import 'dart:math' as math;

/// Where a coordinate lands on screen, given the camera.
///
/// Web Mercator worked out in Dart, because the alternative —
/// `controller.toScreenLocation` — is an async platform call *per point*.
///
/// Pure numbers, no Flutter types. [CameraProjection] is the adapter that
/// builds one from a MapLibre camera.
///
/// One instance per frame is then asked about hundreds of points, so the two
/// quantities that depend only on the camera are cached. Deliberately not
/// `const`: that is what buys the caching.
class MapProjection {
  MapProjection({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.zoom,
    required this.widthPixels,
    required this.heightPixels,
  });

  final double centerLatitude;
  final double centerLongitude;
  final double zoom;
  final double widthPixels;
  final double heightPixels;

  /// MapLibre's vector tiles are 512 px square. The raster convention of 256,
  /// which most Mercator snippets assume, puts every marker at half the right
  /// distance from the centre — plausible in the middle, wrong at the edges.
  static const double tileSize = 512;

  /// Latitude beyond which Mercator stops being finite.
  static const double maxLatitude = 85.05112878;

  /// Earth's equatorial circumference in metres, as Web Mercator uses it.
  static const double earthCircumferenceMeters = 40075016.686;

  late final double _worldPixels = tileSize * math.pow(2, zoom).toDouble();

  late final ({double x, double y}) _centre = _project(
    centerLatitude,
    centerLongitude,
    _worldPixels,
  );

  /// Screen position of [latitude], [longitude], in logical pixels from the
  /// top-left of the map.
  ({double x, double y}) toScreen(double latitude, double longitude) {
    final point = _project(latitude, longitude, _worldPixels);

    return (
      x: point.x - _centre.x + widthPixels / 2,
      y: point.y - _centre.y + heightPixels / 2,
    );
  }

  /// How many metres one screen pixel covers at [latitude].
  ///
  /// For anything sized in metres on the ground — a reveal radius — rather
  /// than in pixels on the screen.
  double metersPerPixel(double latitude) =>
      earthCircumferenceMeters *
      math.cos(latitude * math.pi / 180) /
      _worldPixels;

  /// Whether a marker at this position is worth building. [margin] keeps one
  /// alive slightly off screen, since its artwork is wider than its centre.
  bool isVisible(({double x, double y}) screen, {double margin = 64}) =>
      screen.x >= -margin &&
      screen.x <= widthPixels + margin &&
      screen.y >= -margin &&
      screen.y <= heightPixels + margin;

  static ({double x, double y}) _project(
    double latitude,
    double longitude,
    double worldPixels,
  ) {
    final clamped = latitude.clamp(-maxLatitude, maxLatitude);
    final sin = math.sin(clamped * math.pi / 180);

    return (
      x: (longitude + 180) / 360 * worldPixels,
      // The standard Mercator y, written with sin rather than tan because the
      // tan form blows up at the poles and this one degrades gracefully.
      y: (0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi)) * worldPixels,
    );
  }

  /// A value, so a painter's `shouldRepaint` can ask "same camera?" in one
  /// line instead of comparing five fields it will forget to update.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapProjection &&
          other.centerLatitude == centerLatitude &&
          other.centerLongitude == centerLongitude &&
          other.zoom == zoom &&
          other.widthPixels == widthPixels &&
          other.heightPixels == heightPixels;

  @override
  int get hashCode => Object.hash(
    centerLatitude,
    centerLongitude,
    zoom,
    widthPixels,
    heightPixels,
  );
}
