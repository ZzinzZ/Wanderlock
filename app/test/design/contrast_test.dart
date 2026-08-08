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

/// The floor for a drawn edge on the map — a road casing, not text.
///
/// Deliberately not a WCAG number: WCAG has nothing to say about the outline
/// of a road, and holding one to 3:1 would give the map an ink border it was
/// never meant to have. This is the weaker claim that the first casings still
/// failed: that the edge is a different colour from what it sits on at all.
/// They measured 1.08:1 and 1.03:1, which is to say invisible.
const _visibleEdge = 1.3;

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

    // The map is a second palette on a second set of surfaces, and section 2.3
    // applies there too. Nothing checked it until the labels turned out to be
    // sitting at 4.29:1 on the land.
    for (final theme in <(String, AppMapColors)>[
      ('light', AppMapColors.light),
      ('dark', AppMapColors.dark),
    ]) {
      final (name, map) = theme;

      // A road name is placed along a road, so it crosses every surface the
      // map draws. The halo helps, but the halo is the land colour, so the
      // land is the case that has to hold on its own.
      test('$name map: road labels on every surface they can cross', () {
        for (final surface in <(String, Color)>[
          ('land', map.land),
          ('water', map.water),
          ('green', map.green),
          ('road', map.road),
        ]) {
          final (surfaceName, color) = surface;
          expect(
            contrastRatio(map.label, color),
            greaterThanOrEqualTo(_normalText),
            reason: '$name map: labels over $surfaceName',
          );
        }
      });

      // Both neighbours, because which side of the fill the casing sits on
      // differs by theme and only one of the two comparisons catches it. In
      // light the road is the brightest thing on the map and the edge goes
      // darker; in dark the road is brighter than the ground, so the edge has
      // to go the other way. The dark casing was drawn darker anyway, against
      // a land colour already close to black — 1.03:1, and only the land
      // comparison sees it.
      test('$name map: the road casing is visible against both neighbours', () {
        expect(
          contrastRatio(map.roadCasing, map.road),
          greaterThanOrEqualTo(_visibleEdge),
          reason: '$name map: casing vanishes into the road it outlines',
        );
        expect(
          contrastRatio(map.roadCasing, map.land),
          greaterThanOrEqualTo(_visibleEdge),
          reason: '$name map: casing vanishes into the ground',
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
