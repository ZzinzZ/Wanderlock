import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/checkpoint/data/checkpoint_bundled_source.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/quest/data/quest_route_bundled_source.dart';
import 'package:wanderlock/features/story/data/story_chapter_bundled_source.dart';
import 'package:wanderlock/features/unlock/domain/geo_distance.dart';

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

  group('story chapters', () {
    final authoredDir = Directory('${root.path}/content/stories');
    final bundledDir = Directory('assets/content/stories');

    String nameOf(File file) => file.uri.pathSegments.last;

    // A leading underscore marks a file that documents the format rather than
    // holding content — the same rule the loader applies, so the example is
    // neither shipped nor counted. It claims a real checkpoint id, which is
    // what makes it a useful example and a bad chapter.
    List<File> jsonIn(Directory dir) =>
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .where((f) => !nameOf(f).startsWith('_'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('every authored chapter is bundled, and nothing extra is', () {
      final authoredNames = jsonIn(authoredDir).map(nameOf).toSet();
      final bundledNames = jsonIn(bundledDir).map(nameOf).toSet();

      expect(
        bundledNames,
        authoredNames,
        reason:
            'assets/content/stories has drifted from content/stories — '
            'copy the authored folder over it',
      );
    });

    test('each bundled chapter is byte-for-byte the authored one', () {
      for (final authoredFile in jsonIn(authoredDir)) {
        final bundledFile = File('${bundledDir.path}/${nameOf(authoredFile)}');
        expect(bundledFile.existsSync(), isTrue);
        expect(
          bundledFile.readAsBytesSync(),
          authoredFile.readAsBytesSync(),
          reason: '${nameOf(authoredFile)} đã lệch khỏi bản gốc',
        );
      }
    });

    test('every chapter parses, and belongs to a real checkpoint', () {
      final ids = {
        for (final checkpoint in CheckpointBundledSource.parse(
          bundled.readAsStringSync(),
        ))
          checkpoint.id,
      };

      for (final file in jsonIn(bundledDir)) {
        final chapter = StoryChapterBundledSource.parse(
          file.readAsStringSync(),
        );
        expect(
          ids,
          contains(chapter.checkpointId),
          reason:
              '${nameOf(file)} trỏ tới checkpoint "${chapter.checkpointId}" '
              'không có trong checkpoints.json',
        );
        expect(chapter.nodes, isNotEmpty, reason: nameOf(file));
      }
    });

    // A chapter is written from a source, and saying which one is what lets
    // the next person check the facts again.
    test('every chapter says where its facts came from', () {
      for (final file in jsonIn(bundledDir)) {
        final chapter = StoryChapterBundledSource.parse(
          file.readAsStringSync(),
        );
        expect(chapter.source, isNotNull, reason: nameOf(file));
        expect(chapter.source, isNotEmpty, reason: nameOf(file));
      }
    });

    test('no two chapters claim the same checkpoint', () {
      final claimed = <String, String>{};
      for (final file in jsonIn(bundledDir)) {
        final chapter = StoryChapterBundledSource.parse(
          file.readAsStringSync(),
        );
        expect(
          claimed,
          isNot(contains(chapter.checkpointId)),
          reason:
              '${nameOf(file)} và ${claimed[chapter.checkpointId]} cùng nhận '
              'checkpoint "${chapter.checkpointId}" — v1 chỉ một chương mỗi nơi',
        );
        claimed[chapter.checkpointId] = nameOf(file);
      }
    });
  });

  group('parsing the authored content', () {
    late List<Checkpoint> checkpoints;

    setUp(() {
      checkpoints = CheckpointBundledSource.parse(bundled.readAsStringSync());
    });

    // The pilot grew from twelve landmarks to the city's markets, parks,
    // malls and places to eat on 2026-09-19 (docs/08). The twelve are still
    // the ones checked by eye, and that is what this pins down.
    test('keeps the twelve verified landmarks among the places', () {
      const landmarks = {
        'independence-palace',
        'central-post-office',
        'ben-thanh-market',
        'war-remnants-museum',
        'vinh-nghiem-pagoda',
        'binh-tay-market',
        'le-van-duyet-tomb',
        'giac-lam-pagoda',
        'nha-rong-wharf',
        'thien-hau-temple',
        'landmark-81',
        'buu-long-pagoda',
      };
      final ids = {for (final checkpoint in checkpoints) checkpoint.id};
      expect(ids, containsAll(landmarks));
      expect(checkpoints.length, greaterThan(landmarks.length));
    });

    test('no two places share an id', () {
      final ids = [for (final checkpoint in checkpoints) checkpoint.id];
      expect(ids.toSet(), hasLength(ids.length));
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

    test('no two places share a name', () {
      final names = [for (final checkpoint in checkpoints) checkpoint.name];
      final repeated = names.toSet().where(
        (name) => names.where((other) => other == name).length > 1,
      );
      expect(
        repeated,
        isEmpty,
        reason:
            'two places with one name are indistinguishable in a quest list '
            'and in the collection — give each its own',
      );
    });

    // OpenStreetMap maps a statue in a churchyard and the church itself as
    // separate features. Imported as two checkpoints they sit metres apart,
    // and one visit unlocks both — which is the one thing "you have to
    // actually go there" is supposed to rule out.
    //
    // The exceptions below are real containment, not an import artefact: the
    // temple genuinely stands inside the zoo, so unlocking both is the truth.
    test('standing at one place does not unlock another', () {
      const containedOnPurpose = {
        'den-tho-vua-hung|thao-cam-vien-sai-gon',
        'cong-vien-van-lang|nha-tho-thanh-jeanne-d-arc',
        'nha-tho-thanh-jeanne-d-arc|cong-vien-van-lang',
        'cho-kim-bien|cho-tin-nghia',
        'cho-tin-nghia|cho-kim-bien',
        'cong-vien-le-thi-rieng|thien-duong-giai-tri-tho-trang',
        'thien-duong-giai-tri-tho-trang|cong-vien-le-thi-rieng',
      };

      final offenders = <String>[];
      for (final standing in checkpoints) {
        for (final other in checkpoints) {
          if (identical(standing, other)) continue;
          if (containedOnPurpose.contains('${standing.id}|${other.id}')) {
            continue;
          }
          final metres = metresBetween(
            fromLatitude: standing.latitude,
            fromLongitude: standing.longitude,
            toLatitude: other.latitude,
            toLongitude: other.longitude,
          );
          if (metres < other.radiusMeters) {
            offenders.add(
              '${standing.id} -> ${other.id} '
              '(${metres.round()} m, radius ${other.radiusMeters} m)',
            );
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
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
