import 'dart:math' as math;

/// One place the explorer has been, as the fog remembers it.
///
/// **Not unlock state.** A trail point clears fog so the map shows where the
/// user has wandered; it never opens a checkpoint. Checkpoints open only
/// through `unlock` and `visit_state`, and the fog lens reads those the same
/// way every other lens does. Two different questions: "where have I walked?"
/// belongs to this lens alone, "what have I unlocked?" belongs to all of them.
class TrailPoint {
  const TrailPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrailPoint &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'TrailPoint($latitude, $longitude)';
}

/// How a trail grows as the explorer moves.
///
/// Pure arithmetic, so the rules can be tested without a map or a database.
class FogTrail {
  const FogTrail._();

  /// Radius the fog clears round each trail point: a street and a bit either
  /// side, roughly what you can see standing in a Saigon street.
  static const double revealRadiusMeters = 160;

  /// A new point is kept only this far from the last one. Closer than this and
  /// the two reveals overlap so much the second adds nothing but storage.
  static const double stepMeters = 50;

  /// Beyond this the move is a jump — a fling across the city, a GPS fix after
  /// a tunnel — and the gap is not filled in. Joining it would draw a straight
  /// corridor through streets nobody walked.
  static const double maxJoinMeters = 3000;

  static const double _metresPerDegreeLatitude = 111320;

  /// Ground distance between two points, in metres.
  ///
  /// Equirectangular: at city scale and this latitude it is within a fraction
  /// of a percent of the haversine, and cheaper, which matters because it runs
  /// on every frame of a pan.
  static double distanceMeters(TrailPoint a, TrailPoint b) {
    final meanLatitude = (a.latitude + b.latitude) / 2 * math.pi / 180;
    final dy = (b.latitude - a.latitude) * _metresPerDegreeLatitude;
    final dx =
        (b.longitude - a.longitude) *
        _metresPerDegreeLatitude *
        math.cos(meanLatitude);
    return math.sqrt(dx * dx + dy * dy);
  }

  /// The point on the segment [a]–[b] closest to [p].
  ///
  /// Worked in a local flat frame, which is exact enough over the few hundred
  /// metres one step can cover. Used to ask whether a move passed through a
  /// checkpoint's radius, not merely whether it ended inside it.
  static TrailPoint nearestOnSegment(TrailPoint a, TrailPoint b, TrailPoint p) {
    final scale = math.cos(a.latitude * math.pi / 180);
    final abx = (b.longitude - a.longitude) * scale;
    final aby = b.latitude - a.latitude;
    final apx = (p.longitude - a.longitude) * scale;
    final apy = p.latitude - a.latitude;
    final lengthSquared = abx * abx + aby * aby;
    if (lengthSquared == 0) return a;
    final t = ((apx * abx + apy * aby) / lengthSquared).clamp(0.0, 1.0);
    return TrailPoint(
      latitude: a.latitude + aby * t,
      longitude: a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// The points to add when the explorer, last recorded at [last], is now at
  /// [next].
  ///
  /// Empty when they have not moved far enough. When they have moved further
  /// than one step, the gap is filled with evenly spaced points so the reveal
  /// is a continuous road from A to B rather than two separate clearings —
  /// the owner's first complaint about the fog.
  static List<TrailPoint> extend(TrailPoint? last, TrailPoint next) {
    if (last == null) return [next];

    final distance = distanceMeters(last, next);
    if (distance < stepMeters) return const [];
    if (distance > maxJoinMeters) return [next];

    final steps = (distance / stepMeters).ceil();
    return [
      for (var i = 1; i <= steps; i++)
        TrailPoint(
          latitude: last.latitude + (next.latitude - last.latitude) * i / steps,
          longitude:
              last.longitude + (next.longitude - last.longitude) * i / steps,
        ),
    ];
  }
}

/// Where the trail is kept.
abstract interface class FogTrailRepository {
  Stream<List<TrailPoint>> watch();

  Future<void> append(List<TrailPoint> points);
}
