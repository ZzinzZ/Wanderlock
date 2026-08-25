import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// Draws the twelve checkpoints onto a live map, and reports taps.
///
/// Circles rather than photographs, for now. The art direction is firm that a
/// landmark is shown as a real photograph and never as an illustration, and
/// no photograph has cleared licensing yet — so this draws the honest thing,
/// a marked position, instead of a stand-in drawing that would have to be
/// unlearned later. [Checkpoint.photoUrl] is already carried end to end; the
/// day it is filled, a symbol layer replaces this file and nothing else moves.
///
/// The emulator settles the choice as well as the licence does: it renders no
/// symbol layer at all, so a marker made of an image would be invisible on
/// every machine that has no phone attached.
class CheckpointMarkerLayer extends StatefulWidget {
  const CheckpointMarkerLayer({
    required this.controller,
    required this.checkpoints,
    required this.visitedIds,
    this.onTap,
    super.key,
  });

  final MapLibreMapController controller;
  final List<Checkpoint> checkpoints;

  /// Which of them this user has unlocked. Passed in from `unlock` by the
  /// composition layer rather than read here, so the checkpoint feature keeps
  /// holding no opinion about unlock state.
  final Set<String> visitedIds;

  final void Function(Checkpoint checkpoint)? onTap;

  static const String sourceId = 'wanderlock-checkpoints';
  static const String haloLayerId = 'wanderlock-checkpoint-halo';
  static const String dotLayerId = 'wanderlock-checkpoint-dot';

  static const double dotRadius = 7;
  static const double haloRadius = 15;
  static const double dotStrokeWidth = 2.5;

  /// Property name shared with the paint expressions below.
  static const String visitedProperty = 'isVisited';
  static const String idProperty = 'checkpointId';

  @override
  State<CheckpointMarkerLayer> createState() => _CheckpointMarkerLayerState();
}

class _CheckpointMarkerLayerState extends State<CheckpointMarkerLayer> {
  bool _isInstalled = false;

  /// See the note on the fog layer: `didChangeDependencies` fires more than
  /// once, and adding a source twice is an error on the platform side.
  bool _hasStartedInstall = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onFeatureTapped.add(_onFeatureTapped);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: the marker colours come from the theme, and an
    // inherited widget read before initState completes throws.
    if (_hasStartedInstall) return;
    _hasStartedInstall = true;
    _install();
  }

  @override
  void didUpdateWidget(CheckpointMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInstalled) return;
    if (!identical(oldWidget.checkpoints, widget.checkpoints) ||
        !identical(oldWidget.visitedIds, widget.visitedIds)) {
      _syncData();
    }
  }

  void _onFeatureTapped(
    dynamic point,
    LatLng latLng,
    String? id,
    String? layerId,
    dynamic annotation,
  ) {
    final handler = widget.onTap;
    if (handler == null) return;
    if (layerId != CheckpointMarkerLayer.dotLayerId &&
        layerId != CheckpointMarkerLayer.haloLayerId) {
      return;
    }

    for (final checkpoint in widget.checkpoints) {
      if (checkpoint.id == id) {
        handler(checkpoint);
        return;
      }
    }
  }

  Map<String, Object?> _featureCollection() {
    return <String, Object?>{
      'type': 'FeatureCollection',
      'features': <Object?>[
        for (final checkpoint in widget.checkpoints)
          <String, Object?>{
            'type': 'Feature',
            // Feature-level id, which is what a tap comes back with.
            'id': checkpoint.id,
            'properties': <String, Object?>{
              CheckpointMarkerLayer.idProperty: checkpoint.id,
              CheckpointMarkerLayer.visitedProperty: widget.visitedIds.contains(
                checkpoint.id,
              ),
            },
            'geometry': <String, Object?>{
              'type': 'Point',
              'coordinates': <double>[
                checkpoint.longitude,
                checkpoint.latitude,
              ],
            },
          },
      ],
    };
  }

  Future<void> _install() async {
    final colors = AppColors.of(context);
    final visited = MapStyle.hex(colors.primary);
    final locked = MapStyle.hex(colors.coral);

    // `case` reads the property written above, so one layer paints both
    // states. Two layers filtered by state would drift apart the moment one
    // of them gained a property the other did not.
    final stateColor = <Object>[
      'case',
      <Object>['get', CheckpointMarkerLayer.visitedProperty],
      visited,
      locked,
    ];

    try {
      await widget.controller.addGeoJsonSource(
        CheckpointMarkerLayer.sourceId,
        _featureCollection(),
        promoteId: CheckpointMarkerLayer.idProperty,
      );

      // A soft disc under the dot. It is what makes a marker findable against
      // a busy street pattern without resorting to a drop shadow, which the
      // art direction bans on the map.
      await widget.controller.addCircleLayer(
        CheckpointMarkerLayer.sourceId,
        CheckpointMarkerLayer.haloLayerId,
        CircleLayerProperties(
          circleRadius: CheckpointMarkerLayer.haloRadius,
          circleColor: stateColor,
          circleOpacity: _haloOpacity,
        ),
      );
      await widget.controller.addCircleLayer(
        CheckpointMarkerLayer.sourceId,
        CheckpointMarkerLayer.dotLayerId,
        CircleLayerProperties(
          circleRadius: CheckpointMarkerLayer.dotRadius,
          circleColor: stateColor,
          circleStrokeWidth: CheckpointMarkerLayer.dotStrokeWidth,
          circleStrokeColor: MapStyle.hex(colors.card),
        ),
      );
    } on Object {
      return;
    }

    if (!mounted) return;
    _isInstalled = true;
  }

  Future<void> _syncData() async {
    try {
      await widget.controller.setGeoJsonSource(
        CheckpointMarkerLayer.sourceId,
        _featureCollection(),
      );
    } on Object {
      return;
    }
  }

  @override
  void dispose() {
    widget.controller.onFeatureTapped.remove(_onFeatureTapped);
    if (_isInstalled) {
      widget.controller.removeLayer(CheckpointMarkerLayer.haloLayerId).ignore();
      widget.controller.removeLayer(CheckpointMarkerLayer.dotLayerId).ignore();
      widget.controller.removeSource(CheckpointMarkerLayer.sourceId).ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Faint enough to read as a glow rather than a second circle.
const double _haloOpacity = 0.22;
