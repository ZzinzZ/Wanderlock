import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/app/lenses/map_filter.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Narrows the map to one group of places.
///
/// Lives in `app/` because it joins quests to checkpoints, which is the one
/// thing no feature is allowed to do for itself.
class MapFilterButton extends ConsumerWidget {
  const MapFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final active = ref.watch(activeFilterNameProvider);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: StickerSurface(
          borderRadius: AppRadius.pill,
          depth: AppSticker.depthSmall,
          color: active == null ? colors.card : colors.accentYellow,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.questRoute, size: AppIconSize.inline),
              const SizedBox(width: AppSpacing.xs + 2),
              // The name of the group, or the invitation to pick one. A count
              // would be the obvious thing to show here and is deliberately
              // absent: the number that matters is on the HUD already, and two
              // counters a centimetre apart mean neither gets read.
              Text(
                active ?? l10n.mapFilterAll,
                style: AppTypography.tag.copyWith(
                  color: active == null ? colors.ink : colors.onAccentYellow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      // Không phải một màu của hệ thiết kế mà là "không có nền": tấm sticker
      // bên trong tự mang nền, viền và bóng của nó.
      // design-token-ignore: sheet trong suốt để sticker tự dựng nền của nó
      backgroundColor: Colors.transparent,
      builder: (_) => const _MapFilterSheet(),
    );
  }
}

class _MapFilterSheet extends ConsumerWidget {
  const _MapFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final routes = ref.watch(questRoutesProvider);
    final active = ref.watch(mapFilterProvider);
    final total = ref.watch(allCheckpointCountProvider);

    void pick(String? id) {
      ref.read(mapFilterProvider.notifier).show(id);
      Navigator.of(context).maybePop();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: StickerSurface(
          borderRadius: AppRadius.hero,
          depth: AppSticker.depthLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.mapFilterTitle,
                style: AppTypography.hudTitle.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _FilterRow(
                      label: l10n.mapFilterAll,
                      count: total,
                      isSelected: active == null,
                      onTap: () => pick(null),
                    ),
                    for (final route in routes)
                      _FilterRow(
                        label: route.name,
                        count: route.totalCount,
                        isSelected: active == route.id,
                        onTap: () => pick(route.id),
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
          child: Row(
            children: [
              AppIcon(
                isSelected ? AppIcons.visited : AppIcons.questRoute,
                size: AppIconSize.inline,
                isMuted: !isSelected,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: isSelected ? colors.ink : colors.inkMuted,
                  ),
                ),
              ),
              Text(
                '$count',
                style: AppTypography.tag.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
