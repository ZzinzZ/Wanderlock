import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/sticker_progress.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The game HUD across the top of the map: how far the player has got, and a
/// shortcut to what they have collected.
///
/// Shows only what v1 already has — places reached out of the pilot's
/// total, and stamps owned. No levels, no currency, no ranking: those would be
/// new mechanics, and the owner chose to keep the HUD inside scope.
///
/// Reads `visit_state` through the same provider every lens reads. It holds
/// no count of its own, so it cannot disagree with the album.
class ExploreHud extends ConsumerWidget {
  const ExploreHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final total = (ref.watch(checkpointsProvider).value ?? const []).length;
    final visited = ref.watch(visitedCheckpointIdsProvider).length;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StickerSurface(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md - 4,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppIconSize.navigation + 2,
                    height: AppIconSize.navigation + 2,
                    decoration: BoxDecoration(
                      color: colors.accentYellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.outline,
                        width: AppSticker.stroke,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(AppIcons.lensJourney),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.hudExplorerTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.hudTitle.copyWith(
                                  color: colors.ink,
                                ),
                              ),
                            ),
                            Text(
                              l10n.hudProgress(visited, total),
                              style: AppTypography.badge.copyWith(
                                color: colors.ink,
                                fontSize: AppTypography.hudTitle.fontSize,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        StickerProgressBar(
                          value: total == 0 ? 0 : visited / total,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: l10n.hudStampsLabel(visited),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () =>
                  ref.read(lensProvider.notifier).select(Lens.collection),
              child: StickerSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(AppIcons.lensCollection),
                    Text(
                      '$visited',
                      style: AppTypography.badge.copyWith(color: colors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
