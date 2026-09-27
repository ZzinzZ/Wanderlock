import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/pattern_background.dart';
import 'package:wanderlock/design/widgets/sticker_button.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/story/domain/story_chapter.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The Story lens: a chapter, read full screen.
///
/// Full screen rather than a lens on the map, because that is what section 5.2
/// of the scope lays out — the lens bar stays three chips (Map, Collection,
/// Journey) and the story player is a destination reached by tapping a place
/// you have already unlocked. A fourth chip would give the rarest destination
/// the same weight as the map.
///
/// Reading is the whole interaction. No choices, no branches, no way to mark
/// anything complete: a chapter opens because the unlock layer says the place
/// was visited, and nothing that happens on this screen can change that.
class StoryPlayer extends StatelessWidget {
  const StoryPlayer({
    required this.chapter,
    required this.placeName,
    required this.landmark,
    super.key,
  });

  final StoryChapter chapter;

  /// The checkpoint's own name. The chapter title is a headline for the piece,
  /// not the name of the place, so both are shown.
  final String placeName;

  /// A `LandmarkArt` name, used as the plate at the top while there is no
  /// cover photograph.
  final String landmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return PatternBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  StickerButton(
                    label: l10n.storyClose,
                    variant: StickerButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    l10n.storyMinutes(chapter.estimatedMinutes),
                    style: AppTypography.label.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  _Heading(
                    title: chapter.title,
                    placeName: placeName,
                    landmark: landmark,
                    coverImage: chapter.coverImage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final node in chapter.nodes) ...[
                    switch (node) {
                      Narration() => _Paragraph(node.text),
                      StoryImage() => _Plate(node),
                    },
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (chapter.source case final source?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.storySource(source),
                      style: AppTypography.label.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.placeName,
    required this.landmark,
    required this.coverImage,
  });

  final String title;
  final String placeName;
  final String landmark;
  final String? coverImage;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StickerSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: coverImage == null
                ? LandmarkImage(landmark, size: AppIconSize.tile)
                : ClipRRect(
                    borderRadius: AppRadius.chip,
                    child: Image.asset(coverImage!, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            placeName.toUpperCase(),
            style: AppTypography.label.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.hudTitle.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(color: AppColors.of(context).ink),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate(this.image);

  final StoryImage image;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StickerSurface(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.chip,
            child: Image.asset(image.asset, fit: BoxFit.cover),
          ),
          if (image.caption case final caption?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              style: AppTypography.label.copyWith(color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
