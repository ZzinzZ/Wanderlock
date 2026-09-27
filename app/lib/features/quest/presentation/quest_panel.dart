import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/step_bubble.dart';
import 'package:wanderlock/design/widgets/sticker_progress.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/quest/domain/quest_route.dart';
import 'package:wanderlock/features/quest/domain/quest_step.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The quest lens: one route, in order, with what is left to do.
///
/// Reads and never writes. There is no "complete step" button anywhere on this
/// screen, and that absence is the feature — a step is completed by standing
/// in the place, which the unlock layer verifies. A button here would be a
/// second way to finish a quest, and the cheaper one would win.
class QuestPanel extends StatelessWidget {
  const QuestPanel({required this.route, required this.landmarkOf, super.key});

  /// The route to show. The caller decides there is one — `JourneyPanel`
  /// shows the list of routes until one is opened.
  final QuestRoute route;

  /// Which building sticker a step shows. Passed in: the mapping belongs to
  /// the checkpoint feature, which this one may not import.
  final String Function(String checkpointId) landmarkOf;

  @override
  Widget build(BuildContext context) {
    final next = route.nextStep;

    // Built lazily rather than all at once: a category set is as large as its
    // category, and markets alone is 68 places — of which four are on screen.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: route.steps.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _RouteCard(route: route),
          );
        }

        final step = route.steps[index - 1];
        return _StepRow(
          step: step,
          ordinal: index,
          isNext: step == next,
          art: landmarkOf(step.checkpointId),
        );
      },
    );
  }
}

/// The route's name, summary and progress, under a blue header strip.
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final QuestRoute route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final nextStep = route.nextStep;
    final nextIndex = nextStep == null ? null : route.steps.indexOf(nextStep);
    final percent = (route.progress * 100).round();

    return StickerSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.infoSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.md + 2),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colors.outline,
                  width: AppSticker.stroke,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  const AppIcon(
                    AppIcons.questStep,
                    size: AppIconSize.action + 4,
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: AppTypography.hudTitle.copyWith(
                            color: colors.ink,
                            fontSize: AppTypography.banner.fontSize! - 3,
                          ),
                        ),
                        Text(
                          route.isComplete
                              ? l10n.questComplete
                              : l10n.questProgress(
                                  route.doneCount,
                                  route.totalCount,
                                ),
                          style: AppTypography.tag.copyWith(color: colors.ink),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: AppTypography.badge.copyWith(
                      color: colors.ink,
                      fontSize: AppTypography.banner.fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md - 2,
              AppSpacing.sm + 2,
              AppSpacing.md - 2,
              AppSpacing.md - 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  route.summary,
                  style: AppTypography.label.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                StickerSegments(
                  total: route.totalCount,
                  done: {
                    for (var i = 0; i < route.steps.length; i++)
                      if (route.steps[i].isDone) i,
                  },
                  currentIndex: nextIndex,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.ordinal,
    required this.isNext,
    required this.art,
  });

  final QuestStep step;
  final int ordinal;

  /// The first stop still missing: raised and nudged out of the column so the
  /// eye lands on it first.
  final bool isNext;
  final String art;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    final fill = step.isDone
        ? colors.card
        : isNext
        ? colors.highlightSurface
        : colors.lockedSurface;
    final bubble = step.isDone
        ? colors.primaryAction
        : isNext
        ? colors.accentYellow
        : colors.card;
    final bubbleInk = step.isDone ? colors.onPrimaryAction : colors.ink;
    final isLit = step.isDone || isNext;

    return Semantics(
      label: step.name,
      value: step.isDone
          ? l10n.checkpointUnlockedLabel
          : l10n.checkpointLockedLabel,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isNext ? AppSpacing.sm - 2 : 0,
        ),
        child: StickerSurface(
          color: fill,
          depth: isNext ? AppSticker.depth + 1 : AppSticker.depthSmall,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.md - 4,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              StepBubble(ordinal: ordinal, fill: bubble, ink: bubbleInk),
              const SizedBox(width: AppSpacing.sm + 2),
              Container(
                width: AppIconSize.place - 4,
                height: AppIconSize.place - 4,
                decoration: BoxDecoration(
                  color: isLit ? colors.highlightSurface : colors.surfaceMuted,
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                    color: colors.outline,
                    width: AppSticker.stroke,
                  ),
                ),
                alignment: Alignment.center,
                child: LandmarkImage(
                  art,
                  size: AppIconSize.action + 6,
                  isMuted: !isLit,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.name,
                      style: AppTypography.hudTitle.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      step.isDone
                          ? l10n.questStepDone
                          : isNext
                          ? l10n.questStepNext
                          : l10n.questStepTodo,
                      style: AppTypography.tag.copyWith(color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              AppIcon(
                step.isDone
                    ? AppIcons.visited
                    : isNext
                    ? AppIcons.unlock
                    : AppIcons.locked,
                size: AppIconSize.inline + 4,
                isMuted: !isLit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
