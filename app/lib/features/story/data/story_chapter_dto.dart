import 'package:wanderlock/features/story/domain/story_chapter.dart';

/// Thrown when authored content does not match the format.
///
/// Carries the chapter and node it failed on, because the person who has to
/// act on this is an author looking at a JSON file, not a developer looking
/// at a stack trace.
class StoryFormatException implements Exception {
  const StoryFormatException(this.message, {this.chapterId, this.nodeIndex});

  final String message;
  final String? chapterId;
  final int? nodeIndex;

  @override
  String toString() {
    final where = [
      if (chapterId != null) 'chương "$chapterId"',
      if (nodeIndex != null) 'node #$nodeIndex',
    ].join(', ');
    return where.isEmpty ? message : '$message ($where)';
  }
}

/// Reads a chapter from the authored JSON.
///
/// Strict on purpose. A typo in a node type silently dropping a paragraph
/// would be discovered by a reader standing in front of a monument, which is
/// the worst place to find out.
abstract final class StoryChapterDto {
  static StoryChapter fromJson(Map<String, Object?> json) {
    final id = _requireString(json, 'id');

    final rawNodes = json['nodes'];
    if (rawNodes is! List) {
      throw StoryFormatException('thiếu danh sách nodes', chapterId: id);
    }

    return StoryChapter(
      id: id,
      checkpointId: _requireString(json, 'checkpointId', chapterId: id),
      title: _requireString(json, 'title', chapterId: id),
      kind: _kindFromJson(json['kind'], chapterId: id),
      source: json['source'] as String?,
      coverImage: json['coverImage'] as String?,
      coverCredit: json['coverCredit'] as String?,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 2,
      nodes: [
        for (var i = 0; i < rawNodes.length; i++)
          _nodeFromJson(rawNodes[i], chapterId: id, index: i),
      ],
    );
  }

  /// Absent means [StoryChapterKind.chapter]. An unknown value is refused
  /// rather than defaulted: a typo silently downgrading a chapter to an intro
  /// is exactly the kind of quiet wrong this parser exists to prevent.
  static StoryChapterKind _kindFromJson(
    Object? raw, {
    required String chapterId,
  }) {
    if (raw == null) return StoryChapterKind.chapter;
    return switch (raw) {
      'chapter' => StoryChapterKind.chapter,
      'intro' => StoryChapterKind.intro,
      _ => throw StoryFormatException(
        'kind phải là "chapter" hoặc "intro", không phải "$raw"',
        chapterId: chapterId,
      ),
    };
  }

  static StoryNode _nodeFromJson(
    Object? raw, {
    required String chapterId,
    required int index,
  }) {
    if (raw is! Map<String, Object?>) {
      throw StoryFormatException(
        'node phải là một object',
        chapterId: chapterId,
        nodeIndex: index,
      );
    }

    final type = raw['type'];
    return switch (type) {
      'narration' => Narration(
        _requireString(raw, 'text', chapterId: chapterId, nodeIndex: index),
      ),
      'image' => StoryImage(
        asset: _requireString(
          raw,
          'asset',
          chapterId: chapterId,
          nodeIndex: index,
        ),
        caption: raw['caption'] as String?,
      ),
      _ => throw StoryFormatException(
        'không biết node type "$type" — chỉ có narration và image',
        chapterId: chapterId,
        nodeIndex: index,
      ),
    };
  }

  static String _requireString(
    Map<String, Object?> json,
    String key, {
    String? chapterId,
    int? nodeIndex,
  }) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw StoryFormatException(
        'thiếu hoặc rỗng: "$key"',
        chapterId: chapterId,
        nodeIndex: nodeIndex,
      );
    }
    return value;
  }
}
