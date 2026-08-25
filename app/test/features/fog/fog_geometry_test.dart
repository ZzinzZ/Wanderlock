import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/fog/domain/fog_geometry.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';

/// The fog is the one lens whose correctness is arithmetic rather than
/// appearance, so it is the one that can be held to account without a screen.
void main() {
  const benThanh = FogHole(
    latitude: 10.7725509,
    longitude: 106.697868,
    revealRadiusMeters: 300,
  );

  List<List<double>> ringsOf(Map<String, Object?> geojson, int index) {
    final features = geojson['features']! as List<Object?>;
    final geometry =
        (features.first! as Map<String, Object?>)['geometry']!
            as Map<String, Object?>;
    final rings = geometry['coordinates']! as List<List<List<double>>>;
    return rings[index];
  }

  group('veil', () {
    test('is one polygon whose first ring is the whole world', () {
      final rings = ringsOf(FogGeometry.veil(const []), 0);

      // Longitudes reach both edges: pan anywhere and there is still fog.
      expect(rings.map((point) => point[0]), contains(-180));
      expect(rings.map((point) => point[0]), contains(180));
      expect(rings.first, equals(rings.last), reason: 'ring must be closed');
    });

    test('still covers the map when nothing has been visited', () {
      final features = FogGeometry.veil(const [])['features']! as List<Object?>;

      // The obvious bug is an empty collection, which makes the layer vanish
      // and shows a fully revealed city to someone who has been nowhere.
      expect(features, hasLength(1));
    });

    test('a visited place becomes a hole after the world ring', () {
      final veil = FogGeometry.veil(const [benThanh]);
      final rings =
          ((veil['features']! as List<Object?>).first!
                  as Map<String, Object?>)['geometry']!
              as Map<String, Object?>;
      final coordinates = rings['coordinates']! as List<List<List<double>>>;

      expect(coordinates, hasLength(2));
      // GeoJSON reads ring 0 as the outside and every later ring as a hole.
      // Emitting the hole first would fill the ocean and clear the city.
      expect(coordinates[1].first[0], closeTo(benThanh.longitude, 0.01));
    });

    test('the hole is a circle on the ground, not on the page', () {
      final ring = ringsOf(FogGeometry.veil(const [benThanh]), 1);

      final longitudes = ring.map((point) => point[0]);
      final latitudes = ring.map((point) => point[1]);
      final longitudeSpan =
          longitudes.reduce(math.max) - longitudes.reduce(math.min);
      final latitudeSpan =
          latitudes.reduce(math.max) - latitudes.reduce(math.min);

      // A degree of longitude is shorter than a degree of latitude everywhere
      // but the equator, so an honest circle is *wider* in degrees than it is
      // tall. Equal spans would mean the cosine was skipped and the hole is an
      // ellipse squeezed along the east-west axis.
      expect(longitudeSpan, greaterThan(latitudeSpan));
      expect(
        longitudeSpan / latitudeSpan,
        closeTo(1 / math.cos(benThanh.latitude * math.pi / 180), 0.001),
      );
    });

    test('the hole is the size it was asked for', () {
      final ring = ringsOf(FogGeometry.veil(const [benThanh]), 1);
      final latitudes = ring.map((point) => point[1]);
      final metres =
          (latitudes.reduce(math.max) - benThanh.latitude) *
          FogGeometry.metresPerDegreeLatitude;

      expect(metres, closeTo(benThanh.revealRadiusMeters, 1));
    });
  });

  group('revealRadiusMeters', () {
    test('opens more map than the check-in radius', () {
      // A 60 m hole is a pinprick at city zoom: the map would never visibly
      // open, and the lens would look broken rather than earned.
      expect(FogGeometry.revealRadiusMeters(60), greaterThan(60));
    });

    test('a narrow gate and a wide plaza open comparable amounts', () {
      final gate = FogGeometry.revealRadiusMeters(40);
      final plaza = FogGeometry.revealRadiusMeters(80);

      expect(plaza / gate, lessThan(2));
    });

    test('scales with the radius once past the floor', () {
      expect(
        FogGeometry.revealRadiusMeters(200),
        200 * FogGeometry.revealMultiplier,
      );
    });
  });

  group('clearedEdges', () {
    test('draws a rim per hole and none for the world', () {
      final features =
          FogGeometry.clearedEdges(const [benThanh])['features']!
              as List<Object?>;

      // One rim, not two: a stroke on the veil polygon would also outline the
      // world rectangle and draw a line across the Pacific.
      expect(features, hasLength(1));
    });

    test('nothing visited means no rims at all', () {
      expect(FogGeometry.clearedEdges(const [])['features'], isEmpty);
    });
  });
}
