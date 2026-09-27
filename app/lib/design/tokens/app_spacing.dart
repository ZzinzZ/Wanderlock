/// Spacing scale.
///
/// The art direction asks for "large blocks, airy layout" without fixing a
/// scale, so this is a 4px base grid — small enough to be flexible, coarse
/// enough to stop arbitrary values creeping in.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Default horizontal page padding.
  static const double pageGutter = 20;

  /// Room to leave at the bottom of a lens for the lens switcher, which
  /// floats over every one of them.
  ///
  /// The bar is roughly 52dp tall and sits [lg] above the safe area. Three
  /// screens used to work this out for themselves and two of them landed on a
  /// different answer, so one of the three had the wrong gap — which is only
  /// visible on the last row of a full list.
  static const double aboveLensBar = xxl + xxl + xl;
}
