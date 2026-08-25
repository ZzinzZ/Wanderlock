import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/features/collection/domain/stamp.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The collection lens.
///
/// Exists to be the second lens: something that is unmistakably not the map,
/// reading the same `visit_state`, so "one arrival, every way of playing" can
/// be watched rather than argued about. Unlock a place in the fog lens and its
/// stamp is already coloured in here, with nothing to press in between.
///
/// The art direction allows this screen to be denser and more cheerful than
/// the rest of the app, which is why the tiles are close-packed where every
/// other surface is airy.
class StampAlbum extends StatelessWidget {
  const StampAlbum({required this.stamps, super.key});

  final List<Stamp> stamps;

  /// Widest a tile may get before the grid adds a column. Chosen so a phone
  /// shows three across and a tablet more, without a breakpoint list.
  static const double maxTileWidth = 132;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final owned = stamps.where((stamp) => stamp.isOwned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.md,
            AppSpacing.pageGutter,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.collectionTitle, style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                stamps.isEmpty
                    ? l10n.collectionEmpty
                    : l10n.collectionProgress(owned, stamps.length),
                style: AppTypography.label.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              0,
              AppSpacing.pageGutter,
              AppSpacing.lg,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxTileWidth,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.sm,
              // Room under the square for exactly two lines of name.
              childAspectRatio: 0.72,
            ),
            itemCount: stamps.length,
            itemBuilder: (context, index) => _StampTile(stamp: stamps[index]),
          ),
        ),
      ],
    );
  }
}

class _StampTile extends StatelessWidget {
  const _StampTile({required this.stamp});

  final Stamp stamp;

  /// How grey a stamp nobody has earned looks.
  ///
  /// Not fully transparent and not fully grey: section 8 of the art direction
  /// asks for "desaturated, low contrast" rather than hidden. A locked stamp
  /// has to stay legible enough to want.
  static const double lockedOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Semantics(
      label: stamp.name,
      value: stamp.isOwned
          ? l10n.checkpointUnlockedLabel
          : l10n.checkpointLockedLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A square, always. Letting the tile stretch to fill whatever the
          // name left over made every row a different height — twelve stamps
          // that should read as a set looked like twelve unrelated cards.
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: AppMotion.standard,
              curve: AppMotion.linearCurve,
              decoration: BoxDecoration(
                borderRadius: AppRadius.chip,
                color: stamp.isOwned
                    ? colors.primary
                    : colors.inkMuted.withValues(alpha: lockedOpacity),
              ),
              alignment: Alignment.center,
              child: AppIcon(
                stamp.isOwned ? AppIcons.lensCollection : AppIcons.locked,
                size: AppIconSize.tile,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Fixed room for the caption, so a one-line name and a two-line name
          // leave their squares at the same size.
          Expanded(
            child: Text(
              stamp.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                color: stamp.isOwned ? colors.ink : colors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
