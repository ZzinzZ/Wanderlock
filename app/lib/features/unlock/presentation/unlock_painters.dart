import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Beat 1 — the colour, flooding out from where the user stands.
class FloodPainter extends CustomPainter {
  const FloodPainter({
    required this.progress,
    required this.origin,
    required this.colour,
  });

  final double progress;
  final Alignment origin;
  final Color colour;

  /// How solid the flood gets. Full opacity would hide the map it is
  /// celebrating.
  static const double peakOpacity = 0.92;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final centre = origin.alongSize(size);
    // Far corner, so the disc always finishes off-screen rather than stopping
    // as a visible circle.
    final reach = math.sqrt(
      size.width * size.width + size.height * size.height,
    );

    canvas.drawCircle(
      centre,
      reach * progress,
      Paint()..color = colour.withValues(alpha: peakOpacity * progress),
    );
  }

  @override
  bool shouldRepaint(FloodPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.origin != origin ||
      oldDelegate.colour != colour;
}

/// Alternating wedges of a lighter pink, turning slowly behind the plate.
class RayPainter extends CustomPainter {
  const RayPainter({
    required this.turn,
    required this.opacity,
    required this.colour,
  });

  /// 0 to 1 over the three seconds.
  final double turn;
  final double opacity;
  final Color colour;

  static const int rays = 20;

  /// How far the rays turn over the whole moment, in radians.
  static const double sweep = math.pi / 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final centre = Offset(size.width / 2, size.height * 0.42);
    final reach = size.longestSide;
    final paint = Paint()..color = colour.withValues(alpha: opacity * colour.a);
    const wedge = math.pi / rays;

    for (var i = 0; i < rays; i++) {
      final start = i * 2 * wedge + turn * sweep;
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(
          centre.dx + reach * math.cos(start),
          centre.dy + reach * math.sin(start),
        )
        ..lineTo(
          centre.dx + reach * math.cos(start + wedge),
          centre.dy + reach * math.sin(start + wedge),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(RayPainter oldDelegate) =>
      oldDelegate.turn != turn ||
      oldDelegate.opacity != opacity ||
      oldDelegate.colour != colour;
}
