/// One beat of a chapter.
///
/// Deliberately a closed set with no branching. Section 2 of docs/08-scope.md
/// puts fragmented, branching stories in v2; a format that allows branches now
/// would invite content that depends on them, and the reader would arrive
/// before the player did.
///
/// **Dialogue was removed on 2026-09-27** (owner's decision). A chapter is a
/// written introduction to a place, in one voice — so the only beats are prose
/// and photographs. The `speech` node it had, and the character file it would
/// have needed, are gone with it; nothing in the pilot content used them.
sealed class StoryNode {
  const StoryNode();
}

/// A paragraph of prose.
final class Narration extends StoryNode {
  const Narration(this.text);

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
/// Content lives in `content/stories/*.json`, is version-controlled, and ships
/// inside the binary the way the checkpoints and the quests do.
class StoryChapter {
  const StoryChapter({
    required this.id,
    required this.checkpointId,
    required this.title,
    required this.nodes,
    this.source,
    this.coverImage,
    this.coverCredit,
    this.estimatedMinutes = 2,
  });

  final String id;

  /// The checkpoint this chapter belongs to. One chapter per checkpoint in v1.
  final String checkpointId;

  final String title;

  /// Where the facts came from, shown at the end of the chapter.
  ///
  /// The pilot chapters are written from Wikipedia articles. Facts are not
  /// anybody's property, but saying where they were checked is what lets the
  /// next person check them again — and it is the same discipline the photo
  /// ledger applies to pictures.
  final String? source;

  /// 16:9, per the image ratios fixed by the art direction.
  final String? coverImage;

  /// The line the photograph's licence requires to be shown beside it.
  ///
  /// CC BY and CC BY-SA are free to ship and not free of obligation: the
  /// author has to be named where the picture is seen. Empty only for CC0 and
  /// public domain, where nothing is required. A chapter with a cover and no
  /// credit is refused by a test rather than by a lawyer.
  final String? coverCredit;

  /// Roughly how long it takes to read. Shown before opening, because
  /// somebody standing in the sun deserves to know what they are committing
  /// to. The pilot targets one to three minutes.
  final int estimatedMinutes;

  final List<StoryNode> nodes;

  bool get isEmpty => nodes.isEmpty;
}
