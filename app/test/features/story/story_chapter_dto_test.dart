import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/story/data/story_chapter_dto.dart';
import 'package:wanderlock/features/story/domain/story_chapter.dart';

Map<String, Object?> _chapter({List<Object?>? nodes}) => {
  'id': 'chapter-1',
  'checkpointId': 'independence-palace',
  'narratorId': 'narrator-main',
  'title': 'Tiêu đề',
  'nodes':
      nodes ??
      [
        {'type': 'narration', 'text': 'Mở đầu.'},
      ],
};

void main() {
  test('reads every node type', () {
    final chapter = StoryChapterDto.fromJson(
      _chapter(
        nodes: [
          {'type': 'narration', 'text': 'Bối cảnh.'},
          {'type': 'speech', 'speakerId': 'co-ba', 'text': 'Chào bạn.'},
          {'type': 'image', 'asset': 'a.jpg', 'caption': 'Chú thích'},
        ],
      ),
    );

    expect(chapter.nodes, hasLength(3));
    expect(chapter.nodes[0], isA<Narration>());
    expect((chapter.nodes[1] as Speech).speakerId, 'co-ba');
    expect((chapter.nodes[2] as StoryImage).caption, 'Chú thích');
  });

  test('collects speakers so portraits can be preloaded', () {
    final chapter = StoryChapterDto.fromJson(
      _chapter(
        nodes: [
          {'type': 'speech', 'speakerId': 'co-ba', 'text': 'Một.'},
          {'type': 'speech', 'speakerId': 'ong-tu', 'text': 'Hai.'},
          {'type': 'speech', 'speakerId': 'co-ba', 'text': 'Ba.'},
          {'type': 'narration', 'text': 'Không phải người nói.'},
        ],
      ),
    );

    expect(chapter.speakerIds, {'co-ba', 'ong-tu'});
  });

  test('defaults the reading time rather than guessing at zero', () {
    expect(StoryChapterDto.fromJson(_chapter()).estimatedMinutes, 3);
  });

  // A typo in a node type must not silently drop a paragraph. The reader would
  // find out standing in front of a monument, which is the worst place for it.
  test('an unknown node type is rejected, not skipped', () {
    expect(
      () => StoryChapterDto.fromJson(
        _chapter(
          nodes: [
            {'type': 'naration', 'text': 'Sai chính tả type.'},
          ],
        ),
      ),
      throwsA(isA<StoryFormatException>()),
    );
  });

  test('an empty text field is rejected', () {
    expect(
      () => StoryChapterDto.fromJson(
        _chapter(
          nodes: [
            {'type': 'narration', 'text': ''},
          ],
        ),
      ),
      throwsA(isA<StoryFormatException>()),
    );
  });

  test('the error says which chapter and which node', () {
    try {
      StoryChapterDto.fromJson(
        _chapter(
          nodes: [
            {'type': 'narration', 'text': 'Ổn.'},
            {'type': 'speech', 'text': 'Thiếu speakerId.'},
          ],
        ),
      );
      fail('should have thrown');
    } on StoryFormatException catch (error) {
      expect(error.toString(), contains('chapter-1'));
      expect(error.toString(), contains('node #1'));
    }
  });

  test('a chapter without a checkpoint is rejected', () {
    final json = _chapter()..remove('checkpointId');
    expect(
      () => StoryChapterDto.fromJson(json),
      throwsA(isA<StoryFormatException>()),
    );
  });

  // The example in content/ is the thing authors copy. If it stops parsing,
  // everyone writing from it is writing something broken.
  test('the format example in content/ parses', () {
    final file = File('../content/stories/_format-example.json');
    expect(file.existsSync(), isTrue, reason: 'ví dụ định dạng phải tồn tại');

    final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final chapter = StoryChapterDto.fromJson(json);

    expect(chapter.nodes, isNotEmpty);
    expect(chapter.checkpointId, isNotEmpty);
  });
}
