import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/design/tokens/tokens.dart';

Map<String, Object?> _style(Brightness brightness) =>
    jsonDecode(
          MapStyle.toJson(
            tilesUrl: 'https://tiles.example.test/tiles.json',
            glyphsUrl: 'https://tiles.example.test/fonts/{fontstack}/{range}',
            brightness: brightness,
          ),
        )
        as Map<String, Object?>;

List<Map<String, Object?>> _layers(Map<String, Object?> style) =>
    (style['layers']! as List<Object?>).cast<Map<String, Object?>>();

Map<String, Object?> _layer(Map<String, Object?> style, String id) =>
    _layers(style).firstWhere((layer) => layer['id'] == id);

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// The width a line layer draws at zoom 16, pulled back out of the
/// `interpolate` expression its stops are written into.
double _widthAtZoom16(Map<String, Object?> layer) {
  final width = (layer['paint']! as Map)['line-width']! as List<Object?>;
  final zoom16 = width.indexOf(16);
  expect(zoom16, greaterThan(0), reason: 'no zoom-16 stop in ${layer['id']}');
  return (width[zoom16 + 1]! as num).toDouble();
}

/// The `class` values a road layer claims, read off its filter.
List<Object?> _classes(Map<String, Object?> layer) {
  final filter = layer['filter']! as List<Object?>;
  return (filter.last as List<Object?>).last as List<Object?>;
}

List<Map<String, Object?>> _roadLayers(
  Map<String, Object?> style,
  String prefix,
) => _layers(
  style,
).where((l) => (l['id']! as String).startsWith(prefix)).toList();

/// Ordered least to most important — the same order the style paints them.
const _tierIds = ['path', 'minor', 'tertiary', 'secondary', 'major'];

