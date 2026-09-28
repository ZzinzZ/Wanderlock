/// Sticker geometry — docs/09-art-direction.md, section 0.
///
/// The sticker look is three numbers applied everywhere with discipline: how
/// thick the ink line is, how far the hard shadow drops, and how much a
/// sticker is allowed to lean. They are tokens for the same reason colours
/// are: a card outlined at 3 here and 2 there is the drift nobody reports and
/// everybody feels.
class AppSticker {
  const AppSticker._();

  /// Chips, labels, progress tracks — anything smaller than a thumb.
  static const double strokeThin = 2.5;

  /// Cards, buttons, markers. The default.
  static const double stroke = 3;

  /// The one primary action on screen, and the unlock plate.
  static const double strokeHeavy = 3.5;

  /// Hard shadow under a chip or a small control.
  static const double depthSmall = 3;

  /// Hard shadow under a card or a button.
  static const double depth = 4;

  /// Hard shadow under the primary action and the sheet.
  static const double depthLarge = 6;

  /// Hard shadow under the unlock plate — the object being handed over.
  static const double depthHero = 9;

  /// How far a selected lens chip rises out of its bar.
  static const double selectedLift = 6;

  /// Lean of a stamp, in radians. Alternated per tile so a grid reads as
  /// stuck in by hand rather than printed.
  static const double tilt = 0.03;

  /// Lean of the unlock plate.
  static const double heroTilt = -0.09;

  /// Perforation dashes inside a stamp.
  static const double perforationDash = 5;
  static const double perforationGap = 4;
  static const double perforationInset = 7;

  /// Spacing of the polka dots behind full-screen lenses.
  static const double patternSpacing = 20;
  static const double patternDotRadius = 2.6;
}
