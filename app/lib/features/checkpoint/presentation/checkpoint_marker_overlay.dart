import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/domain/map_projection.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_icons.dart';

/// The twelve places, drawn as Flutter widgets on top of the map.
///
/// **Why not a MapLibre symbol layer.** That was built first and is the
/// textbook answer: images registered with the style, one symbol layer, all of
/// it on the GPU. It also draws nothing on the emulator — verified twice now,
/// once in an earlier session against a control style and once here, where the
/// plates appeared and every icon was missing. A map whose markers cannot be
/// seen until a phone is plugged in cannot be designed, reviewed, or argued
/// about, and that cost more than the frames this saves.
///
/// It buys something as well: a marker is now an ordinary widget, so it can
/// animate, scale with its state, and use the same [AppIcon] as the rest of
/// the app rather than a separate copy of the artwork registered with a style.
///
/// The cost is real and bounded: twelve positions recomputed in Dart whenever
/// the camera moves. The arithmetic is [MapProjection] — no platform calls, no
/// awaits — and markers off screen are not built at all.
class CheckpointMarkerOverlay extends StatelessWidget {
  const CheckpointMarkerOverlay({
    required this.controller,
    required this.fallbackCamera,
    required this.checkpoints,
    required this.visitedIds,
    this.onTap,
    super.key,
  });

  final MapLibreMapController controller;

  /// Where to draw from before the controller has a camera of its own.
  ///
  /// It reports `null` until something moves the map, and nothing moves the
  /// map on a first launch — so without this the twelve markers appeared only
  /// after the user happened to pan, which is to say never, for anyone opening
  /// the app for the first time. Found by printing the camera, not by reading
  /// the code.
  final CameraPosition fallbackCamera;
  final List<Checkpoint> checkpoints;

  /// Which of them this user has unlocked. Passed in from `unlock` by the
  /// composition layer, so the checkpoint feature keeps holding no opinion
  /// about unlock state.
  final Set<String> visitedIds;

  final void Function(Checkpoint checkpoint)? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The controller is a ChangeNotifier that fires as the camera moves,
        // which is exactly the signal a widget overlay needs.
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final camera = controller.cameraPosition ?? fallbackCamera;

            final projection = MapProjection(
              centerLatitude: camera.target.latitude,
              centerLongitude: camera.target.longitude,
              zoom: camera.zoom,
              widthPixels: constraints.maxWidth,
              heightPixels: constraints.maxHeight,
            );

            final markers = <Widget>[];
            for (final checkpoint in checkpoints) {
              final screen = projection.toScreen(
                checkpoint.latitude,
                checkpoint.longitude,
              );
              if (!projection.isVisible(screen)) continue;

              markers.add(
                Positioned(
                  left: screen.x - _CheckpointMarker.diameter / 2,
                  top: screen.y - _CheckpointMarker.diameter / 2,
                  child: _CheckpointMarker(
                    checkpoint: checkpoint,
                    isVisited: visitedIds.contains(checkpoint.id),
                    onTap: onTap,
                  ),
                ),
              );
            }

            // Sized explicitly. A Stack holding nothing but Positioned
            // children collapses to zero under loose constraints, and every
            // marker is then laid out correctly and clipped away — which is
            // exactly how this first ran: no markers at all, no error.
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(children: markers),
            );
          },
        );
      },
    );
  }
}

class _CheckpointMarker extends StatelessWidget {
  const _CheckpointMarker({
    required this.checkpoint,
    required this.isVisited,
    this.onTap,
  });

  final Checkpoint checkpoint;
  final bool isVisited;
  final void Function(Checkpoint checkpoint)? onTap;

  static const double diameter = 60;
  static const double ringWidth = 3;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(checkpoint),
      child: Semantics(
        button: true,
        label: checkpoint.name,
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.linearCurve,
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.marker,
            // A flat ring, not a neumorphic pair. Section 10 bans the soft
            // shadow on anything sitting directly on the map, and a marker is
            // the most "directly on the map" thing there is: the ground under
            // it is a city, not a flat evenly lit surface.
            border: Border.all(
              color: isVisited ? colors.primary : colors.coral,
              width: ringWidth,
            ),
          ),
          alignment: Alignment.center,
          // Colour means reached, here as everywhere else.
          child: AppIcon(CheckpointIcons.of(checkpoint), isMuted: !isVisited),
        ),
      ),
    );
  }
}
