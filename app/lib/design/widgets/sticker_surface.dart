import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// A card that looks stuck onto the screen: ink outline, solid fill, hard
/// shadow dropped straight down.
///
/// The building block of the sticker look (docs/09-art-direction.md,
/// section 0). Unlike the neumorphic surface it replaced, it is allowed on
/// top of the map: an outline and a solid shadow do not need a flat, evenly
/// lit ground to read.
class StickerSurface extends StatelessWidget {
  const StickerSurface({
    required this.child,
    this.color,
    this.borderRadius = AppRadius.sticker,
    this.depth = AppSticker.depth,
    this.stroke = AppSticker.stroke,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.isPerforated = false,
    super.key,
  });

  final Widget child;

  /// Fill. Defaults to the card colour.
  final Color? color;
  final BorderRadius borderRadius;

  /// How far the hard shadow drops. Zero for a sticker lying flat, such as a
  /// pressed button.
  final double depth;
  final double stroke;
  final EdgeInsetsGeometry padding;

  /// Dashed line just inside the edge, like the perforation on a postage
  /// stamp. For stamps and the unlock plate, nowhere else.
  final bool isPerforated;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget content = Padding(padding: padding, child: child);
    if (isPerforated) {
      content = CustomPaint(
        painter: PerforationPainter(
          color: colors.outline,
          borderRadius: borderRadius,
        ),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: borderRadius,
        border: Border.all(color: colors.outline, width: stroke),
        boxShadow: depth > 0 ? AppShadows.sticker(colors, depth: depth) : null,
      ),
      child: content,
    );
  }
}

/// Draws the dashed perforation inside a stamp.
///
/// Flutter has no dashed border, and a dependency for one dashed rounded
/// rectangle would cost more than these lines.
class PerforationPainter extends CustomPainter {
  const PerforationPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppSticker.perforationInset;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final radius = (borderRadius.topLeft.x - inset).clamp(0.0, rect.width / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSticker.strokeThin * 0.8;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + AppSticker.perforationDash;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + AppSticker.perforationGap;
      }
    }
  }

  @override
  bool shouldRepaint(PerforationPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}
