import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/map/camera_projection.dart';
import 'package:wanderlock/core/map/map_projection.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';

/// The fog of war, painted in Flutter over the map.
///
/// **Not a MapLibre fill layer**, which is what it replaced: a GL fill has no
/// blur, so every clearing was a hard-edged disc. The owner asked for the fog
/// of a strategy game — clearings that bleed into each other.
///
/// Each hole is a main disc plus a few lobes pushed off-centre, sized and
/// placed from a hash of the hole's own coordinates, so the shape is irregular
/// but stable across frames and launches.
///
/// Uses the same [MapProjection] as the markers; holes off screen are skipped.
class FogOverlay extends StatelessWidget {
  const FogOverlay({
    required this.controller,
    required this.fallbackCamera,
    required this.holes,
    super.key,
  });

  final MapLibreMapController controller;

  /// Where to draw from before the controller reports a camera of its own.
  final CameraPosition fallbackCamera;

  final List<FogHole> holes;

  @override
  Widget build(BuildContext context) {
    final colors = AppMapColors.of(Theme.of(context).brightness);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final camera = controller.cameraPosition ?? fallbackCamera;
            return CustomPaint(
              size: constraints.biggest,
              painter: _FogPainter(
                projection: camera.projectionOver(constraints.biggest),
                holes: holes,
                veil: colors.fogVeil,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  _FogPainter({
    required this.projection,
    required this.holes,
    required this.veil,
  });

  final MapProjection projection;
  final List<FogHole> holes;
  final Color veil;

  /// Lobes round each disc. Three is enough to break the circle without the
  /// edge turning into a flower.
  static const int lobes = 3;

  /// Softness of the edge, as a share of the typical clearing's radius.
  static const double blurShare = 0.35;

  /// Bounds on the blur, in logical pixels of the screen. Below the minimum
  /// the stretched edge shows the small image's pixels; above the maximum it
  /// reads as haze rather than as the edge of fog.
  static const double minimumBlur = 6;
  static const double maximumBlur = 48;

  /// Two clearings whose centres fall this close on screen, as a share of the
  /// radius, are drawn once. Zoomed out, a long trail puts dozens of points on
  /// top of each other and every one of them was being painted.
  static const double mergeShare = 0.4;

  /// Below this a clearing is too small to see and is not drawn.
  static const double minimumRadius = 2;

  /// The fog image's size as a share of the screen's, per side. A quarter is
  /// small enough that painting it is cheap at any zoom, and large enough
  /// that, stretched with bilinear filtering, the edge reads as soft fog
  /// rather than as blocks.
  static const double resolution = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    // Drawn small and stretched to fit, the way strategy games do theirs: one
    // solid union of clearings, blurred once at a sixteenth of the pixels.
    //
    // Measured and rejected: a full-screen blur per frame stutters at any
    // zoom; soft discs at full resolution are worse zoomed in; soft discs at
    // low resolution are fast but their fades multiply into a hard rim.
    final width = math.max(1, (size.width * resolution).ceil());
    final height = math.max(1, (size.height * resolution).ceil());

    final cleared = Path();
    final occupied = <int>{};
    var radiusSum = 0.0;
    var drawn = 0;
    for (final hole in holes) {
      final radius =
          hole.revealRadiusMeters / projection.metersPerPixel(hole.latitude);
      if (radius < minimumRadius) continue;

      final centre = projection.toScreen(hole.latitude, hole.longitude);
      if (!projection.isVisible(centre, margin: radius * 1.6)) continue;

      final cell = math.max(radius * mergeShare, minimumRadius);
      final key = Object.hash(
        (centre.x / cell).floor(),
        (centre.y / cell).floor(),
        cell.round(),
      );
      if (!occupied.add(key)) continue;

      _addBlob(cleared, Offset(centre.x, centre.y), radius, hole);
      radiusSum += radius;
      drawn++;
    }

    final recorder = ui.PictureRecorder();
    final fog = Canvas(recorder)..scale(resolution);
    fog.drawRect(bounds, Paint()..color = veil);
    if (drawn > 0) {
      // A mask blur on the path itself. A blur on a save layer was tried
      // first and is silently dropped when the layer also erases (dstOut) —
      // the edge came out one stretched pixel wide. Sigma is in the same
      // units as the path, before the scale, like every other length here.
      final sigma = (radiusSum / drawn * blurShare).clamp(
        minimumBlur,
        maximumBlur,
      );
      fog.drawPath(
        cleared,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bounds,
      Paint()..filterQuality = FilterQuality.medium,
    );
    image.dispose();
    picture.dispose();
  }

  /// One irregular clearing: a jittered disc and a few lobes, all derived
  /// from the hole's coordinates so the shape never flickers.
  void _addBlob(Path path, Offset centre, double radius, FogHole hole) {
    final random = math.Random(_seed(hole));
    final core = radius * (0.82 + random.nextDouble() * 0.16);
    path.addOval(Rect.fromCircle(center: centre, radius: core));

    final turn = random.nextDouble() * 2 * math.pi;
    for (var i = 0; i < lobes; i++) {
      final angle = turn + i * 2 * math.pi / lobes + random.nextDouble() * 0.9;
      final reach = radius * (0.35 + random.nextDouble() * 0.3);
      path.addOval(
        Rect.fromCircle(
          center: centre + Offset(math.cos(angle), math.sin(angle)) * reach,
          radius: radius * (0.45 + random.nextDouble() * 0.25),
        ),
      );
    }
  }

  static int _seed(FogHole hole) =>
      ((hole.latitude * 1e5).round() * 73856093) ^
      ((hole.longitude * 1e5).round() * 19349663);

  @override
  bool shouldRepaint(_FogPainter oldDelegate) =>
      !identical(oldDelegate.holes, holes) ||
      oldDelegate.veil != veil ||
      oldDelegate.projection != projection;
}
