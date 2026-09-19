import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

void main() {
  const benThanh = TrailPoint(latitude: 10.7725, longitude: 106.6980);
  // Roughly 1 km north-east, towards the post office.
  const postOffice = TrailPoint(latitude: 10.7798, longitude: 106.6999);

  group('FogTrail.extend', () {
    test('the first point is kept as it is', () {
      expect(FogTrail.extend(null, benThanh), [benThanh]);
    });

    test('a move shorter than a step adds nothing', () {
      const nudge = TrailPoint(latitude: 10.77252, longitude: 106.69802);
      expect(FogTrail.extend(benThanh, nudge), isEmpty);
    });

    // The owner's complaint: A and B lit, the road between them still dark.
    test('a longer move is filled in, so the whole road clears', () {
      final added = FogTrail.extend(benThanh, postOffice);
      final distance = FogTrail.distanceMeters(benThanh, postOffice);

      expect(added.length, (distance / FogTrail.stepMeters).ceil());
      expect(added.last, postOffice);

      var previous = benThanh;
      for (final point in added) {
        expect(
          FogTrail.distanceMeters(previous, point),
          lessThanOrEqualTo(FogTrail.stepMeters),
          reason: 'a gap wider than a step leaves dark fog on the road',
        );
        previous = point;
      }
    });

    test('a gap narrower than the reveal never shows between two points', () {
      expect(FogTrail.stepMeters, lessThan(FogTrail.revealRadiusMeters));
    });

    test('a jump across the city is not joined with a straight corridor', () {
      const thuDuc = TrailPoint(latitude: 10.8500, longitude: 106.7700);
      expect(FogTrail.extend(benThanh, thuDuc), [thuDuc]);
    });
  });

  test('distance agrees with a known span to within a percent', () {
    // One hundredth of a degree of latitude is about 1113 m anywhere.
    const north = TrailPoint(latitude: 10.7825, longitude: 106.6980);
    expect(FogTrail.distanceMeters(benThanh, north), closeTo(1113, 11));
  });

  group('FogTrail.nearestOnSegment', () {
    const west = TrailPoint(latitude: 10.7700, longitude: 106.6900);
    const east = TrailPoint(latitude: 10.7700, longitude: 106.7100);

    // A fast swipe straight over a checkpoint: both camera samples are far
    // outside its 60 m radius, but the road between them runs through it.
    test('finds a checkpoint the move passed over without stopping', () {
      const checkpoint = TrailPoint(latitude: 10.7702, longitude: 106.7000);
      final nearest = FogTrail.nearestOnSegment(west, east, checkpoint);

      expect(FogTrail.distanceMeters(west, checkpoint), greaterThan(60));
      expect(FogTrail.distanceMeters(east, checkpoint), greaterThan(60));
      expect(FogTrail.distanceMeters(nearest, checkpoint), lessThan(60));
    });

    test('never reaches past the ends of the move', () {
      const beyond = TrailPoint(latitude: 10.7700, longitude: 106.7300);
      expect(FogTrail.nearestOnSegment(west, east, beyond), east);
    });

    test('a move of zero length is its own nearest point', () {
      const checkpoint = TrailPoint(latitude: 10.7800, longitude: 106.7000);
      expect(FogTrail.nearestOnSegment(west, west, checkpoint), west);
    });
  });
}
