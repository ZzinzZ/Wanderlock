import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/player_dot.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';

/// Page one: a patch of city cleared out of the fog around the explorer.
class FogArt extends StatelessWidget {
  const FogArt({super.key});

  static const double side = 232;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final map = AppMapColors.of(Theme.of(context).brightness);

    return Transform.rotate(
      angle: -AppSticker.tilt * 2,
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.hero,
                  border: Border.all(
                    color: colors.outline,
                    width: AppSticker.strokeHeavy,
                  ),
                  boxShadow: AppShadows.sticker(
                    colors,
                    depth: AppSticker.depthLarge,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.sticker,
                  child: CustomPaint(painter: _FogArtPainter(map: map)),
                ),
              ),
            ),
            const Center(child: PlayerDot(hasShadow: false)),
            const Positioned(
              right: -AppSpacing.md,
              top: -AppSpacing.md,
              child: AppIcon(AppIcons.lensJourney, size: AppIconSize.tile),
            ),
          ],
        ),
      ),
    );
  }
}

/// A little cartoon map: paper, a river, two roads, under fog with a soft
/// clearing — the same look as the real fog lens.
class _FogArtPainter extends CustomPainter {
  const _FogArtPainter({required this.map});

  final AppMapColors map;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = map.land);

    final river = Path()
      ..moveTo(w * 0.72, -4)
      ..cubicTo(w * 0.55, h * 0.35, w * 0.95, h * 0.6, w * 0.7, h + 4)
      ..lineTo(w * 0.9, h + 4)
      ..cubicTo(w * 1.1, h * 0.6, w * 0.7, h * 0.35, w * 0.88, -4)
      ..close();
    canvas.drawPath(river, Paint()..color = map.water);

    final casing = Paint()
      ..color = map.roadMajorCasing
      ..strokeWidth = AppSpacing.md - 2
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = map.roadMajor
      ..strokeWidth = AppSpacing.sm + 2
      ..style = PaintingStyle.stroke;
    for (final (from, to) in [
      (Offset(-4, h * 0.3), Offset(w + 4, h * 0.62)),
      (Offset(w * 0.3, -4), Offset(w * 0.42, h + 4)),
    ]) {
      canvas.drawLine(from, to, casing);
      canvas.drawLine(from, to, road);
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = map.fogVeil);
    final clearing = Path()
      ..addOval(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.26))
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.34, h * 0.36), radius: w * 0.16),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.64, h * 0.62), radius: w * 0.15),
      );
    canvas.drawPath(
      clearing,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FogArtPainter oldDelegate) => oldDelegate.map != map;
}

/// Page two: a place still locked, with the radius you have to stand in.
class UnlockArt extends StatelessWidget {
  const UnlockArt({super.key});

  static const double ring = 236;
  static const double badge = 132;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The radius, drawn as a dashed ring on a tinted disc.
          Container(
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              color: colors.infoSurface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: PerforationPainter(
                color: colors.info,
                borderRadius: const BorderRadius.all(Radius.circular(ring / 2)),
              ),
            ),
          ),
          Container(
            width: badge,
            height: badge,
            decoration: BoxDecoration(
              color: colors.lockedSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.outline,
                width: AppSticker.strokeHeavy,
              ),
              boxShadow: AppShadows.sticker(
                colors,
                depth: AppSticker.depthLarge,
              ),
            ),
            alignment: Alignment.center,
            child: const LandmarkImage(
              LandmarkArt.market,
              size: AppIconSize.celebration,
              isMuted: true,
            ),
          ),
          const Positioned(
            right: AppSpacing.lg,
            top: AppSpacing.md,
            child: AppIcon(AppIcons.locked, size: AppIconSize.tile),
          ),
          const Positioned(
            left: 0,
            bottom: AppSpacing.md,
            child: AppIcon(AppIcons.unlock, size: AppIconSize.tile),
          ),
        ],
      ),
    );
  }
}

/// Page three: the three lenses, fanned like stamps, all lit by one arrival.
class LensesArt extends StatelessWidget {
  const LensesArt({super.key});

  static const double stamp = 104;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget stampOf(String icon, Color fill, double angle) => Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: stamp,
        height: stamp * 1.2,
        child: StickerSurface(
          color: fill,
          borderRadius: AppRadius.chip,
          depth: AppSticker.depth + 1,
          isPerforated: true,
          padding: EdgeInsets.zero,
          child: Center(child: AppIcon(icon, size: AppIconSize.tile)),
        ),
      ),
    );

    return SizedBox(
      width: stamp * 3,
      height: stamp * 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: stamp * 0.45,
            child: stampOf(AppIcons.lensMap, colors.infoSurface, -math.pi / 14),
          ),
          Positioned(
            right: 0,
            top: stamp * 0.45,
            child: stampOf(
              AppIcons.lensJourney,
              colors.decorativeMint,
              math.pi / 14,
            ),
          ),
          Positioned(
            top: stamp * 0.2,
            child: stampOf(AppIcons.lensCollection, colors.highlightSurface, 0),
          ),
          const Positioned(
            top: -AppSpacing.sm,
            right: AppSpacing.xl,
            child: AppIcon(AppIcons.reward, size: AppIconSize.place),
          ),
        ],
      ),
    );
  }
}
