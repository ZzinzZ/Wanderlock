import 'package:flutter/widgets.dart';

/// Type tokens, from docs/09-art-direction.md section 3.
///
/// Both families are bundled under `assets/fonts/`, never fetched at runtime:
/// the app has to work offline, and a first launch without a network would
/// otherwise fall back to a system font and break every layout.
class AppTypography {
  const AppTypography._();

  /// UI, body and buttons. Designed in Vietnam, so Vietnamese diacritics are
  /// the first concern rather than an afterthought.
  static const String uiFamily = 'BeVietnamPro';

  /// Large headings, scores and badges. Rounded, to match the clay
  /// illustration style.
  static const String displayFamily = 'Baloo2';

  /// Baloo 2 ships from google/fonts as a variable font with no static
  /// instances, so weight is selected on the `wght` axis. [FontWeight] is set
  /// as well so the correct weight still resolves if the axis is unavailable.
  static List<FontVariation> _wght(double value) => [
    FontVariation('wght', value),
  ];

  /// Screen title: 24 / 600.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: uiFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Card title: 17 / 600.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: uiFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// Body: 15 / 400, line height 1.6.
  static const TextStyle body = TextStyle(
    fontFamily: uiFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Secondary label: 13 / 400.
  static const TextStyle label = TextStyle(
    fontFamily: uiFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Button text. Pills carry medium weight so the label holds its own
  /// against a solid fill.
  static const TextStyle button = TextStyle(
    fontFamily: uiFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Figures, distances and coordinates: tabular so digits stop jittering as
  /// values update, right-aligned at the call site.
  static const TextStyle numeric = TextStyle(
    fontFamily: uiFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large display heading in Baloo 2.
  static TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontVariations: _wght(700),
    height: 1.2,
  );

  /// Weights bundled for the UI family. Drives the diacritics check, which
  /// has to cover every weight actually shipped — stacked marks usually break
  /// first at the heavy end.
  static const List<FontWeight> uiWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

  /// Weights exercised on the display family's variable `wght` axis.
  static const List<double> displayWeights = [400, 500, 600, 700, 800];

  /// One specimen line of the UI family, for the diacritics check.
  static TextStyle specimenUi(FontWeight weight) =>
      TextStyle(fontFamily: uiFamily, fontSize: 22, fontWeight: weight);

  /// One specimen line of the display family, for the diacritics check.
  static TextStyle specimenDisplay(double weight) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: _wght(weight),
  );

  /// Badge or score numerals in Baloo 2.
  static TextStyle badge = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontVariations: _wght(800),
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
