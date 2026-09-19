import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_bundled_source.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';

/// Guards the copy of the pilot content that ships inside the binary.
///
/// Flutter cannot bundle an asset from outside the package directory, so
/// `content/checkpoints.json` has to exist twice. Two copies of a source of
/// truth is a bug waiting to happen — this is the thing that stops it, and it
/// is the only reason the duplication is acceptable.
void main() {
  _assetManifestTests();

  final root = File('pubspec.yaml').absolute.parent.parent;
  final authored = File('${root.path}/content/checkpoints.json');
  final bundled = File('assets/content/checkpoints.json');

  test('the bundled copy is byte-for-byte the authored content', () {
    expect(
      authored.existsSync(),
      isTrue,
      reason: 'expected ${authored.path} to exist',
    );
    expect(bundled.existsSync(), isTrue);

    expect(
      bundled.readAsBytesSync(),
      authored.readAsBytesSync(),
      reason:
          'assets/content/checkpoints.json has drifted from '
          'content/checkpoints.json — copy the root file over it',
    );
  });

  group('parsing the authored content', () {
    late List<Checkpoint> checkpoints;

    setUp(() {
      checkpoints = CheckpointBundledSource.parse(bundled.readAsStringSync());
    });

    test('yields the twelve pilot places', () {
      expect(checkpoints, hasLength(12));
    });

    test('every place lands in Ho Chi Minh City', () {
      for (final checkpoint in checkpoints) {
        // A place that parsed wrong tends to end up at (0, 0), which is in the
        // Gulf of Guinea and looks like a rendering bug rather than bad data.
        expect(checkpoint.latitude, inInclusiveRange(10.5, 11.1));
        expect(checkpoint.longitude, inInclusiveRange(106.4, 107.0));
      }
    });

    test('every place carries a usable radius', () {
      for (final checkpoint in checkpoints) {
        expect(checkpoint.radiusMeters, inInclusiveRange(20, 500));
      }
    });

    test('ids are unique, so no place can shadow another', () {
      final ids = checkpoints.map((c) => c.id).toSet();
      expect(ids, hasLength(checkpoints.length));
    });
  });

  group('parse', () {
    test('drops a place with no coordinates rather than defaulting it', () {
      const raw = '''
      {"checkpoints": [
        {"id": "a", "name": "Có toạ độ", "category": "museum",
         "radiusMeters": 50,
         "coordinates": {"lat": 10.77, "lon": 106.69, "verified": true}},
        {"id": "b", "name": "Chưa có toạ độ", "category": "museum",
         "radiusMeters": 50}
      ]}''';

      final parsed = CheckpointBundledSource.parse(raw);

      expect(parsed, hasLength(1));
      expect(parsed.single.id, 'a');
    });

    test('reads the optional fields, and defaults them when absent', () {
      const raw = '''
      {"checkpoints": [
        {"id": "a", "name": "Đủ dấu: ế ỡ ộ ữ ẫ", "category": "religious",
         "radiusMeters": 40, "address": "Số 1",
         "requiresQrFallback": true, "photoUrl": "https://example.test/a.jpg",
         "coordinates": {"lat": 10.77, "lon": 106.69, "verified": true}},
        {"id": "b", "name": "Tối giản", "category": "street",
         "radiusMeters": 40,
         "coordinates": {"lat": 10.78, "lon": 106.70, "verified": false}}
      ]}''';

      final parsed = CheckpointBundledSource.parse(raw);

      expect(parsed.first.name, 'Đủ dấu: ế ỡ ộ ữ ẫ');
      expect(parsed.first.requiresQrFallback, isTrue);
      expect(parsed.first.photoUrl, 'https://example.test/a.jpg');
      expect(parsed.last.requiresQrFallback, isFalse);
      expect(parsed.last.photoUrl, isNull);
      expect(parsed.last.address, isNull);
    });

    test('an unknown category falls back instead of throwing', () {
      const raw = '''
      {"checkpoints": [
        {"id": "a", "name": "Loại mới", "category": "space-elevator",
         "radiusMeters": 40,
         "coordinates": {"lat": 10.77, "lon": 106.69, "verified": true}}
      ]}''';

      // A category added on the server must not brick an older client.
      expect(CheckpointBundledSource.parse(raw), hasLength(1));
    });

    test('an empty file is empty, not an error', () {
      expect(CheckpointBundledSource.parse('{"checkpoints": []}'), isEmpty);
    });
  });
}

/// Catches the gap between "the file exists" and "the file ships".
///
/// Every other test in this file reads the asset **from disk**, which is what
/// let a quest route sit in `assets/content/`, pass its parser tests, and then
/// render an empty screen on a real device: the file was never listed in
/// `pubspec.yaml`, so it was not in the bundle for `rootBundle` to find.
///
/// Lives here rather than beside each feature because the failure is about the
/// manifest, and the manifest is one file for the whole app.
void _assetManifestTests() {
  // Entries, not raw text. Matching the file as one string made the check
  // useless: `- assets/content/checkpoints.json` contains the substring
  // `- assets/content/`, so a directory test written that way passed for
  // every sibling file the manifest had never heard of.
  final entries = File('pubspec.yaml')
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.startsWith('- '))
      .map((line) => line.substring(2).trim())
      .toSet();

  group('every content asset the code names is declared in pubspec', () {
    for (final assetPath in const [
      CheckpointBundledSource.defaultAssetPath,
      QuestRouteBundledSource.defaultAssetPath,
    ]) {
      test(assetPath, () {
        expect(
          File(assetPath).existsSync(),
          isTrue,
          reason: '$assetPath is named in code but not on disk',
        );

        // A directory entry covers every file inside it, so either the exact
        // path or its directory counts — but each has to be an entry of its
        // own, not a substring of a longer one.
        final directory =
            '${assetPath.substring(0, assetPath.lastIndexOf('/'))}/';
        expect(
          entries.contains(assetPath) || entries.contains(directory),
          isTrue,
          reason:
              '$assetPath is not listed under flutter/assets in pubspec.yaml, '
              'so rootBundle cannot load it — the screen that reads it will '
              'be empty on a device while every disk-reading test passes',
        );
      });
    }
  });
}
