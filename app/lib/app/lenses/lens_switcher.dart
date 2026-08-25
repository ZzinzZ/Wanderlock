import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Picks the lens.
///
/// A segmented pill rather than a tab bar or a drawer, because switching lens
/// is the single most repeated action in the product and it has to stay under
/// the thumb without covering the map it is changing.
class LensSwitcher extends ConsumerWidget {
  const LensSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final current = ref.watch(lensProvider);

    // No neumorphic shadow. Section 10 of the art direction bans the soft pair
    // on anything sitting directly on the map, and this bar sits on the map:
    // a surface that needs a flat, evenly lit ground cannot have a city
    // underneath it. A solid block is what the same document prescribes
    // instead.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lens in Lens.values)
              _LensChip(
                lens: lens,
                isSelected: lens == current,
                onSelected: () => ref.read(lensProvider.notifier).select(lens),
              ),
          ],
        ),
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
    };

    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: AppMotion.lensSwitch,
          curve: AppMotion.linearCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            // The selected chip is the one solid block on the bar. Green
            // rather than the action green: this selects a view, it does not
            // commit anything, and the art direction reserves the darker
            // action colour for buttons that do.
            color: isSelected ? colors.primary : colors.card,
            borderRadius: AppRadius.pill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full colour on both chips. With no tint left to dim, an
              // unselected chip is distinguished by its label and its ground,
              // not by a quieter icon — and two full-colour icons side by side
              // is what makes the bar read as a set of places to go.
              AppIcon(icon),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isSelected ? colors.ink : colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
