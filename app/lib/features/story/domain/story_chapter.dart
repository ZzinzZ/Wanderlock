/// One beat of a chapter.
///
/// A closed set with no branching: section 2 of docs/08-scope.md puts
/// branching stories in v2, and a format that allowed them now would invite
/// content that depends on them.
///
/// **Dialogue was removed on 2026-09-27** (owner). A chapter is a written
/// introduction to a place, in one voice, so the only beats are prose and
/// photographs.
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

/// What kind of reading a chapter is.
///
/// Both are the same format and open the same way; they differ in what a
/// reader should expect. Keeping the distinction in the content, rather than
/// inferring it from length, means a two-paragraph chapter written for a small
/// place is still a chapter, and a long intro is still an intro.
enum StoryChapterKind {
  /// Written from a source about this place, with something to say about it.
  chapter,

  /// A few factual lines assembled from open data, for a place nobody has
  /// written about. Honest, short, and labelled so it is not mistaken for the
  /// other kind.
  intro,
}

/// A chapter of the Story lens: what a checkpoint has to say once you have
/// stood in front of it. Content lives in `content/stories/*.json` and ships
/// inside the binary, like the checkpoints and the quests.
class StoryChapter {
  const StoryChapter({
    required this.id,
    required this.checkpointId,
    required this.title,
    required this.nodes,
    this.kind = StoryChapterKind.chapter,
    this.source,
    this.coverImage,
    this.coverCredit,
    this.estimatedMinutes = 2,
  });

  final String id;

  /// Defaults to [StoryChapterKind.chapter]: the authored chapters were
  /// written before intros existed and must not be relabelled by their
  /// silence.
  final StoryChapterKind kind;

  /// The checkpoint this chapter belongs to. One chapter per checkpoint in v1.
  final String checkpointId;

  final String title;

  /// Where the facts came from, shown at the end of the chapter. Facts are not
  /// anybody’s property, but saying where they were checked is what lets the
  /// next person check them again.
  final String? source;

  /// 16:9, per the image ratios fixed by the art direction.
  final String? coverImage;

  /// The line the photograph’s licence requires to be shown beside it.
  ///
  /// CC BY and CC BY-SA are free to ship and not free of obligation: the author
  /// has to be named where the picture is seen. Empty only for CC0 and public
  /// domain. A chapter with a cover and no credit is refused by a test.
  final String? coverCredit;

  /// Roughly how long it takes to read, shown before opening, because somebody
  /// standing in the sun deserves to know what they are committing to.
  final int estimatedMinutes;

  final List<StoryNode> nodes;

  bool get isEmpty => nodes.isEmpty;
}
