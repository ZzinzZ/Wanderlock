import 'dart:math' as math;

import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// A rectangle on the globe, given by its south-west and north-east corners.
///
/// Deliberately not MapLibre's `LatLngBounds`: this lives in `domain/`, which
/// depends on plain Dart only, so the area worth keeping offline can be
/// computed and tested without a map engine or a device.
class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoBounds &&
          other.south == south &&
          other.west == west &&
          other.north == north &&
          other.east == east;

  @override
  int get hashCode => Object.hash(south, west, north, east);

  @override
  String toString() =>
      'GeoBounds(south: $south, west: $west, north: $north, east: $east)';
}

/// Web Mercator cannot represent the poles, and MapLibre clamps here too.
const _mercatorLatitudeLimit = 85.05112878;

/// Kilometres in one degree of latitude. A degree of longitude is this
/// shortened by the cosine of the latitude.
const _kmPerDegreeLatitude = 111.32;

/// The area worth having on the phone before leaving the house.
///
/// Derived from the checkpoints themselves rather than written down as a fixed
/// box, for one reason: the pilot's coordinates are still being verified. A
/// hardcoded box would be a guess that silently stays wrong after the real
/// coordinates land, while this one simply becomes correct.
///
/// [paddingKm] is the margin around the outermost checkpoints, so someone who
/// wanders off the straight line between two places does not walk off the edge
/// of the downloaded map.
///
/// Returns null for an empty list. There is no region to speak of, and a
/// zero-size download is a worse answer than admitting there is nothing to do.
///
/// Does not handle a region straddling the antimeridian — the pilot is one
/// city, and the wrong answer there would be a silently enormous download
/// rather than a subtle error.
GeoBounds? cacheRegionFor(
  Iterable<Checkpoint> checkpoints, {
  double paddingKm = 2,
}) {
  if (checkpoints.isEmpty) return null;

  var south = double.infinity;
  var north = double.negativeInfinity;
  var west = double.infinity;
  var east = double.negativeInfinity;

  for (final checkpoint in checkpoints) {
    south = math.min(south, checkpoint.latitude);
    north = math.max(north, checkpoint.latitude);
    west = math.min(west, checkpoint.longitude);
    east = math.max(east, checkpoint.longitude);
  }

  final latitudePadding = paddingKm / _kmPerDegreeLatitude;

  // Longitude degrees shrink away from the equator, so the padding is computed
  // at whichever edge is furthest from it. That way the margin is at least
  // [paddingKm] along the whole box rather than only at its middle.
  final worstLatitude = math.max(south.abs(), north.abs());
  final longitudePadding =
      paddingKm /
      (_kmPerDegreeLatitude * math.cos(worstLatitude * math.pi / 180));

  return GeoBounds(
    south: math.max(south - latitudePadding, -_mercatorLatitudeLimit),
    north: math.min(north + latitudePadding, _mercatorLatitudeLimit),
    west: math.max(west - longitudePadding, -180),
    east: math.min(east + longitudePadding, 180),
  );
}
