import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/map/map_projection.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/fog/domain/fog_hole.dart';

/// The fog of war, painted in Flutter over the map.
///
/// **Why not the MapLibre fill layer it replaced.** That drew the fog as a
/// polygon with circular holes, and a GL fill has no blur: every clearing was
/// a hard-edged disc. The owner asked for the fog of a strategy game instead —
/// clearings that bleed into each other with soft, uneven edges. A Flutter
/// canvas can blur; a style layer cannot.
///
/// How it looks organic: each hole is drawn as a main disc plus a few smaller
/// lobes pushed off-centre, all sized and placed from a hash of the hole's
/// own coordinates. The shape is irregular but stable — the same spot clears
/// the same way every frame and every launch — and the whole union is erased
/// through one blurred mask, so neighbouring clearings melt together.
///
/// Positioned with the same [MapProjection] as the markers, redrawn on every
/// camera frame, and holes off screen are not drawn.
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
                projection: MapProjection(
                  centerLatitude: camera.target.latitude,
                  centerLongitude: camera.target.longitude,
                  zoom: camera.zoom,
                  widthPixels: constraints.maxWidth,
                  heightPixels: constraints.maxHeight,
                ),
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

  /// Upper bound on the blur, in pixels. Cost grows with the sigma, and past
  /// this the edge reads as haze rather than as fog.
  static const double maxBlur = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = veil);

    final cleared = Path();
    var radiusSum = 0.0;
    var drawn = 0;

    for (final hole in holes) {
      final centre = projection.toScreen(hole.latitude, hole.longitude);
      final radius =
          hole.revealRadiusMeters / projection.metersPerPixel(hole.latitude);
      if (!projection.isVisible(centre, margin: radius * 1.6)) continue;

      _addBlob(cleared, Offset(centre.x, centre.y), radius, hole);
      radiusSum += radius;
      drawn++;
    }

    if (drawn > 0) {
      final sigma = (radiusSum / drawn * blurShare).clamp(1.0, maxBlur);
      canvas.drawPath(
        cleared,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }

    canvas.restore();
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
      final lobe = radius * (0.45 + random.nextDouble() * 0.25);
      path.addOval(
        Rect.fromCircle(
          center: centre + Offset(math.cos(angle), math.sin(angle)) * reach,
          radius: lobe,
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
      oldDelegate.projection.centerLatitude != projection.centerLatitude ||
      oldDelegate.projection.centerLongitude != projection.centerLongitude ||
      oldDelegate.projection.zoom != projection.zoom ||
      oldDelegate.projection.widthPixels != projection.widthPixels ||
      oldDelegate.projection.heightPixels != projection.heightPixels;
}
