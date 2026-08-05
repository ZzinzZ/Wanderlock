import 'package:flutter/widgets.dart';

/// Colours for the map surface itself.
///
/// Kept apart from [AppColors] because they answer a different question. UI
/// colours are read per widget and animate between themes; these are baked
/// into a MapLibre style document once per theme and never interpolated.
///
/// Light values are transcribed from section 6 of docs/09-art-direction.md,
/// which fixes them exactly and bans the provider's default style.
@immutable
class AppMapColors {
  const AppMapColors({
    required this.land,
    required this.water,
    required this.green,
    required this.road,
    required this.roadCasing,
  });

  /// Ground with nothing else on it.
  final Color land;

  final Color water;

  /// Parks and tree cover.
  final Color green;

  /// Road fill.
  final Color road;

  /// The edge drawn under the fill, which is what makes a road read as drawn
  /// rather than as a flat ribbon.
  final Color roadCasing;

  static const light = AppMapColors(
    land: Color(0xFFF4F1EA),
    water: Color(0xFFCDE9F5),
    green: Color(0xFFDCEFD9),
    road: Color(0xFFFFFFFF),
    roadCasing: Color(0xFFE6E9EE),
  );

  /// Dark is **not** an inversion of light.
  ///
  /// Section 8 of the art direction is explicit that both themes get their own
  /// map, and that Fog is a mode rather than a theme — a user in light mode
  /// must never be thrown onto a black screen just because they opened the
  /// map.
  ///
  /// The art direction fixes only the page background for dark (`#14161C`).
  /// Water and green here are chosen: the same hues held at the light values'
  /// relationship to their ground, so the map reads as the same map at night.
  /// Flagged for sign-off alongside the other two dark choices.
  static const dark = AppMapColors(
    land: Color(0xFF14161C),
    water: Color(0xFF1B2A33),
    green: Color(0xFF1A2620),
    road: Color(0xFF2A2E38),
    roadCasing: Color(0xFF11131A),
  );

  static AppMapColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
