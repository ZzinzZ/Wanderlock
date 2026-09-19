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
    required this.roadMajor,
    required this.roadMajorCasing,
    required this.waterEdge,
    required this.greenEdge,
    required this.boundary,
    required this.label,
    required this.fogVeil,
    required this.fogEdge,
    required this.fogCleared,
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
  /// Fill of the biggest roads. Yellow in the sticker map, so the few roads
  /// that carry a name read as the spine of the city before any label does.
  final Color roadMajor;

  /// Edge of [roadMajor].
  final Color roadMajorCasing;

  /// Drawn outline round water — the cartoon map outlines its shapes the way
  /// the stickers on top of it are outlined.
  final Color waterEdge;

  /// Drawn outline round parks.
  final Color greenEdge;

  final Color boundary;

  /// Road names — the only labels the map draws at all.
  ///
  /// Not [AppColors.inkMuted], though it started there. Section 2.3 of the art
  /// direction requires 4.5:1 for normal text, and the map labels are 11px
  /// over four different surfaces, so they need a colour picked against the
  /// map rather than against a card.
  final Color label;

  /// The veil laid over everywhere the user has not been, in the Fog lens.
  ///
  /// **The veil is dark in both themes** — chosen by the project owner on
  /// 2026-09-08, reversing the earlier "fog is a mode, not a theme" rule. The
  /// mental model is a ward in a MOBA: unexplored city is genuinely dark, and
  /// what you have visited is lit. That contrast is the whole lens, and the
  /// light-theme version was dissolving it.
  ///
  /// The earlier rule was not merely too subtle, it was arithmetically empty:
  /// a cream veil at 60% over cream land measured (243,240,232) against
  /// (244,241,234) on a device — one or two units in 255. You cannot grey out
  /// a cream map by laying cream over it.
  ///
  /// Sheer enough that the street pattern still shows through: unexplored city
  /// must stay legible as a city, not become a black rectangle.
  final Color fogVeil;

  /// The rim around a cleared area.
  ///
  /// Without it a hole in the veil reads as a rendering glitch. With it, the
  /// cleared area reads as somewhere that was earned.
  final Color fogEdge;

  /// The wash laid *inside* a cleared area.
  ///
  /// "Light spreads": lifting a dark veil off the map is most of the effect,
  /// but the cleared ground is also warmed slightly so that where you have
  /// been reads as lit rather than merely as a gap. Kept low — the streets
  /// underneath have to stay streets, not become a pale patch.
  ///
  /// Now identical in both themes, because the veil above it is.
  final Color fogCleared;

  /// The cartoon map of the sticker pass (2026-09-19) — docs/09, section 0.
  /// Saturated water and grass with drawn edges, warm paper land, white
  /// streets with a tan casing and yellow boulevards.
  static const light = AppMapColors(
    land: Color(0xFFFBF0D5),
    water: Color(0xFF7FD6F2),
    green: Color(0xFF9BE08F),
    road: Color(0xFFFFFFFF),
    // 1.66:1 against the white fill, 1.45:1 against the land.
    roadCasing: Color(0xFFDCC697),
    roadMajor: Color(0xFFFFE08A),
    roadMajorCasing: Color(0xFFD9AE45),
    waterEdge: Color(0xFF2F9BEA),
    greenEdge: Color(0xFF4FAE55),
    boundary: Color(0xFFE9D9B4),
    // Dark brown ink. It has to clear 4.5:1 on the saturated water and grass
    // as well as on the paper, which rules out anything lighter.
    label: Color(0xFF3F3020),
    fogVeil: _fogVeil,
    fogEdge: _fogEdge,
    fogCleared: _fogCleared,
  );

  /// Plum, like the outline ink: fog is the same night sky in both themes.
  static const Color _fogVeil = Color(0xDB3A2E5C);

  static const Color _fogEdge = Color(0x88FFC93C);

  static const Color _fogCleared = Color(0x1FFBF0D5);

  static const dark = AppMapColors(
    land: Color(0xFF1E1A2E),
    water: Color(0xFF1F3A55),
    green: Color(0xFF1F3D2E),
    road: Color(0xFF3A3452),
    // Lighter than the road it sits under, where light's casing is darker:
    // in dark the road is already lighter than the land, so a darker edge
    // would vanish into the ground.
    roadCasing: Color(0xFF57507A),
    roadMajor: Color(0xFF5A4A2A),
    roadMajorCasing: Color(0xFF8A7440),
    waterEdge: Color(0xFF3A7BB8),
    greenEdge: Color(0xFF3F7A55),
    boundary: Color(0xFF15121F),
    label: Color(0xFFD9CFEA),
    fogVeil: _fogVeil,
    fogEdge: _fogEdge,
    fogCleared: _fogCleared,
  );

  static AppMapColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
