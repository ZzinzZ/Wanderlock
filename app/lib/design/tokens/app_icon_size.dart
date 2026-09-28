/// Icon size scale.
///
/// The artwork is 400×400, so every size here is a downscale and none of them
/// will ever look soft. They are tokens rather than numbers at the call site
/// for the same reason colours are: an icon that is 22 in one place and 24 in
/// another is the kind of drift nobody reports and everybody feels.
///
/// **Raised across the board on 2026-08-25.** With the coloured fills gone,
/// the icons are the only thing left carrying colour, and at the old sizes
/// they read as labels beside text rather than as the subject. Everything here
/// went up by roughly half.
class AppIconSize {
  const AppIconSize._();

  /// Inline with a line of label text — a state marker beside a word.
  static const double inline = 24;

  /// Default: buttons, list rows, sheet actions.
  static const double action = 36;

  /// Lens switcher and other primary navigation.
  static const double navigation = 44;

  /// The centrepiece of a tile, such as a stamp in the collection.
  static const double tile = 72;

  /// A place on the map, and the header of a checkpoint sheet.
  static const double place = 56;

  /// The badge that drops into the collection during the unlock moment. The
  /// one place an icon is allowed to be the largest thing on screen.
  static const double celebration = 112;
}
