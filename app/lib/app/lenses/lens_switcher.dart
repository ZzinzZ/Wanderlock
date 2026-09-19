import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Picks the lens.
///
/// A chunky game tab bar pinned under the thumb: the most repeated action in
/// the product, so it gets the loudest treatment short of the unlock button.
/// The selected tab is a yellow sticker lifted out of the bar; the others lie
/// flat, their icons greyed — colour means "on", as everywhere else.
class LensSwitcher extends ConsumerWidget {
  const LensSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(lensProvider);

    return StickerSurface(
      borderRadius: AppRadius.hero,
      depth: AppSticker.depthLarge - 1,
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      child: Row(
        children: [
          for (final lens in Lens.values)
            Expanded(
              child: _LensChip(
                lens: lens,
                isSelected: lens == current,
                onSelected: () => ref.read(lensProvider.notifier).select(lens),
              ),
            ),
        ],
      ),
    );
  }
}

class _LensChip extends StatelessWidget {
  const _LensChip({
    required this.lens,
    required this.isSelected,
    required this.onSelected,
  });

  final Lens lens;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    final (label, icon) = switch (lens) {
      Lens.fog => (l10n.lensFog, AppIcons.lensMap),
      Lens.collection => (l10n.lensCollection, AppIcons.lensCollection),
      Lens.journey => (l10n.lensJourney, AppIcons.lensJourney),
    };

    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelected,
        child: AnimatedContainer(
          duration: AppMotion.lensSwitch,
          curve: AppMotion.standardCurve,
          transform: Matrix4.translationValues(
            0,
            isSelected ? -AppSticker.selectedLift : 0,
            0,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentYellow : colors.card,
            borderRadius: AppRadius.sticker,
            border: Border.all(
              color: isSelected ? colors.outline : colors.card,
              width: AppSticker.stroke,
            ),
            boxShadow: isSelected ? AppShadows.sticker(colors) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1 : 0.85,
                duration: AppMotion.lensSwitch,
                curve: AppMotion.standardCurve,
                child: AppIcon(icon, isMuted: !isSelected),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.tab.copyWith(
                  color: isSelected ? colors.onAccentYellow : colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
