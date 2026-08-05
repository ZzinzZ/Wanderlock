import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The base map.
///
/// F3's job is to make this look like our product rather than a map
/// provider's demo. Checkpoint markers arrive once there are verified
/// coordinates and processed photographs to put on them.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  /// Ho Chi Minh City centre. A starting camera, not a claim about where the
  /// user is — that arrives with location permission in F4.
  static const _initialCamera = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: MapLibreMap(
        // Rebuilt when the theme changes, which is what gives dark mode its
        // own map instead of a tinted copy of the light one.
        styleString: MapStyle.toJson(
          tilesUrl: AppConfig.mapTilesUrl,
          glyphsUrl: AppConfig.mapGlyphsUrl,
          brightness: brightness,
        ),
        initialCameraPosition: _initialCamera,
        // Nothing in this product is served by tilting or rotating the map,
        // and both make a fog overlay considerably harder to draw correctly.
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
      ),
    );
  }
}
