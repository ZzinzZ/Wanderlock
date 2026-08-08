import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:wanderlock/design/tokens/tokens.dart';

/// Builds the MapLibre style from design tokens.
///
/// Section 6 of docs/09-art-direction.md calls the map the easiest thing to
/// get wrong, and bans the provider's default style outright. A map that looks
/// like every other map undoes the rest of the art direction on the one
/// surface the user spends all their time on.
///
/// The style is generated rather than checked in as a static JSON file, for
/// two reasons. Colours stay in `design/tokens/` and cannot drift from the
/// rest of the app, and light and dark come from one definition instead of two
/// files that have to be kept in step by hand.
///
/// Targets the OpenMapTiles layer schema, which MapTiler, OpenFreeMap and
/// self-hosted tile servers all speak. Which provider to use is still open —
/// see docs/09-art-direction.md section 11.
abstract final class MapStyle {
  /// Source id every layer refers to. Must match the key in `sources`.
  static const _source = 'basemap';

  /// Labels are kept to a minimum: this app is not for wayfinding, and every
  /// label is ink competing with the checkpoints.
  static const _labelledRoadClasses = ['motorway', 'trunk', 'primary'];

  /// The road hierarchy, least important first.
  ///
  /// Order is paint order. Casings are drawn for every tier before any fill,
  /// so an alley crossing a boulevard cannot cut a notch out of the
  /// boulevard's edge; then fills run in the same order, which puts the bigger
  /// road on top where the two meet.
  ///
  /// [_RoadTier.classes] is an allow-list, and that is the point: the
  /// OpenMapTiles `transportation` layer also carries railways, ferry routes,
  /// piers and `*_construction` variants of every road class. Drawn with one
  /// undifferentiated layer they all became streets — a ferry route rendered
  /// exactly like Trần Hưng Đạo. Anything not named below is not a street and
  /// is not drawn as one.
  static const _roadTiers = <_RoadTier>[
    _RoadTier(
      id: 'path',
      classes: ['path', 'track'],
      width: 1,
      minZoom: 15,
      // A footpath has no edge to draw; a casing at this width would swallow
      // the fill entirely.
      hasCasing: false,
    ),
    _RoadTier(
      id: 'minor',
      classes: ['minor', 'service', 'busway'],
      width: 1.4,
      minZoom: 14,
    ),
    _RoadTier(id: 'tertiary', classes: ['tertiary'], width: 2.2, minZoom: 13),
    _RoadTier(id: 'secondary', classes: ['secondary'], width: 3, minZoom: 11),
    // The only tier drawn at every zoom: at city scale these are the whole
    // map, and below zoom 11 nothing else is legible anyway.
    _RoadTier(
      id: 'major',
      classes: ['motorway', 'trunk', 'primary'],
      width: 4.2,
      minZoom: 0,
    ),
  ];

  /// How much wider the casing is than the fill it sits under, in the same
  /// units as [_RoadTier.width]. Constant rather than proportional so the
  /// drawn edge stays the same visual weight across the hierarchy.
  static const _casingBleed = 1.6;

  /// A complete style document, ready to hand to MapLibre as a JSON string.
  ///
  /// [tilesUrl] is the vector tile endpoint; [glyphsUrl] serves the label
  /// fonts. Both are configuration rather than design, so they arrive from
  /// outside.
  static String toJson({
    required String tilesUrl,
    required String glyphsUrl,
    required Brightness brightness,
  }) {
    return jsonEncode(
      _document(
        tilesUrl: tilesUrl,
        glyphsUrl: glyphsUrl,
        brightness: brightness,
      ),
    );
  }

  static Map<String, Object?> _document({
    required String tilesUrl,
    required String glyphsUrl,
    required Brightness brightness,
  }) {
    final palette = AppMapColors.of(brightness);

    return {
      'version': 8,
      'name': 'Wanderlock ${brightness.name}',
      'glyphs': glyphsUrl,
      'sources': {
        _source: {'type': 'vector', 'url': tilesUrl},
      },
      'layers': [
        _fill('background', palette.land, isBackground: true),
        _sourceFill('water', 'water', palette.water),
        _sourceFill('landcover-green', 'landcover', palette.green),
        _sourceFill('park', 'park', palette.green),
        // Casing under the fill is what gives roads a drawn edge rather than a
        // flat ribbon. Every casing first, then every fill — see [_roadTiers].
        for (final tier in _roadTiers)
          if (tier.hasCasing)
            _roadLine(
              id: 'road-casing-${tier.id}',
              tier: tier,
              color: palette.roadCasing,
              width: tier.width + _casingBleed,
            ),
        for (final tier in _roadTiers)
          _roadLine(
            id: 'road-fill-${tier.id}',
            tier: tier,
            color: palette.road,
            width: tier.width,
          ),
        _line('boundary', 'boundary', palette.boundary, 1),
        _roadLabels(label: palette.label, halo: palette.land),
      ],
    };
  }

