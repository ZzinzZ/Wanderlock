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
    expect(
      (_layer(style, 'road-fill')['paint']! as Map)['line-color'],
      _hex(AppMapColors.light.road),
    );
    expect(
      (_layer(style, 'road-casing')['paint']! as Map)['line-color'],
      _hex(AppMapColors.light.roadCasing),
    );
  });

  // Section 8: both themes get their own map. An inverted light map would be
  // a different bug wearing the same clothes.
  test('dark is a separate map, not an inversion of light', () {
    final light = _style(Brightness.light);
    final dark = _style(Brightness.dark);

    for (final id in ['background', 'water', 'park', 'road-fill']) {
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

  // Road casing has to be drawn under the fill or it is not a casing.
  test('road casing sits beneath the road fill', () {
    final ids = _layers(_style(Brightness.light)).map((l) => l['id']).toList();
    expect(ids.indexOf('road-casing'), lessThan(ids.indexOf('road-fill')));
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
      _hex(AppColors.light.inkMuted),
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
