import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/fog/domain/fog_reveal.dart';

/// What is left of the old `fog_geometry_test.dart`.
///
/// That file also guarded the GeoJSON veil — ring winding, world rings, the
/// shoelace helper — for a renderer the branch replaced with a Flutter painter.
/// Those tests went with the code they were guarding; keeping them green would
/// have meant keeping an abandoned implementation alive to be tested.
void main() {
  group('radiusMeters', () {
    test('opens more map than the check-in radius', () {
      // A 60 m hole is a pinprick at city zoom: the map would never visibly
      // open, and the lens would look broken rather than earned.
      expect(FogReveal.radiusMeters(60), greaterThan(60));
    });

    test('a narrow gate and a wide plaza open comparable amounts', () {
      final gate = FogReveal.radiusMeters(40);
      final plaza = FogReveal.radiusMeters(80);

      expect(plaza / gate, lessThan(2));
    });

    test('scales with the radius once past the floor', () {
      // Derived from the floor rather than written as a number, so raising
      // the floor cannot quietly turn this into a second test of the floor —
      // which is what happened when it moved from 260 m to 900 m and a
      // hard-coded 200 m checkpoint stopped being past it.
      final pastFloor =
          (FogReveal.minimumRevealMeters / FogReveal.revealMultiplier).ceil() +
          1;

      expect(
        FogReveal.radiusMeters(pastFloor),
        pastFloor * FogReveal.revealMultiplier,
      );
      expect(
        FogReveal.radiusMeters(pastFloor),
        greaterThan(FogReveal.minimumRevealMeters),
      );
    });
  });
}
