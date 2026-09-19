import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/map/map_projection.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
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

  /// Which marker, if any, a tap on the map at this coordinate landed on.
  ///
  /// The markers ignore the pointer so the map can be dragged from anywhere,
  /// which leaves the map to report taps; this turns one back into a marker,
  /// using the same projection and the same marker geometry that drew it.
  /// When markers overlap, the one whose sticker is closest wins.
  static Checkpoint? checkpointAt({
    required CameraPosition camera,
    required Size size,
    required List<Checkpoint> checkpoints,
    required double latitude,
    required double longitude,
  }) {
    final projection = MapProjection(
      centerLatitude: camera.target.latitude,
      centerLongitude: camera.target.longitude,
      zoom: camera.zoom,
      widthPixels: size.width,
      heightPixels: size.height,
    );
    final tap = projection.toScreen(latitude, longitude);

    Checkpoint? best;
    var bestDistance = double.infinity;
    for (final checkpoint in checkpoints) {
      final at = projection.toScreen(checkpoint.latitude, checkpoint.longitude);
      final dx = tap.x - at.x;
      final dy = tap.y - at.y;
      final isInside =
          dx.abs() <= _CheckpointMarker.width / 2 &&
          dy >=
              -_CheckpointMarker.diameter / 2 -
                  _CheckpointMarker.badgeOverhang &&
          dy <= _CheckpointMarker.diameter / 2 + _CheckpointMarker.tagReach;
      if (!isInside) continue;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = checkpoint;
      }
    }
    return best;
  }

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
                  left: screen.x - _CheckpointMarker.width / 2,
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
            // IgnorePointer: every touch goes through to the map, so a drag
            // that starts on a marker still pans. A marker used to take the
            // pointer for its own tap and the map under it never moved.
            // Taps are resolved from the map instead — see [checkpointAt].
            return IgnorePointer(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(children: markers),
              ),
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

  /// The round sticker. The point on the map is its centre.
  static const double diameter = 64;

  /// The whole marker including its name tag, which is wider than the badge.
  static const double width = 104;

  /// How far the state badge hangs off the sticker's top-right edge.
  static const double badgeOverhang = 10;

  /// How far below the sticker the name tag reaches, for hit-testing: the gap
  /// plus two lines of tag text.
  static const double tagReach = 44;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Semantics keeps the tap for screen readers; a finger's tap reaches the
    // map instead and comes back through [CheckpointMarkerOverlay.checkpointAt].
    return Semantics(
      button: true,
      label: checkpoint.name,
      onTap: onTap == null ? null : () => onTap!(checkpoint),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: diameter,
              height: diameter,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // A sticker, not a pin: outline and hard shadow, the
                  // building drawn on it. Unlike the soft pair these survive
                  // on a multicoloured ground — section 0.
                  AnimatedContainer(
                    duration: AppMotion.standard,
                    curve: AppMotion.linearCurve,
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      color: isVisited
                          ? colors.highlightSurface
                          : colors.lockedSurface,
                      borderRadius: AppRadius.marker,
                      border: Border.all(
                        color: colors.outline,
                        width: AppSticker.stroke,
                      ),
                      boxShadow: AppShadows.sticker(colors),
                    ),
                    alignment: Alignment.center,
                    // Colour means reached, here as everywhere else.
                    child: LandmarkImage(
                      CheckpointIcons.landmarkOf(checkpoint),
                      size: AppIconSize.place - AppSpacing.xs,
                      isMuted: !isVisited,
                    ),
                  ),
                  Positioned(
                    right: -badgeOverhang,
                    top: -badgeOverhang,
                    child: AppIcon(
                      isVisited ? AppIcons.reward : AppIcons.locked,
                      size: AppIconSize.inline + AppSpacing.xs,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            _NameTag(name: checkpoint.name, isVisited: isVisited),
          ],
        ),
      ),
    );
  }
}

/// The name under a marker, on its own little sticker so it reads over any
/// street, park or river.
class _NameTag extends StatelessWidget {
  const _NameTag({required this.name, required this.isVisited});

  final String name;
  final bool isVisited;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isVisited ? colors.card : colors.surfaceMuted,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.strokeThin),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.tag.copyWith(color: colors.ink),
        ),
      ),
    );
  }
}
