import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'package:wanderlock/features/story/data/story_chapter_dto.dart';
import 'package:wanderlock/features/story/domain/story_chapter.dart';

/// Reads the authored chapters that ship inside the binary.
///
/// Bundled rather than fetched, for the same reason the checkpoints and the
/// quests are: a chapter is read while standing in front of the place, which
/// is exactly where signal is worst, and a few kilobytes of prose is not worth
/// a round trip.
///
/// One file per chapter rather than one file holding all of them — that is how
/// `content/stories/` is laid out, and it is the right shape for the thing
/// being authored: a chapter is written, reviewed and corrected on its own, by
/// someone who should never have to open a file containing 271 other places.
/// The cost is that the list of chapters is not written down anywhere, so it
/// has to be discovered from the asset manifest at runtime.
///
/// The copies under `app/assets/content/stories/` are kept identical to the
/// authored ones by `test/content/bundled_content_test.dart` — Flutter cannot
/// bundle an asset from outside the package directory, so a copy is the only
/// option and a test is what stops it drifting.
class StoryChapterBundledSource {
  const StoryChapterBundledSource({
    this.directory = defaultDirectory,
    this.listAssets,
    this.load,
  });

  static const String defaultDirectory = 'assets/content/stories/';

  final String directory;

  /// Overridable so the reader can be tested without a Flutter asset bundle.
  final Future<List<String>> Function()? listAssets;
  final Future<String> Function(String assetPath)? load;

  Future<List<StoryChapter>> readAll() async {
    final paths = await (listAssets ?? _manifestAssets)();

    final chapters = <StoryChapter>[];
    for (final path in paths..sort()) {
      if (!path.startsWith(directory) || !path.endsWith('.json')) continue;
      // A leading underscore marks a file that documents the format rather
      // than holding content. Loading it would put placeholder prose in front
      // of a reader standing at a real place.
      if (_fileName(path).startsWith('_')) continue;

      final chapter = parse(await (load ?? rootBundle.loadString)(path));
      // An empty chapter is dropped rather than shown: a reader who walked to
      // a place and was handed a blank page would reasonably call that broken.
      if (chapter.isEmpty) continue;
      chapters.add(chapter);
    }
    return chapters;
  }

  static StoryChapter parse(String raw) =>
      StoryChapterDto.fromJson(jsonDecode(raw) as Map<String, Object?>);

  static String _fileName(String path) =>
      path.substring(path.lastIndexOf('/') + 1);

  static Future<List<String>> _manifestAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets();
  }
}
