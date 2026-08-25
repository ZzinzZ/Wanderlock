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
        // The bar is the quiet surface and the selected chip is the bright
        // one, which is the opposite of the green-fill version: with no
        // colour left in the fills, selection reads as a card lifting out of
        // its track rather than as a block lighting up.
        color: colors.surfaceMuted,
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
            // No fill colour on either chip. The icon is the only thing that
            // changes hue, so the bar has exactly one accent on it at a time —
            // which is what keeps the three-colour rule affordable now that
            // every icon brings its own palette.
            color: isSelected ? colors.card : colors.surfaceMuted,
            borderRadius: AppRadius.pill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full colour on both chips. With no tint left to dim, an
              // unselected chip is distinguished by its label and its ground,
              // not by a quieter icon — and two full-colour icons side by side
              // is what makes the bar read as a set of places to go.
              AppIcon(icon, isMuted: !isSelected),
              const SizedBox(width: AppSpacing.xs),
              // Full ink on both chips. The muted grey measures 3.9:1 on the
              // quiet surface, under the 4.5:1 the art direction demands, and
              // dimming the label was never carrying the state anyway — the
              // greyed icon is.
              Text(
                label,
                style: AppTypography.label.copyWith(color: colors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
