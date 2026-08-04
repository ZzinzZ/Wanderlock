import 'package:flutter/widgets.dart';

/// Corner radius tokens, from docs/09-art-direction.md section 4.
///
/// "No square corners anywhere, except the map surface itself."
class AppRadius {
  const AppRadius._();

  /// Buttons are pills. Large enough that any button height stays fully round.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  /// Cards.
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));

  /// Bottom sheets: top two corners only.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(28),
  );

  /// Chips and small tiles.
  static const BorderRadius chip = BorderRadius.all(Radius.circular(16));

  /// Map markers are fully round; use with a square box.
  static const BorderRadius marker = BorderRadius.all(Radius.circular(999));
}