void main() {
  test('is a valid style document with a source every layer can use', () {
    final style = _style(Brightness.light);

    expect(style['version'], 8);
    final sources = style['sources']! as Map<String, Object?>;
    expect(sources.keys, hasLength(1));

    final sourceId = sources.keys.single;
    for (final layer in _layers(style)) {
      if (layer['type'] == 'background') continue;
      expect(
        layer['source'],
        sourceId,
        reason: 'layer ${layer['id']} points at a source that does not exist',
      );
    }
  });

  // The exact values the art direction fixes. If someone changes these, they
  // are changing the art direction and should be doing it there.
  test('light map uses the colours the art direction fixes', () {
    final style = _style(Brightness.light);

    expect(
      (_layer(style, 'background')['paint']! as Map)['background-color'],
      _hex(AppMapColors.light.land),
    );
    expect(
      (_layer(style, 'water')['paint']! as Map)['fill-color'],
      _hex(AppMapColors.light.water),
    );
    expect(
      (_layer(style, 'park')['paint']! as Map)['fill-color'],
      _hex(AppMapColors.light.green),
    );
    for (final layer in _roadLayers(style, 'road-fill-')) {
      expect(
        (layer['paint']! as Map)['line-color'],
        _hex(AppMapColors.light.road),
        reason: '${layer['id']} is off palette',
      );
    }
    for (final layer in _roadLayers(style, 'road-casing-')) {
      expect(
        (layer['paint']! as Map)['line-color'],
        _hex(AppMapColors.light.roadCasing),
        reason: '${layer['id']} is off palette',
      );
    }
  });

  // Section 8: both themes get their own map. An inverted light map would be
  // a different bug wearing the same clothes.
  test('dark is a separate map, not an inversion of light', () {
    final light = _style(Brightness.light);
    final dark = _style(Brightness.dark);

    for (final id in ['background', 'water', 'park', 'road-fill-major']) {
      final lightPaint = _layer(light, id)['paint']! as Map;
      final darkPaint = _layer(dark, id)['paint']! as Map;
      expect(
        darkPaint.values.first,
        isNot(lightPaint.values.first),
        reason: '$id is identical in both themes',
      );
    }

    expect(
      (_layer(dark, 'background')['paint']! as Map)['background-color'],
      _hex(AppMapColors.dark.land),
    );
  });

  // "Reduce labels to a minimum: this app is not used for directions."
  test('only the largest roads carry a name', () {
    final style = _style(Brightness.light);
    final symbolLayers = _layers(
      style,
    ).where((layer) => layer['type'] == 'symbol').toList();

    expect(symbolLayers, hasLength(1));

    final filter = symbolLayers.single['filter']! as List<Object?>;
    final classes = (filter.last as List<Object?>).last as List<Object?>;
    expect(classes, ['motorway', 'trunk', 'primary']);
  });

  // Road casing has to be drawn under the fill or it is not a casing. Every
  // casing goes under every fill, so a lane crossing a boulevard cannot cut a
  // notch out of the boulevard's edge.
  test('every road casing sits beneath every road fill', () {
    final ids = _layers(
      _style(Brightness.light),
    ).map((l) => l['id']! as String).toList();

    final lastCasing = ids.lastIndexWhere(
      (id) => id.startsWith('road-casing-'),
    );
    final firstFill = ids.indexWhere((id) => id.startsWith('road-fill-'));

    expect(lastCasing, greaterThan(-1));
    expect(firstFill, greaterThan(-1));
    expect(lastCasing, lessThan(firstFill));
  });

  // The whole point of the tiers. Without this a boulevard draws exactly like
  // an alley, and the map reads as an undifferentiated mesh.
  test('a more important road draws wider than a less important one', () {
    final style = _style(Brightness.light);

    final widths = [
      for (final tier in _tierIds)
        _widthAtZoom16(_layer(style, 'road-fill-$tier')),
    ];

    expect(
      widths,
      orderedEquals(List<double>.from(widths)..sort()),
      reason: 'tier widths $widths are not strictly ordered $_tierIds',
    );
    expect(widths.toSet(), hasLength(widths.length), reason: 'two tiers tie');
  });

  // The paint order has to match the importance order too, or the wider road
  // ends up underneath at the junction.
  test('road tiers are painted least important first', () {
    final ids = _layers(
      _style(Brightness.light),
    ).map((l) => l['id']! as String).toList();

    expect(
      [for (final tier in _tierIds) ids.indexOf('road-fill-$tier')],
      orderedEquals(
        [for (final tier in _tierIds) ids.indexOf('road-fill-$tier')]..sort(),
      ),
    );
  });

  // The `transportation` layer is not a road layer. It also carries railways,
  // ferry routes, piers and a `*_construction` variant of every road class —
  // all of which were rendering as ordinary streets.
  test('nothing that is not a street is drawn as one', () {
    final style = _style(Brightness.light);
    final claimed = <Object?>{
      for (final layer in _roadLayers(style, 'road-')) ..._classes(layer),
    };

    for (final notAStreet in [
      'rail',
      'transit',
      'ferry',
      'pier',
      'aerialway',
      'motorway_construction',
      'primary_construction',
      'minor_construction',
      'path_construction',
    ]) {
      expect(
        claimed,
        isNot(contains(notAStreet)),
        reason: '$notAStreet is being drawn as a road',
      );
    }
  });

  // Same argument one layer over: an administrative line drawn in the road
  // casing colour is a street the city never built. It shared that colour
  // until the casing was made visible, at which point sharing would have lit
  // up every district border.
  test('an administrative boundary is not painted as a road', () {
    for (final brightness in Brightness.values) {
      final style = _style(brightness);
      final boundary =
          (_layer(style, 'boundary')['paint']! as Map)['line-color'];
      final palette = AppMapColors.of(brightness);

      expect(boundary, _hex(palette.boundary));
      expect(
        boundary,
        isNot(_hex(palette.roadCasing)),
        reason: '${brightness.name}: boundaries read as streets',
      );
    }
  });

  // A road too small to walk at this scale is noise, not information.
  test('minor roads drop out before the map zooms out', () {
    final style = _style(Brightness.light);

    int minZoom(String tier) =>
        (_layer(style, 'road-fill-$tier')['minzoom'] as num?)?.toInt() ?? 0;

    expect(minZoom('major'), 0);
    expect(minZoom('path'), greaterThan(minZoom('minor')));
    expect(minZoom('minor'), greaterThan(minZoom('tertiary')));
    expect(minZoom('tertiary'), greaterThan(minZoom('secondary')));
    expect(minZoom('secondary'), greaterThan(minZoom('major')));
  });

  test('water is drawn over land, not under it', () {
    final ids = _layers(_style(Brightness.light)).map((l) => l['id']).toList();
    expect(ids.indexOf('background'), lessThan(ids.indexOf('water')));
  });

  // The provider's default style is banned outright by the art direction.
  test('no layer carries a colour from outside the map palette', () {
    final style = _style(Brightness.light);
    final allowed = {
      _hex(AppMapColors.light.land),
      _hex(AppMapColors.light.water),
      _hex(AppMapColors.light.green),
      _hex(AppMapColors.light.road),
      _hex(AppMapColors.light.roadCasing),
      _hex(AppMapColors.light.boundary),
      _hex(AppMapColors.light.label),
    };

    for (final layer in _layers(style)) {
      final paint = layer['paint']! as Map<String, Object?>;
      for (final entry in paint.entries) {
        final value = entry.value;
        if (value is String && value.startsWith('#')) {
          expect(
            allowed,
            contains(value),
            reason: '${layer['id']}.${entry.key} uses an off-palette colour',
          );
        }
      }
    }
  });
}
