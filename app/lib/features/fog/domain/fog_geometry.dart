import 'dart:math' as math;

import 'package:wanderlock/features/fog/domain/fog_hole.dart';

/// Builds the fog as one polygon with holes punched in it.
///
/// The alternative — recomputing screen positions in Dart on every camera
/// frame — was rejected before it was written. This produces GeoJSON handed to
/// MapLibre once; the GPU then pans, zooms and redraws it with the rest of the
/// map. Frames cost nothing, which is the whole point when F5's DoD is two
/// hours of walking without dropping frames.
///
/// GeoJSON says the first linear ring of a polygon is its outside and every
/// ring after it is a hole. That single rule is what makes "the world, minus
/// where you have been" expressible as one feature.
class FogGeometry {
  const FogGeometry._();

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
  static const double minimumRevealMeters = 260;

  /// Metres per degree of latitude. Constant enough at pilot scale; the pilot
  /// spans about 25 km and the error over that distance is centimetres.
  static const double metresPerDegreeLatitude = 111320;

  /// Vertices used to approximate a circle.
  ///
  /// 48 is smooth to the eye at the zoom levels a walker uses, and keeps the
  /// whole twelve-hole document small enough to hand over without a stutter.
  static const int circleVertices = 48;

  /// The reveal radius for a checkpoint whose check-in radius is [radiusMeters].
  static double revealRadiusMeters(int radiusMeters) =>
      math.max(radiusMeters * revealMultiplier, minimumRevealMeters);

  /// A GeoJSON `FeatureCollection` holding the veil.
  ///
  /// Always one feature, even with no holes: an empty collection would make
  /// the layer vanish, and a fog lens that disappears when you have visited
  /// nothing is exactly backwards.
  static Map<String, Object?> veil(List<FogHole> holes) {
    final rings = <List<List<double>>>[
      _worldRing(),
      for (final hole in holes) _circleRing(hole),
    ];

    return <String, Object?>{
      'type': 'FeatureCollection',
      'features': <Object?>[
        <String, Object?>{
          'type': 'Feature',
          'properties': <String, Object?>{},
          'geometry': <String, Object?>{
            'type': 'Polygon',
            'coordinates': rings,
          },
        },
      ],
    };
  }

  /// A GeoJSON `FeatureCollection` of the cleared areas, as filled circles.
  ///
  /// The inverse of [veil], and needed because the two themes clear fog by
  /// opposite means: light lifts a cream veil, dark lights the ground up. See
  /// [AppMapColors.fogCleared].
  static Map<String, Object?> clearedAreas(List<FogHole> holes) {
    return <String, Object?>{
      'type': 'FeatureCollection',
      'features': <Object?>[
        for (final hole in holes)
          <String, Object?>{
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': <String, Object?>{
              'type': 'Polygon',
              'coordinates': <Object?>[_circleRing(hole)],
            },
          },
      ],
    };
  }

  /// A GeoJSON `FeatureCollection` of just the cleared rims, as closed lines.
  ///
  /// Drawn as its own layer rather than as a stroke on the veil: a polygon
  /// stroke would also outline the world rectangle, drawing a line across the
  /// Pacific.
  static Map<String, Object?> clearedEdges(List<FogHole> holes) {
    return <String, Object?>{
      'type': 'FeatureCollection',
      'features': <Object?>[
        for (final hole in holes)
          <String, Object?>{
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': <String, Object?>{
              'type': 'LineString',
              'coordinates': _circleRing(hole),
            },
          },
      ],
    };
  }

  /// The outer ring: the whole world, so panning never runs off the fog.
  ///
  /// Latitude stops at ±85 because Web Mercator cannot express the poles.
  static List<List<double>> _worldRing() => <List<double>>[
    <double>[-180, -85],
    <double>[180, -85],
    <double>[180, 85],
    <double>[-180, 85],
    <double>[-180, -85],
  ];

  /// A circle of [FogHole.revealRadiusMeters] around a hole, in longitude and
  /// latitude pairs, closed by repeating the first point.
  ///
  /// A degree of longitude shrinks towards the poles, so the radius is divided
  /// by the cosine of the latitude. Skipping that is what turns a circle into
  /// an ellipse: at the pilot's latitude of about 10.8° the error is only 1.8%,
  /// small enough to look almost right and therefore easy to ship by accident.
  static List<List<double>> _circleRing(FogHole hole) {
    final latitudeRadians = hole.latitude * math.pi / 180;
    final deltaLatitude = hole.revealRadiusMeters / metresPerDegreeLatitude;
    final deltaLongitude =
        deltaLatitude / math.max(math.cos(latitudeRadians), 0.000001);

    final ring = <List<double>>[];
    for (var i = 0; i < circleVertices; i++) {
      final angle = 2 * math.pi * i / circleVertices;
      ring.add(<double>[
        hole.longitude + deltaLongitude * math.cos(angle),
        hole.latitude + deltaLatitude * math.sin(angle),
      ]);
    }
    ring.add(ring.first);
    return ring;
  }
}
