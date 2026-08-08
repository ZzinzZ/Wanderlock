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
    required this.boundary,
    required this.label,
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
  ///
  /// The casing has to separate from the *land*, not only from the fill: it is
  /// the outline you see against the ground. The first values chosen missed
  /// this and were 1.08:1 against the land in light and 1.03:1 in dark, which
  /// is to say invisible — the roads read as flat ribbons exactly as the doc
  /// comment above promised they would not.
  final Color roadCasing;

  /// Administrative lines.
  ///
  /// Its own colour rather than a second use of [roadCasing]: a boundary drawn
  /// at road-casing strength reads as a street, which is the same mistake the
  /// road hierarchy had to undo for railways and ferry routes.
  final Color boundary;

  /// Road names — the only labels the map draws at all.
  ///
  /// Not [AppColors.inkMuted], though it started there. Section 2.3 of the art
  /// direction requires 4.5:1 for normal text, and the map labels are 11px
  /// over four different surfaces, so they need a colour picked against the
  /// map rather than against a card.
  final Color label;

  static const light = AppMapColors(
    land: Color(0xFFF4F1EA),
    water: Color(0xFFCDE9F5),
    green: Color(0xFFDCEFD9),
    road: Color(0xFFFFFFFF),
    // 1.56:1 against the white fill, 1.39:1 against the land.
    roadCasing: Color(0xFFC9CFDB),
    boundary: Color(0xFFE6E9EE),
    // The art direction's ink. `#6B7280` sat at 4.29:1 on the land, under the
    // 4.5:1 the same document demands.
    label: Color(0xFF1F2430),
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
    // Lighter than the road it sits under, where light's casing is darker.
    // The direction is not a free choice: in dark the road is already the
    // lighter of the two, so an edge drawn darker than the land disappears
    // into it. 1.58:1 against the fill, 2.10:1 against the land.
    roadCasing: Color(0xFF454C5B),
    boundary: Color(0xFF11131A),
    // Muted ink, unchanged: 7.11:1 on the land, already clear of 4.5:1. Dark
    // does not borrow light's answer, because it never had light's problem.
    label: Color(0xFF9AA3B2),
  );

  static AppMapColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
