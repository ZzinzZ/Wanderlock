/// The rules behind exploring by panning, kept apart from the screen that
/// applies them: they are decisions rather than drawing, and neither was
/// testable while it lived inside a widget.
library;

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';

/// What a camera frame means for where the player stands.
sealed class PanStep {
  const PanStep();
}

/// First frame: put the player down without treating it as an arrival.
class PanSetDown extends PanStep {
  const PanSetDown(this.at);

  final TrailPoint at;
}

/// The map was dragged, so the player walked the same distance.
class PanWalk extends PanStep {
  const PanWalk(this.to);

  final TrailPoint to;
}

/// The zoom changed, so the player did not move.
class PanZoomed extends PanStep {
  const PanZoomed();
}

/// Below this a change in zoom is rounding in the reported camera rather than
/// the user zooming.
const double panZoomTolerance = 0.001;

/// Reads one camera frame.
///
/// A pinch zooms about the point between the fingers, which moves the centre;
/// treating that as a drag walked the player whenever anyone zoomed.
PanStep panStepFor({
  required LatLng centre,
  required double zoom,
  required LatLng? lastCentre,
  required double? lastZoom,
  required TrailPoint? explorer,
}) {
  if (explorer == null || lastCentre == null || lastZoom == null) {
    return PanSetDown(
      TrailPoint(latitude: centre.latitude, longitude: centre.longitude),
    );
  }
  if ((zoom - lastZoom).abs() > panZoomTolerance) return const PanZoomed();

  return PanWalk(
    TrailPoint(
      latitude: explorer.latitude + centre.latitude - lastCentre.latitude,
      longitude: explorer.longitude + centre.longitude - lastCentre.longitude,
    ),
  );
}

/// A checkpoint the player just walked into, and the point on their path
/// closest to it — somewhere they really went, which the authority then
/// measures for itself.
class Arrival {
  const Arrival(this.checkpoint, this.at);

  final Checkpoint checkpoint;
  final TrailPoint at;
}

/// Which checkpoint, if any, the step from [from] to [here] arrived at.
///
/// Treats the step as the segment it is: the map reports only a handful of
/// camera positions per swipe, so a quick drag across a checkpoint can jump
/// from one side of a 60 m radius to the other without a single sample inside.
///
/// Arriving means crossing in from outside, so a step that begins inside the
/// radius is not an arrival — that is the player being set down there, or
/// lingering. Leaving re-arms the checkpoint by dropping it from [asked],
/// which is why that set is modified here rather than by the caller.
///
/// [checkpoints] is every place, filtered or not: the map filter decides what
/// is drawn and must never decide what can be unlocked.
Arrival? arrivalBetween({
  required TrailPoint from,
  required TrailPoint here,
  required List<Checkpoint> checkpoints,
  required Set<String> visited,
  required Set<String> asked,
  required bool isCelebrating,
}) {
  // A jump is not a walk: nothing between the two ends was visited.
  final isJump = FogTrail.distanceMeters(from, here) > FogTrail.maxJoinMeters;

  for (final checkpoint in checkpoints) {
    if (visited.contains(checkpoint.id)) continue;

    final target = TrailPoint(
      latitude: checkpoint.latitude,
      longitude: checkpoint.longitude,
    );
    final nearest = isJump
        ? here
        : FogTrail.nearestOnSegment(from, here, target);
    final startsInside =
        FogTrail.distanceMeters(from, target) <= checkpoint.radiusMeters;

    if (startsInside ||
        FogTrail.distanceMeters(nearest, target) > checkpoint.radiusMeters) {
      asked.remove(checkpoint.id);
      continue;
    }
    // While a celebration is on screen the checkpoint is deliberately left
    // unasked, so it can still open once the three seconds are over.
    if (isCelebrating || !asked.add(checkpoint.id)) continue;

    return Arrival(checkpoint, nearest);
  }
  return null;
}
