import 'package:flutter/widgets.dart';

/// Colours for the map surface itself.
///
/// Apart from [AppColors] because they answer a different question: UI colours
/// are read per widget and animate between themes, while these are baked into
/// a MapLibre style document once per theme and never interpolated.
///
/// Values come from section 6 of docs/09-art-direction.md, which fixes them
/// exactly and bans the provider's default style.
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
  });

  /// Ground with nothing else on it.
  final Color land;

  final Color water;

  /// Parks and tree cover.
  final Color green;

  /// Road fill.
  final Color road;

  /// The edge under the fill, which makes a road read as drawn rather than as
  /// a flat ribbon. It has to separate from the *land*, not only from the
  /// fill: it is the outline seen against the ground.
  final Color roadCasing;

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

  /// Administrative lines. Its own colour rather than a second use of
  /// [roadCasing]: a boundary at road-casing strength reads as a street.
  final Color boundary;

  /// Road names — the only labels the map draws at all. Not
  /// [AppColors.inkMuted]: 11px text over four different map surfaces needs
  /// 4.5:1 against the map, not against a card.
  final Color label;

  /// The veil over everywhere the user has not been, in the Fog lens.
  ///
  /// **Dark in both themes** (owner, 2026-09-08). Unexplored city is genuinely
  /// dark and what you have visited is lit; that contrast is the whole lens,
  /// and a light-theme veil dissolved it — cream over cream measured one or
  /// two units in 255.
  ///
  /// Sheer enough that the street pattern still shows through: unexplored city
  /// must stay legible as a city, not become a black rectangle.
  final Color fogVeil;

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
  );

  /// Plum, like the outline ink: fog is the same night sky in both themes.
  static const Color _fogVeil = Color(0xDB3A2E5C);

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
  );

  static AppMapColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
