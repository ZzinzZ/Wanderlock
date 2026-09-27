import 'dart:math' as math;

/// Where a coordinate lands on screen, given the camera.
///
/// Web Mercator, the projection MapLibre draws in, worked out in Dart so the
/// app can position widgets over the map without asking the platform. The
/// alternative — `controller.toScreenLocation` — is an async call across the
/// platform channel *per point*, which is twelve round trips for every frame
/// of a pan.
///
/// Pure numbers, no Flutter types: the architecture gate keeps `domain/` on
/// plain Dart, and a projection is arithmetic rather than drawing.
///
/// One instance is built per frame and then asked about hundreds of points —
/// every checkpoint, every trail point — so the two quantities that depend
/// only on the camera are worked out once per instance rather than once per
/// point. Deliberately not `const`: that is what buys the caching.
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

  /// MapLibre's vector tiles are 512 px square. Using 256 — the raster
  /// convention, and the number most Mercator snippets on the web assume —
  /// puts every marker at half the right distance from the centre, which looks
  /// plausible near the middle of the screen and wrong at the edges.
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

  /// Whether a marker at this position is worth building.
  ///
  /// [margin] keeps a marker alive slightly off screen, so one does not pop
  /// into existence at the moment its centre crosses the edge — its artwork is
  /// wider than its centre point.
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

  /// A value, so a painter can ask "is this the same camera?" in one line.
  ///
  /// Every overlay's `shouldRepaint` used to compare the five fields by hand,
  /// which meant a new field on this class silently stopped being a reason to
  /// repaint in every painter that had not been updated.
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
