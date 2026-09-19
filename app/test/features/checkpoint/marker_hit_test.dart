import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:wanderlock/core/map/map_projection.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_marker_overlay.dart';

/// Markers ignore the pointer so a drag that starts on one still pans the map.
/// Taps therefore arrive at the map, and this is what turns one back into the
/// marker under the finger.
void main() {
  const size = Size(411, 914);
  const camera = CameraPosition(target: LatLng(10.7769, 106.7009), zoom: 15);

  const benThanh = Checkpoint(
    id: 'ben-thanh-market',
    name: 'Chợ Bến Thành',
    latitude: 10.7725,
    longitude: 106.6980,
    radiusMeters: 60,
    category: CheckpointCategory.market,
  );
  const postOffice = Checkpoint(
    id: 'central-post-office',
    name: 'Bưu điện',
    latitude: 10.7798,
    longitude: 106.6999,
    radiusMeters: 60,
    category: CheckpointCategory.architecture,
  );

  /// The coordinate under a screen point `dx, dy` away from [of].
  LatLng tapNear(Checkpoint of, double dx, double dy) {
    final projection = MapProjection(
      centerLatitude: camera.target.latitude,
      centerLongitude: camera.target.longitude,
      zoom: camera.zoom,
      widthPixels: size.width,
      heightPixels: size.height,
    );
    final metresPerPixel = projection.metersPerPixel(of.latitude);
    return LatLng(
      of.latitude - dy * metresPerPixel / 111320,
      of.longitude + dx * metresPerPixel / 109400,
    );
  }

  Checkpoint? hit(LatLng at) => CheckpointMarkerOverlay.checkpointAt(
    camera: camera,
    size: size,
    checkpoints: const [benThanh, postOffice],
    latitude: at.latitude,
    longitude: at.longitude,
  );

  test('a tap on the sticker selects its place', () {
    expect(hit(tapNear(benThanh, 5, -5)), benThanh);
  });

  test('a tap on the name tag under the sticker selects it too', () {
    expect(hit(tapNear(postOffice, 0, 55)), postOffice);
  });

  test('a tap on empty map selects nothing', () {
    expect(hit(tapNear(benThanh, 200, 0)), isNull);
  });
}
