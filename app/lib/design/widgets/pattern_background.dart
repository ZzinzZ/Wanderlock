import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// The polka-dot ground behind the full-screen lenses.
///
/// Texture, not decoration with meaning: it tells the user they have left
/// the map for a page of the game, the way a sticker album has a printed
/// backing sheet.
class PatternBackground extends StatelessWidget {
  const PatternBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Thousands of dots: drawn once, cached, and kept out of the child's
    // repaints by the boundary.
    return CustomPaint(
      painter: _DotPainter(
        ground: colors.patternGround,
        dot: colors.patternDot,
      ),
      isComplex: true,
      child: RepaintBoundary(child: child),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter({required this.ground, required this.dot});

  final Color ground;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);

    final paint = Paint()..color = dot;
    const step = AppSticker.patternSpacing;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), AppSticker.patternDotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) =>
      oldDelegate.ground != ground || oldDelegate.dot != dot;
}
