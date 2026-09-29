import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/app/screens/pan_exploration.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

/// The stand-in build walks a player by dragging the map, and these are the
/// two rules that decide where they end up and what that opens. Both were
/// wrong at some point and neither was reachable from a test while it lived
/// inside the explore screen.
void main() {
  const palace = Checkpoint(
    id: 'independence-palace',
    name: 'Dinh Độc Lập',
    latitude: 10.7768269,
    longitude: 106.6951472,
    radiusMeters: 60,
    category: CheckpointCategory.monument,
  );

  /// Roughly metres, at this latitude, as a step in degrees of longitude.
  double eastMetres(double metres) => metres / 109000;

  TrailPoint at(double latitude, double longitude) =>
      TrailPoint(latitude: latitude, longitude: longitude);

  group('reading a camera frame', () {
    test('the first frame sets the player down rather than walking them', () {
      final step = panStepFor(
        centre: const LatLng(10.77, 106.69),
        zoom: 15,
        lastCentre: null,
        lastZoom: null,
        explorer: null,
      );

      expect(step, isA<PanSetDown>());
      expect((step as PanSetDown).at.latitude, 10.77);
    });

    test('a drag walks the player by exactly the drag', () {
      final step = panStepFor(
        centre: const LatLng(10.78, 106.70),
        zoom: 15,
        lastCentre: const LatLng(10.77, 106.69),
        lastZoom: 15,
        explorer: at(10.50, 106.50),
      );

      expect(step, isA<PanWalk>());
      final to = (step as PanWalk).to;
      expect(to.latitude, closeTo(10.51, 1e-9));
      expect(to.longitude, closeTo(106.51, 1e-9));
    });

    test('a zoom moves nobody, however far the centre slid', () {
      final step = panStepFor(
        centre: const LatLng(10.90, 106.90),
        zoom: 16,
        lastCentre: const LatLng(10.77, 106.69),
        lastZoom: 15,
        explorer: at(10.50, 106.50),
      );

      expect(step, isA<PanZoomed>());
    });

    test('rounding in the reported zoom still counts as a drag', () {
      final step = panStepFor(
        centre: const LatLng(10.7701, 106.69),
        zoom: 15 + panZoomTolerance / 2,
        lastCentre: const LatLng(10.77, 106.69),
        lastZoom: 15,
        explorer: at(10.50, 106.50),
      );

      expect(step, isA<PanWalk>());
    });
  });

  group('arriving somewhere', () {
    Arrival? scan(
      TrailPoint from,
      TrailPoint here, {
      Set<String>? asked,
      Set<String>? visited,
      bool isCelebrating = false,
    }) => arrivalBetween(
      from: from,
      here: here,
      checkpoints: const [palace],
      visited: visited ?? <String>{},
      asked: asked ?? <String>{},
      isCelebrating: isCelebrating,
    );

    test('walking in from outside arrives', () {
      final arrival = scan(
        at(palace.latitude, palace.longitude - eastMetres(300)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
      );

      expect(arrival?.checkpoint.id, palace.id);
    });

    test('a swipe clean across the radius still arrives', () {
      // Neither end is inside 60 m, and no camera frame landed in between —
      // the case that used to pass straight through without unlocking.
      final arrival = scan(
        at(palace.latitude, palace.longitude - eastMetres(400)),
        at(palace.latitude, palace.longitude + eastMetres(400)),
      );

      expect(arrival?.checkpoint.id, palace.id);
      expect(
        FogTrail.distanceMeters(
          arrival!.at,
          at(palace.latitude, palace.longitude),
        ),
        lessThanOrEqualTo(palace.radiusMeters.toDouble()),
      );
    });

    test('a jump is not a walk, so nothing in between counts', () {
      // Further apart than the trail will join, so only the far end is real.
      final arrival = scan(
        at(palace.latitude, palace.longitude - eastMetres(50000)),
        at(palace.latitude, palace.longitude + eastMetres(50000)),
      );

      expect(arrival, isNull);
    });

    test('starting inside the radius is not an arrival', () {
      final arrival = scan(
        at(palace.latitude, palace.longitude),
        at(palace.latitude, palace.longitude + eastMetres(10)),
      );

      expect(arrival, isNull);
    });

    test('lingering inside asks once, not on every frame', () {
      final asked = <String>{};
      final first = scan(
        at(palace.latitude, palace.longitude - eastMetres(300)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
        asked: asked,
      );
      final second = scan(
        at(palace.latitude, palace.longitude - eastMetres(20)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
        asked: asked,
      );

      expect(first?.checkpoint.id, palace.id);
      expect(second, isNull);
    });

    test('leaving and coming back asks again', () {
      final asked = <String>{'independence-palace'};
      scan(
        at(palace.latitude, palace.longitude + eastMetres(500)),
        at(palace.latitude, palace.longitude + eastMetres(900)),
        asked: asked,
      );

      expect(asked, isEmpty, reason: 'walking away re-arms the checkpoint');

      final again = scan(
        at(palace.latitude, palace.longitude - eastMetres(300)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
        asked: asked,
      );
      expect(again?.checkpoint.id, palace.id);
    });

    test('a place already unlocked is not asked about again', () {
      final arrival = scan(
        at(palace.latitude, palace.longitude - eastMetres(300)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
        visited: {palace.id},
      );

      expect(arrival, isNull);
    });

    test('a celebration holds the ask back without consuming it', () {
      final asked = <String>{};
      final during = scan(
        at(palace.latitude, palace.longitude - eastMetres(300)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
        asked: asked,
        isCelebrating: true,
      );

      expect(during, isNull);
      expect(
        asked,
        isEmpty,
        reason: 'it must still open once the three seconds end',
      );

      final after = scan(
        at(palace.latitude, palace.longitude - eastMetres(300)),
        at(palace.latitude, palace.longitude - eastMetres(10)),
        asked: asked,
      );
      expect(after?.checkpoint.id, palace.id);
    });
  });
}
