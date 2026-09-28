import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/story/data/story_chapter_bundled_source.dart';

/// The reader has to discover its own file list from the asset manifest,
/// because one chapter per file means nothing writes the list down. These
/// pin the rules it applies while doing that.
void main() {
  String chapterJson(
    String id, {
    String checkpointId = 'a-place',
    int nodes = 1,
  }) {
    final body = [
      for (var i = 0; i < nodes; i++) '{"type":"narration","text":"Đoạn $i."}',
    ].join(',');
    return '{"id":"$id","checkpointId":"$checkpointId","title":"T",'
        '"source":"S","nodes":[$body]}';
  }

  StoryChapterBundledSource sourceOver(Map<String, String> files) =>
      StoryChapterBundledSource(
        listAssets: () async => files.keys.toList(),
        load: (path) async => files[path]!,
      );

  test('reads every chapter in the directory', () async {
    final chapters = await sourceOver({
      'assets/content/stories/one.json': chapterJson('one'),
      'assets/content/stories/two.json': chapterJson('two'),
    }).readAll();

    expect(chapters.map((c) => c.id), ['one', 'two']);
  });

  test('ignores assets outside its own directory', () async {
    final chapters = await sourceOver({
      'assets/content/stories/one.json': chapterJson('one'),
      'assets/content/checkpoints.json': '{"checkpoints":[]}',
      'assets/icons/lock.png': 'not json',
    }).readAll();

    expect(chapters.map((c) => c.id), ['one']);
  });

  // The format example claims a real checkpoint id — that is what makes it a
  // useful example. Shipping it would put placeholder prose in front of
  // somebody standing at the palace.
  test('skips the underscore-prefixed format example', () async {
    final chapters = await sourceOver({
      'assets/content/stories/_format-example.json': chapterJson('example'),
      'assets/content/stories/real.json': chapterJson('real'),
    }).readAll();

    expect(chapters.map((c) => c.id), ['real']);
  });

  test(
    'drops a chapter with no nodes rather than showing a blank page',
    () async {
      final chapters = await sourceOver({
        'assets/content/stories/empty.json': chapterJson('empty', nodes: 0),
        'assets/content/stories/full.json': chapterJson('full'),
      }).readAll();

      expect(chapters.map((c) => c.id), ['full']);
    },
  );

  test('reads in a stable order whatever the manifest gives back', () async {
    final chapters = await StoryChapterBundledSource(
      listAssets: () async => [
        'assets/content/stories/zulu.json',
        'assets/content/stories/alpha.json',
      ],
      load: (path) async =>
          chapterJson(path.contains('zulu') ? 'zulu' : 'alpha'),
    ).readAll();

    expect(chapters.map((c) => c.id), ['alpha', 'zulu']);
  });
}
