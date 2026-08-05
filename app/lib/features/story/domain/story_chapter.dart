/// One beat of a chapter.
///
/// Deliberately a closed set with no branching. Section 2 of docs/08-scope.md
/// puts fragmented, branching stories in v2; a format that allows branches now
/// would invite content that depends on them, and the reader would arrive
/// before the player did.
sealed class StoryNode {
  const StoryNode();
}

/// The narrator speaking, unattributed.
final class Narration extends StoryNode {
  const Narration(this.text);

  final String text;
}

/// A named character speaking. [speakerId] refers to a narrator or character
/// defined in content, not a display name, so the same chapter survives that
/// character being renamed.
final class Speech extends StoryNode {
  const Speech({required this.speakerId, required this.text});

  final String speakerId;
  final String text;
}

/// A photograph. Landmarks always use real photographs, never illustration —
/// see section 7.1 of docs/09-art-direction.md.
final class StoryImage extends StoryNode {
  const StoryImage({required this.asset, this.caption});

  final String asset;
  final String? caption;
}

/// A chapter of the Story lens: what a checkpoint has to say once you have
/// stood in front of it.
///
/// Content lives in `content/stories/*.json`, is version-controlled, and is
/// loaded by the seed script. The database stores the node list as jsonb
/// because a chapter is authored, reviewed and shipped as one unit.
class StoryChapter {
  const StoryChapter({
    required this.id,
    required this.checkpointId,
    required this.narratorId,
    required this.title,
    required this.nodes,
    this.coverImage,
    this.estimatedMinutes = 3,
  });

  final String id;

  /// The checkpoint this chapter belongs to. One chapter per checkpoint in v1.
  final String checkpointId;

  final String narratorId;
  final String title;

  /// 16:9, per the image ratios fixed by the art direction.
  final String? coverImage;

  /// Roughly how long it takes to read. Shown before opening, because
  /// somebody standing in the sun deserves to know what they are committing
  /// to. The pilot targets two to four minutes.
  final int estimatedMinutes;

  final List<StoryNode> nodes;

  bool get isEmpty => nodes.isEmpty;

  /// Every distinct speaker, so the player can preload their portraits.
  Set<String> get speakerIds => {
    for (final node in nodes)
      if (node is Speech) node.speakerId,
  };
}
