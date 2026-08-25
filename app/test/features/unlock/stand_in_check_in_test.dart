import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/unlock/data/stand_in_check_in_service.dart';
import 'package:wanderlock/features/unlock/domain/check_in_service.dart';
import 'package:wanderlock/features/unlock/domain/checkpoint_geofence.dart';
import 'package:wanderlock/features/unlock/domain/geo_distance.dart';
import 'package:wanderlock/features/unlock/domain/visit_state.dart';

/// The stand-in stands in for a server, so it is held to the server's rule.
///
/// If it ever granted something the SQL would refuse, every screen built
/// against it would be built against a lie, and the day the real service
/// arrives the product would quietly stop working.
void main() {
  const benThanh = CheckpointGeofence(
    latitude: 10.7725509,
    longitude: 106.697868,
    radiusMeters: 50,
  );

  const hanoi = (latitude: 21.0285, longitude: 105.8542);

  StandInCheckInService serviceFor(Map<String, CheckpointGeofence> places) {
    return StandInCheckInService(geofenceOf: (id) => places[id]);
  }

  group('geo distance', () {
    test('is zero at the same point', () {
      expect(
        metresBetween(
          fromLatitude: benThanh.latitude,
          fromLongitude: benThanh.longitude,
          toLatitude: benThanh.latitude,
          toLongitude: benThanh.longitude,
        ),
        closeTo(0, 0.001),
      );
    });

    test('agrees with the server to within half a percent', () {
      // The edge function answered 1138503.8 m for this pair against a live
      // database. This function answers about 1143963 m — 0.48% more, and the
      // gap is not a bug: PostGIS `geography` measures on the WGS84 ellipsoid
      // and this measures on a sphere.
      //
      // The tolerance is written as a fraction rather than as a metre count so
      // it says what it means. At the distance that actually matters — a 60 m
      // check-in radius — half a percent is 30 cm, which is two orders of
      // magnitude inside GPS noise. And the client's number never decides an
      // unlock in any case; the server's does.
      const serverAnswer = 1138503.8;
      final ours = metresBetween(
        fromLatitude: hanoi.latitude,
        fromLongitude: hanoi.longitude,
        toLatitude: benThanh.latitude,
        toLongitude: benThanh.longitude,
      );

      expect((ours - serverAnswer).abs() / serverAnswer, lessThan(0.005));
    });

    test('measures east-west shorter than north-south by the same degrees', () {
      final northSouth = metresBetween(
        fromLatitude: 10.77,
        fromLongitude: 106.69,
        toLatitude: 10.78,
        toLongitude: 106.69,
      );
      final eastWest = metresBetween(
        fromLatitude: 10.77,
        fromLongitude: 106.69,
        toLatitude: 10.77,
        toLongitude: 106.70,
      );

      // Longitude degrees are shorter away from the equator. A distance
      // function that treated the two axes alike would fail here — and would
      // put every radius decision out by nearly 2% at the pilot's latitude.
      expect(eastWest, lessThan(northSouth));
    });
  });

  group('stand-in check-in', () {
    test('grants when the position is inside the radius', () async {
      final outcome = await serviceFor({'ben-thanh-market': benThanh}).checkIn(
        checkpointId: 'ben-thanh-market',
        latitude: benThanh.latitude,
        longitude: benThanh.longitude,
      );

      expect(outcome, isA<CheckInGranted>());
      final visit = (outcome as CheckInGranted).visit;
      expect(visit.status, VisitStatus.visited);
      expect(visit.verifiedBy, VerifyMethod.gps);
      expect(visit.checkpointId, 'ben-thanh-market');
    });

    test('refuses from another city, and says how far', () async {
      final outcome = await serviceFor({'ben-thanh-market': benThanh}).checkIn(
        checkpointId: 'ben-thanh-market',
        latitude: hanoi.latitude,
        longitude: hanoi.longitude,
      );

      expect(outcome, isA<CheckInTooFar>());
      expect((outcome as CheckInTooFar).radiusMeters, 50);
      expect(outcome.distanceMeters, greaterThan(1000000));
    });

    test('refuses just outside the radius', () async {
      // Roughly 90 m north of a 50 m radius. The interesting case is not the
      // one a thousand kilometres away; it is the one that nearly passes.
      final outcome = await serviceFor({'ben-thanh-market': benThanh}).checkIn(
        checkpointId: 'ben-thanh-market',
        latitude: benThanh.latitude + 0.0008,
        longitude: benThanh.longitude,
      );

      expect(outcome, isA<CheckInTooFar>());
    });

    test('grants just inside the radius', () async {
      // Roughly 33 m north, inside 50 m.
      final outcome = await serviceFor({'ben-thanh-market': benThanh}).checkIn(
        checkpointId: 'ben-thanh-market',
        latitude: benThanh.latitude + 0.0003,
        longitude: benThanh.longitude,
      );

      expect(outcome, isA<CheckInGranted>());
    });

    test('refuses a checkpoint it has never heard of', () async {
      final outcome = await serviceFor(const {}).checkIn(
        checkpointId: 'not-a-place',
        latitude: benThanh.latitude,
        longitude: benThanh.longitude,
      );

      expect(outcome, isA<CheckInRejected>());
      expect((outcome as CheckInRejected).reason, 'unknown_checkpoint');
    });

    test('an unanswerable lookup refuses rather than grants', () async {
      // The default seam in `unlock` answers null for everything. A build that
      // forgot to install the real lookup must fail closed.
      const service = StandInCheckInService(geofenceOf: _alwaysUnknown);
      final outcome = await service.checkIn(
        checkpointId: 'ben-thanh-market',
        latitude: benThanh.latitude,
        longitude: benThanh.longitude,
      );

      expect(outcome, isA<CheckInRejected>());
    });
  });
}

CheckpointGeofence? _alwaysUnknown(String checkpointId) => null;
