import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/map/map_style.dart';

/// Writes the generated styles out so a browser can render them.
///
/// Deliberately **not** named `*_test.dart`: the suite globs that suffix, so
/// this never runs in CI and never writes into a CI workspace. It is a tool
/// that happens to need the Flutter test runner, because [MapStyle] takes a
/// `Brightness` and returns colours, and neither exists outside Flutter.
///
/// Run from `app/`:
///
/// ```
/// fvm flutter test test/design/map_style_preview.dart
/// ```
///
/// Then open the preview with the `map-style-preview` launch configuration.
/// The emulator cannot stand in for this: its software renderer draws no map
/// text at all, so labels can only be judged in a browser or on a real device.
void main() {
  const outputDirectory = '../tool/map_preview';

  test('writes both styles for the browser preview', () {
    for (final brightness in Brightness.values) {
      final json = MapStyle.toJson(
        tilesUrl: AppConfig.mapTilesUrl,
        glyphsUrl: AppConfig.mapGlyphsUrl,
        brightness: brightness,
      );
      File(
        '$outputDirectory/style-${brightness.name}.json',
      ).writeAsStringSync(json);
    }
  });
}
