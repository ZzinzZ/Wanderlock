import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/checkpoint/domain/map_projection.dart';

/// The markers are Flutter widgets now, so this arithmetic is the only thing
/// standing between a place and being drawn in the wrong part of the city.
/// MapLibre used to do it; nothing checks it for us any more.
void main() {
  const benThanh = (lat: 10.7725509, lon: 106.697868);

  MapProjection at({
    double lat = 10.7769,
    double lon = 106.7009,
    double zoom = 13,
    double width = 400,
    double height = 800,
  }) => MapProjection(
    centerLatitude: lat,
    centerLongitude: lon,
    zoom: zoom,
    widthPixels: width,
    heightPixels: height,
  );

  test('the camera target lands exactly in the middle', () {
    final projection = at();
    final screen = projection.toScreen(10.7769, 106.7009);

    expect(screen.x, closeTo(200, 0.001));
    expect(screen.y, closeTo(400, 0.001));
  });

  test('east is right and north is up', () {
    final projection = at();
    final east = projection.toScreen(10.7769, 106.75);
    final north = projection.toScreen(10.82, 106.7009);

    expect(east.x, greaterThan(200));
    expect(north.y, lessThan(400));
  });

  test('zooming in doubles the distance from the centre', () {
    final near = at().toScreen(benThanh.lat, benThanh.lon);
    final closer = at(zoom: 14).toScreen(benThanh.lat, benThanh.lon);

    final nearOffset = (near.x - 200).abs() + (near.y - 400).abs();
    final closerOffset = (closer.x - 200).abs() + (closer.y - 400).abs();

    expect(closerOffset, closeTo(nearOffset * 2, 0.5));
  });

  test('uses 512 px tiles, the size MapLibre draws vector tiles at', () {
    // One full turn of longitude at zoom 0 is exactly one world. Getting this
    // wrong by using 256 puts every marker at half its true offset — which
    // looks nearly right at the centre of the screen and clearly wrong at the
    // edges, the worst way for a bug like this to present.
    final projection = at(lat: 0, lon: 0, zoom: 0, width: 512, height: 512);
    final quarterWayEast = projection.toScreen(0, 90);

    expect(quarterWayEast.x, closeTo(256 + 128, 0.001));
  });

  test('a place off screen is culled, with a margin', () {
    final projection = at();
    final faraway = projection.toScreen(21.0285, 105.8542);

    expect(projection.isVisible(faraway), isFalse);
  });

  test('a place just past the edge is kept, because its art is wider', () {
    final projection = at();

    expect(projection.isVisible((x: -20, y: 400)), isTrue);
    expect(projection.isVisible((x: -200, y: 400)), isFalse);
  });

  test('extreme latitudes are clamped rather than producing infinity', () {
    final projection = at();
    final pole = projection.toScreen(90, 106.7);

    expect(pole.y.isFinite, isTrue);
  });

  test('the pilot fits on one screen at the zoom the map opens at', () {
    // District 1 to Bửu Long is about 25 km. If the opening camera cannot hold
    // the pilot, the first thing a new user sees is a map with two pins on it.
    final projection = at(width: 1080, height: 2400, zoom: 11);
    final closest = projection.toScreen(10.7725509, 106.697868);
    final farthest = projection.toScreen(10.8786681, 106.8349651);

    expect(projection.isVisible(closest), isTrue);
    expect(projection.isVisible(farthest), isTrue);
  });
}