  static Map<String, Object?> _fill(
    String id,
    Color color, {
    bool isBackground = false,
  }) => {
    'id': id,
    'type': isBackground ? 'background' : 'fill',
    'paint': {isBackground ? 'background-color' : 'fill-color': _hex(color)},
  };

  static Map<String, Object?> _sourceFill(
    String id,
    String sourceLayer,
    Color color,
  ) => {
    'id': id,
    'type': 'fill',
    'source': _source,
    'source-layer': sourceLayer,
    'paint': {'fill-color': _hex(color), 'fill-antialias': true},
  };

  static Map<String, Object?> _line(
    String id,
    String sourceLayer,
    Color color,
    double width,
  ) => {
    'id': id,
    'type': 'line',
    'source': _source,
    'source-layer': sourceLayer,
    'layout': {'line-cap': 'round', 'line-join': 'round'},
    'paint': {'line-color': _hex(color), 'line-width': _zoomWidth(width)},
  };

  /// One rung of the hierarchy, filtered to its own `class` values.
  ///
  /// [_RoadTier.minZoom] is what keeps a dense city from turning into a grey
  /// mush when zoomed out: an alley that cannot be walked at this scale is not
  /// drawn at this scale.
  static Map<String, Object?> _roadLine({
    required String id,
    required _RoadTier tier,
    required Color color,
    required double width,
  }) => {
    'id': id,
    'type': 'line',
    'source': _source,
    'source-layer': 'transportation',
    if (tier.minZoom > 0) 'minzoom': tier.minZoom,
    'filter': [
      'in',
      ['get', 'class'],
      ['literal', tier.classes],
    ],
    'layout': {'line-cap': 'round', 'line-join': 'round'},
    'paint': {'line-color': _hex(color), 'line-width': _zoomWidth(width)},
  };

  /// Widths grow with zoom rather than staying fixed, so a street reads as a
  /// street at every scale instead of a hairline when zoomed out.
  static List<Object?> _zoomWidth(double width) => [
    'interpolate',
    ['linear'],
    ['zoom'],
    10,
    width * 0.3,
    16,
    width,
    20,
    width * 2.5,
  ];

  /// Only the biggest roads get a name. Everything else stays quiet.
  static Map<String, Object?> _roadLabels({
    required Color label,
    required Color halo,
  }) => {
    'id': 'road-label',
    'type': 'symbol',
    'source': _source,
    'source-layer': 'transportation_name',
    'filter': [
      'in',
      ['get', 'class'],
      ['literal', _labelledRoadClasses],
    ],
    'layout': {
      'symbol-placement': 'line',
      'text-field': ['get', 'name'],
      'text-font': ['Noto Sans Regular'],
      'text-size': 11,
    },
    'paint': {
      'text-color': _hex(label),
      'text-halo-color': _hex(halo),
      'text-halo-width': 1.2,
    },
  };

  static String _hex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }
}

/// A rung of the road hierarchy: which OpenMapTiles classes belong to it, how
/// wide it draws, and the scale below which it stops being worth drawing.
@immutable
class _RoadTier {
  const _RoadTier({
    required this.id,
    required this.classes,
    required this.width,
    required this.minZoom,
    this.hasCasing = true,
  });

  /// Suffix for the layer ids, so a style inspector names the tier.
  final String id;

  /// `transportation.class` values this tier claims. An allow-list.
  final List<String> classes;

  /// Fill width at zoom 16; other zooms interpolate from it.
  final double width;

  /// Below this the tier is not drawn at all. Zero means always.
  final int minZoom;

  /// Whether a casing is drawn under the fill.
  final bool hasCasing;
}
