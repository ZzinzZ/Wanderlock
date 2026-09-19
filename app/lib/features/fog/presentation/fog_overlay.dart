import 'dart:math' as math;
import 'dart:ui' as ui;

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
/// canvas can fade an edge; a style layer cannot.
///
/// How it looks organic: each hole is drawn as a main disc plus a few smaller
/// lobes pushed off-centre, all sized and placed from a hash of the hole's
/// own coordinates. The shape is irregular but stable — the same spot clears
/// the same way every frame and every launch — and every disc fades to fog
/// over a soft rim, so neighbouring clearings melt together.
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

    // The fog is drawn small and stretched to fit — the way strategy games do
    // theirs. The clearings are painted onto an image a quarter of the
    // screen's width and height, blurred there, and the image is drawn across
    // the whole screen with bilinear filtering.
    //
    // Three earlier versions were measured and dropped:
    // - a full-screen blur on every frame stuttered at any zoom;
    // - soft discs at full resolution were worse zoomed in, where one 160 m
    //   clearing is ~550 px across and every pixel was painted tens of times;
    // - soft discs at low resolution were fast, but a trail is dozens of
    //   overlapping discs whose fades multiply, so the rim came out hard.
    // One solid union, blurred once at a sixteenth of the pixels, avoids all
    // three.
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
      oldDelegate.projection.centerLatitude != projection.centerLatitude ||
      oldDelegate.projection.centerLongitude != projection.centerLongitude ||
      oldDelegate.projection.zoom != projection.zoom ||
      oldDelegate.projection.widthPixels != projection.widthPixels ||
      oldDelegate.projection.heightPixels != projection.heightPixels;
}
