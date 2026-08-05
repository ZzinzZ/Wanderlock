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
    final label = brightness == Brightness.dark
        ? AppColors.dark.inkMuted
        : AppColors.light.inkMuted;

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
        // Casing under the fill is what gives roads a drawn edge rather than
        // a flat ribbon. Two layers, wider one underneath.
        _line('road-casing', 'transportation', palette.roadCasing, 5),
        _line('road-fill', 'transportation', palette.road, 3),
        _line('boundary', 'boundary', palette.roadCasing, 1),
        _roadLabels(label: label, halo: palette.land),
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
    'paint': {
      'line-color': _hex(color),
      // Widths grow with zoom rather than staying fixed, so a street reads as
      // a street at every scale instead of a hairline when zoomed out.
      'line-width': [
        'interpolate',
        ['linear'],
        ['zoom'],
        10,
        width * 0.3,
        16,
        width,
        20,
        width * 2.5,
      ],
    },
  };

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
