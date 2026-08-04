import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/design/tokens/tokens.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio, 1.0 (identical) to 21.0 (black on white).
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Normal text threshold from the art direction's colour rules.
const _normalText = 4.5;

/// Large text threshold.
const _largeText = 3.0;

void main() {
  group('contrast', () {
    // Definition of Done for F1: "primary buttons and text on coloured
    // backgrounds are all >= 4.5:1". Checked here rather than by eye, because
    // a pastel-on-pastel pairing is exactly the mistake that survives review.
    for (final theme in <(String, AppColors)>[
      ('light', AppColors.light),
      ('dark', AppColors.dark),
    ]) {
      final (name, colors) = theme;

      test('$name: body text on the page background', () {
        expect(
          contrastRatio(colors.ink, colors.background),
          greaterThanOrEqualTo(_normalText),
        );
      });

      test('$name: body text on a card', () {
        expect(
          contrastRatio(colors.ink, colors.card),
          greaterThanOrEqualTo(_normalText),
        );
      });

      test('$name: muted text on the page background', () {
        expect(
          contrastRatio(colors.inkMuted, colors.background),
          greaterThanOrEqualTo(_normalText),
        );
      });

      test('$name: label on the primary action', () {
        expect(
          contrastRatio(colors.onPrimaryAction, colors.primaryAction),
          greaterThanOrEqualTo(_normalText),
        );
      });

      test('$name: label on the yellow accent', () {
        expect(
          contrastRatio(colors.onAccentYellow, colors.accentYellow),
          greaterThanOrEqualTo(_normalText),
        );
      });

      test('$name: label on coral', () {
        expect(
          contrastRatio(colors.onCoral, colors.coral),
          greaterThanOrEqualTo(_normalText),
        );
      });
    }

    // This is the reason the palette carries two greens. If this ever passes,
    // someone has changed `primary` and the separate action colour has quietly
    // become pointless -- at which point the art direction needs revisiting,
    // not the test.
    test('brand green cannot carry white text, which is why an action '
        'green exists', () {
      final ratio = contrastRatio(
        AppColors.light.onPrimaryAction,
        AppColors.light.primary,
      );
      expect(ratio, lessThan(_largeText));
    });
  });
}
