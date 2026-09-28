import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';

/// The building stickers of the sticker pass are drawn from files named in
/// code. A name without a file draws nothing on the map, silently; a file
/// without a name is weight in the bundle nobody asked for.
void main() {
  const directory = 'assets/landmarks';

  test('every landmark the code names exists as a PNG', () {
    for (final name in LandmarkArt.all) {
      final file = File(LandmarkArt.assetPath(name));
      expect(file.existsSync(), isTrue, reason: 'missing: ${file.path}');
      // The PNG signature, so a renamed SVG cannot pass for a bitmap.
      expect(file.readAsBytesSync().take(4), [0x89, 0x50, 0x4E, 0x47]);
    }
  });

  test('nothing is bundled that no code names', () {
    final bundled = Directory(directory)
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last.replaceAll('.png', ''))
        .toSet();

    expect(bundled, LandmarkArt.all.toSet());
  });
}
