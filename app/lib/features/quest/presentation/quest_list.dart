import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/sticker_progress.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/quest/domain/quest_route.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Every quest, as a stack of sticker cards: what it is, how it is played,
/// and how far along it is.
///
/// Reads and never writes, like the rest of the quest lens: progress comes
/// from `visit_state` through [QuestRoute].
class QuestList extends StatelessWidget {
  const QuestList({
    required this.routes,
    required this.landmarkOf,
    required this.onOpen,
    super.key,
  });

  final List<QuestRoute> routes;

  /// Which building sticker a checkpoint wears. Passed in: the mapping
  /// belongs to the checkpoint feature, which this one may not import.
  final String Function(String checkpointId) landmarkOf;

  final ValueChanged<QuestRoute> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    if (routes.isEmpty) {
      return Center(
        child: Text(
          l10n.questEmpty,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: colors.ink),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: routes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md - 4),
      itemBuilder: (context, index) {
        final route = routes[index];
        return _QuestCard(
          route: route,
          art: landmarkOf(route.steps.first.checkpointId),
          onOpen: () => onOpen(route),
        );
      },
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.route,
    required this.art,
    required this.onOpen,
  });

  final QuestRoute route;
  final String art;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      label: route.name,
      value: l10n.questListProgress(route.doneCount, route.totalCount),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onOpen,
        child: StickerSurface(
          color: route.isComplete ? colors.highlightSurface : colors.card,
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            children: [
              Container(
                width: AppIconSize.tile,
                height: AppIconSize.tile,
                decoration: BoxDecoration(
                  color: route.isSet
                      ? colors.infoSurface
                      : colors.highlightSurface,
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                    color: colors.outline,
                    width: AppSticker.stroke,
                  ),
                ),
                alignment: Alignment.center,
                child: LandmarkImage(art, size: AppIconSize.place),
              ),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            route.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.hudTitle.copyWith(
                              color: colors.ink,
                            ),
                          ),
                        ),
                        if (route.isComplete)
                          const AppIcon(
                            AppIcons.visited,
                            size: AppIconSize.inline,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _KindTag(isSet: route.isSet),
                        const Spacer(),
                        Text(
                          l10n.questListProgress(
                            route.doneCount,
                            route.totalCount,
                          ),
                          style: AppTypography.tab.copyWith(color: colors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    StickerProgressBar(
                      value: route.progress,
                      height: AppSpacing.sm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Route" or "Collection", so the player knows before opening whether the
/// order matters.
class _KindTag extends StatelessWidget {
  const _KindTag({required this.isSet});

  final bool isSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSet ? colors.infoSurface : colors.highlightSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.strokeThin),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          isSet ? l10n.questKindSet : l10n.questKindRoute,
          style: AppTypography.tag.copyWith(color: colors.ink),
        ),
      ),
    );
  }
}
