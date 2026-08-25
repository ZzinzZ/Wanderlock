/// Icon size scale.
///
/// The clay icons are 400×400 source images, so every size here is a
/// downscale and none of them will ever look soft. They are tokens rather than
/// numbers at the call site for the same reason colours are: an icon that is
/// 22 in one place and 24 in another is the kind of drift nobody reports and
/// everybody feels.
class AppIconSize {
  const AppIconSize._();

  /// Inline with a line of label text — a state marker beside a word.
  static const double inline = 20;

  /// Default: buttons, list rows, sheet actions.
  static const double action = 28;

  /// Lens switcher and other primary navigation.
  static const double navigation = 32;

  /// The centrepiece of a tile, such as a stamp in the collection.
  static const double tile = 44;

  /// The badge that drops into the collection during the unlock moment. The
  /// one place an icon is allowed to be the largest thing on screen.
  static const double celebration = 72;
}
