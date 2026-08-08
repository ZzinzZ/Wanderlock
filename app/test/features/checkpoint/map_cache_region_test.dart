import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/map_cache_region.dart';

Checkpoint _at(double latitude, double longitude) => Checkpoint(
  id: '$latitude,$longitude',
  name: 'test',
  latitude: latitude,
  longitude: longitude,
  radiusMeters: 50,
  category: CheckpointCategory.monument,
);

/// Two checkpoints roughly at the corners of the pilot area.
final _benThanh = _at(10.7721, 106.6981);
final _landmark81 = _at(10.7947, 106.7218);

void main() {
  // Nothing to cache is a real answer. Falling back to a default box would
  // download a city the user has no checkpoints in.
  test('no checkpoints means no region', () {
    expect(cacheRegionFor(const []), isNull);
  });

  test('the box contains every checkpoint', () {
    final bounds = cacheRegionFor([_benThanh, _landmark81])!;

    for (final checkpoint in [_benThanh, _landmark81]) {
      expect(checkpoint.latitude, greaterThan(bounds.south));
      expect(checkpoint.latitude, lessThan(bounds.north));
      expect(checkpoint.longitude, greaterThan(bounds.west));
      expect(checkpoint.longitude, lessThan(bounds.east));
    }
  });

  // The margin is the point: someone who wanders off the line between two
  // places must not walk off the edge of the downloaded map.
  test('the padding is at least the distance asked for', () {
    // Deliberately not the default, so the test proves the argument is used
    // rather than that the default happens to be right.
    const paddingKm = 3.5;
    const kmPerDegreeLatitude = 111.32;

    final bounds = cacheRegionFor([_benThanh], paddingKm: paddingKm)!;

    final southMarginKm =
        (_benThanh.latitude - bounds.south) * kmPerDegreeLatitude;
    expect(southMarginKm, closeTo(paddingKm, 0.01));

    // The margin has to be the same *distance* east as it is south, which is
    // not the same number of degrees: a degree of longitude is shorter this
    // far from the equator. Measured in kilometres rather than by comparing
    // the two degree spans — those differ by under 2%, close enough that
    // floating-point noise at longitude 106 decides the comparison instead of
    // the arithmetic under test.
    final eastMarginKm =
        (bounds.east - _benThanh.longitude) *
        kmPerDegreeLatitude *
        math.cos(_benThanh.latitude * math.pi / 180);
    expect(eastMarginKm, closeTo(paddingKm, 0.01));
  });

  test('a single checkpoint still yields a usable box', () {
    final bounds = cacheRegionFor([_benThanh])!;

    expect(bounds.north, greaterThan(bounds.south));
    expect(bounds.east, greaterThan(bounds.west));
  });

  test('one distant checkpoint widens the box to reach it', () {
    final near = cacheRegionFor([_benThanh])!;
    // Thiền viện Bửu Long is in Biên Hoà, well outside the city centre.
    final far = cacheRegionFor([_benThanh, _at(10.9500, 106.8300)])!;

    expect(far.north, greaterThan(near.north));
    expect(far.east, greaterThan(near.east));
    expect(far.south, closeTo(near.south, 1e-9));
  });

  // Web Mercator has no poles to download.
  test('the box never escapes the projection', () {
    final bounds = cacheRegionFor([_at(89.9, 179.9)], paddingKm: 500)!;

    expect(bounds.north, lessThanOrEqualTo(85.05112878));
    expect(bounds.east, lessThanOrEqualTo(180));
  });
}
