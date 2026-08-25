import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/fog/domain/fog_geometry.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';

/// Draws the fog of war onto a live map.
///
/// Renders nothing itself: it owns two MapLibre layers and keeps them in step
/// with [holes]. Kept as a widget so the lifecycle is the one Flutter already
/// manages — the layers go up when the lens appears and come down when it is
/// disposed, with no separate registry to forget to clean.
///
/// Turning the lens off hides the layers rather than removing them. Re-adding
/// a source costs a style round trip, and F5 caps a lens switch at 300 ms.
class FogLayer extends StatefulWidget {
  const FogLayer({
    required this.controller,
    required this.holes,
    this.isVisible = true,
    super.key,
  });

  final MapLibreMapController controller;

  /// Where the fog has been cleared. Derived from `visit_state` by the
  /// composition layer — the fog lens holds no unlock state of its own, which
  /// is the rule the whole architecture rests on.
  final List<FogHole> holes;

  final bool isVisible;

  static const String veilSourceId = 'wanderlock-fog-veil';
  static const String clearedSourceId = 'wanderlock-fog-cleared';
  static const String edgeSourceId = 'wanderlock-fog-edges';
  static const String veilLayerId = 'wanderlock-fog-veil-fill';
  static const String clearedLayerId = 'wanderlock-fog-cleared-fill';
  static const String edgeLayerId = 'wanderlock-fog-edge-line';

  /// Width of the rim around a cleared area, in logical pixels.
  static const double edgeWidth = 1.5;

  @override
  State<FogLayer> createState() => _FogLayerState();
}

class _FogLayerState extends State<FogLayer> {
  bool _isInstalled = false;

  /// Guards against a second install. `didChangeDependencies` runs again on
  /// every inherited change, and layers are not idempotent — adding a source
  /// twice is an error on the platform side.
  bool _hasStartedInstall = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`. The colours come from the theme, and reading an
    // inherited widget before initState finishes throws — which it duly did,
    // on the first launch, before this was moved.
    if (_hasStartedInstall) return;
    _hasStartedInstall = true;
    _install();
  }

  @override
  void didUpdateWidget(FogLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInstalled) return;
    if (!identical(oldWidget.holes, widget.holes)) unawaitedSync();
    if (oldWidget.isVisible != widget.isVisible) unawaitedVisibility();
  }

  /// Named rather than inlined so the fire-and-forget is deliberate and
  /// greppable: a map call that fails mid-frame must not take the frame with
  /// it, and there is nothing useful to await inside `didUpdateWidget`.
  void unawaitedSync() {
    _syncData();
  }

  void unawaitedVisibility() {
    _syncVisibility();
  }

  Future<void> _install() async {
    // Read once at install time, from the theme rather than from the platform:
    // the map style is built from `Theme.of(context).brightness`, and a fog
    // that asked the operating system instead would disagree with the map
    // underneath it the moment someone used the in-app theme toggle.
    //
    // The style document is rebuilt on a theme change, which tears this widget
    // down and brings it back, so the fog never outlives its theme.
    final colors = AppMapColors.of(Theme.of(context).brightness);

    try {
      await widget.controller.addGeoJsonSource(
        FogLayer.veilSourceId,
        FogGeometry.veil(widget.holes),
      );
      await widget.controller.addGeoJsonSource(
        FogLayer.clearedSourceId,
        FogGeometry.clearedAreas(widget.holes),
      );
      await widget.controller.addGeoJsonSource(
        FogLayer.edgeSourceId,
        FogGeometry.clearedEdges(widget.holes),
      );

      await widget.controller.addFillLayer(
        FogLayer.veilSourceId,
        FogLayer.veilLayerId,
        FillLayerProperties(
          fillColor: MapStyle.hex(colors.fogVeil),
          fillOpacity: MapStyle.opacityOf(colors.fogVeil),
        ),
        // The veil covers the map and nothing on the map should be tappable
        // through it — but the markers are added above it, so this only stops
        // the fog itself from swallowing taps meant for the map.
        enableInteraction: false,
      );
      await widget.controller.addFillLayer(
        FogLayer.clearedSourceId,
        FogLayer.clearedLayerId,
        FillLayerProperties(
          fillColor: MapStyle.hex(colors.fogCleared),
          fillOpacity: MapStyle.opacityOf(colors.fogCleared),
        ),
        enableInteraction: false,
      );
      await widget.controller.addLineLayer(
        FogLayer.edgeSourceId,
        FogLayer.edgeLayerId,
        LineLayerProperties(
          lineColor: MapStyle.hex(colors.fogEdge),
          lineOpacity: MapStyle.opacityOf(colors.fogEdge),
          lineWidth: FogLayer.edgeWidth,
        ),
        enableInteraction: false,
      );
    } on Object {
      // A style that went away underneath us — theme switch, hot reload — is
      // not worth crashing a map screen for. The widget rebuilds with the new
      // style and installs again.
      return;
    }

    if (!mounted) return;
    _isInstalled = true;
    await _syncVisibility();
  }

  Future<void> _syncData() async {
    try {
      await widget.controller.setGeoJsonSource(
        FogLayer.veilSourceId,
        FogGeometry.veil(widget.holes),
      );
      await widget.controller.setGeoJsonSource(
        FogLayer.clearedSourceId,
        FogGeometry.clearedAreas(widget.holes),
      );
      await widget.controller.setGeoJsonSource(
        FogLayer.edgeSourceId,
        FogGeometry.clearedEdges(widget.holes),
      );
    } on Object {
      return;
    }
  }

  Future<void> _syncVisibility() async {
    try {
      await widget.controller.setLayerVisibility(
        FogLayer.veilLayerId,
        widget.isVisible,
      );
      await widget.controller.setLayerVisibility(
        FogLayer.clearedLayerId,
        widget.isVisible,
      );
      await widget.controller.setLayerVisibility(
        FogLayer.edgeLayerId,
        widget.isVisible,
      );
    } on Object {
      return;
    }
  }

  @override
  void dispose() {
    if (_isInstalled) {
      // Not awaited: dispose cannot be async, and the map is being torn down
      // either way. Failures here are the same non-event as above.
      widget.controller.removeLayer(FogLayer.veilLayerId).ignore();
      widget.controller.removeLayer(FogLayer.clearedLayerId).ignore();
      widget.controller.removeLayer(FogLayer.edgeLayerId).ignore();
      widget.controller.removeSource(FogLayer.veilSourceId).ignore();
      widget.controller.removeSource(FogLayer.clearedSourceId).ignore();
      widget.controller.removeSource(FogLayer.edgeSourceId).ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
