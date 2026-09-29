import 'package:flutter/rendering.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/map/map_projection.dart';

/// Builds the projection an overlay needs from the camera it is drawing under.
///
/// Lives here rather than on [MapProjection] so that class stays free of
/// Flutter and MapLibre types — it is arithmetic, and its tests run without a
/// binding. This is the adapter between the two.
extension CameraProjection on CameraPosition {
  /// The projection that puts this camera's world onto a [size] viewport.
  MapProjection projectionOver(Size size) => MapProjection(
    centerLatitude: target.latitude,
    centerLongitude: target.longitude,
    zoom: zoom,
    widthPixels: size.width,
    heightPixels: size.height,
  );
}
