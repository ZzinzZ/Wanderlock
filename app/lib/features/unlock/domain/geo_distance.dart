import 'dart:math' as math;

/// Distance between two positions on the earth, in metres.
///
/// Haversine on a sphere. The pilot spans about 25 km, where the difference
/// from a proper ellipsoid is well under a metre — far below GPS noise, and
/// far below any check-in radius.
///
/// **This is not the check-in authority.** The server measures the distance
/// that decides an unlock, in SQL, inside the same transaction that writes the
/// visit. This copy exists so the app can tell a walker how much further they
/// have to go, and it must never be the reason a checkpoint opens.
double metresBetween({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const earthRadiusMetres = 6371008.8;

  final fromLatitudeRadians = _radians(fromLatitude);
  final toLatitudeRadians = _radians(toLatitude);
  final deltaLatitude = _radians(toLatitude - fromLatitude);
  final deltaLongitude = _radians(toLongitude - fromLongitude);

  final a =
      math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
      math.cos(fromLatitudeRadians) *
          math.cos(toLatitudeRadians) *
          math.sin(deltaLongitude / 2) *
          math.sin(deltaLongitude / 2);

  return 2 * earthRadiusMetres * math.asin(math.min(1, math.sqrt(a)));
}

double _radians(double degrees) => degrees * math.pi / 180;
