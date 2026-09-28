/// The three numbers an authority needs to judge a check-in.
///
/// `unlock` must not import the checkpoint feature — lenses meet here, not
/// through each other — and it does not need to: a place, to the unlock layer,
/// is a position and a radius. The composition layer supplies these.
///
/// The real authority never sees this type. It reads the same three numbers
/// out of its own table, which is the point: the phone's copy is for drawing
/// and for the stand-in, never for deciding.
class CheckpointGeofence {
  const CheckpointGeofence({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final int radiusMeters;
}
