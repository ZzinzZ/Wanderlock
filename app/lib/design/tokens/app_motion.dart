import 'package:flutter/widgets.dart';

/// Motion tokens, from docs/09-art-direction.md section 9.
///
/// Everyday motion is soft with a little spring, 200–300ms. The unlock moment
/// is the single place allowed to go big.
class AppMotion {
  const AppMotion._();

  /// Small state changes: chips, toggles, ripples.
  static const Duration quick = Duration(milliseconds: 200);

  /// Default transition: sheets, cards, screen changes.
  static const Duration standard = Duration(milliseconds: 300);

  /// Lens switching. The map must morph in place; above this the switch stops
  /// feeling like the same map. DoD of F5 caps it at 300ms.
  static const Duration lensSwitch = Duration(milliseconds: 300);

  /// The three-second unlock moment. The one place motion may go all out.
  static const Duration unlockMoment = Duration(milliseconds: 3000);

  /// Scale a button shrinks to while pressed.
  static const double pressedScale = 0.96;

  /// Soft with a slight overshoot, the everyday feel.
  static const Curve standardCurve = Curves.easeOutBack;

  /// No overshoot, for anything that must not look bouncy — progress, maps.
  static const Curve linearCurve = Curves.easeInOut;
}
