import 'package:flutter/widgets.dart';

import 'package:wanderlock/design/tokens/app_colors.dart';
import 'package:wanderlock/design/tokens/app_sticker.dart';

/// Elevation tokens, from docs/09-art-direction.md section 5.
///
/// The one-line rule: **neumorphism for surfaces, solid blocks for actions.**
///
/// Neumorphism needs a flat, single-colour ground and controlled light. This
/// app is used outdoors and draws on top of a map, so the soft pair below is
/// banned on anything sitting directly on the map and on primary actions
/// (unlock, start quest) — those get a solid fill instead.
class AppShadows {
  const AppShadows._();

  /// Raised neumorphic surface: sheets, cards, icon tiles on a flat ground.
  /// Two shadows, applied together — the dark offset and the light offset are
  /// what make the surface read as extruded rather than merely dropped.
  static List<BoxShadow> raised(AppColors colors) => [
    BoxShadow(
      color: colors.neumorphicShadow,
      offset: const Offset(4, 4),
      blurRadius: 10,
    ),
    BoxShadow(
      color: colors.neumorphicHighlight,
      offset: const Offset(-4, -4),
      blurRadius: 10,
    ),
  ];

  /// Pressed-in surface, used for the stamp-in-paper effect on the collection
  /// screen. Same offsets, swapped, so a stamp reads as debossed.
  static List<BoxShadow> inset(AppColors colors) => [
    BoxShadow(
      color: colors.neumorphicHighlight,
      offset: const Offset(4, 4),
      blurRadius: 10,
    ),
    BoxShadow(
      color: colors.neumorphicShadow,
      offset: const Offset(-4, -4),
      blurRadius: 10,
    ),
  ];

  /// For anything drawn over the map, where a soft shadow would dissolve into
  /// a multicoloured background. Tight, dark, unambiguous.
  static List<BoxShadow> overMap(AppColors colors) => [
    BoxShadow(
      color: colors.neumorphicShadow,
      offset: const Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// The sticker shadow: solid ink, no blur, dropped straight down.
  ///
  /// Section 0 of the art direction. Unlike the soft pair above it survives
  /// on top of the map, because it does not depend on the ground being flat
  /// or evenly lit — it is a drawn line, not a lighting effect.
  static List<BoxShadow> sticker(
    AppColors colors, {
    double depth = AppSticker.depth,
  }) => [BoxShadow(color: colors.outline, offset: Offset(0, depth))];
}
