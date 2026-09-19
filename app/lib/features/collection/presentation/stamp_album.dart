import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/sticker_progress.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/collection/domain/stamp.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The collection lens: a sticker album.
///
/// Exists to be the second lens: something that is unmistakably not the map,
/// reading the same `visit_state`, so "one arrival, every way of playing" can
/// be watched rather than argued about. Unlock a place in the fog lens and its
/// stamp is already coloured in here, with nothing to press in between.
///
/// Drawn on the album's own backing sheet — see `PatternBackground`, which the
/// composition layer puts behind it.
class StampAlbum extends StatefulWidget {
  const StampAlbum({required this.stamps, required this.landmarkOf, super.key});

  final List<Stamp> stamps;

  /// Which [LandmarkArt] a stamp shows. Passed in rather than looked up here:
  /// the mapping belongs to the checkpoint feature, and this feature is not
  /// allowed to import it.
  final String Function(String checkpointId) landmarkOf;

  /// Widest a tile may get before the grid adds a column. Chosen so a phone
  /// shows three across and a tablet more, without a breakpoint list.
  static const double maxTileWidth = 140;

  @override
  State<StampAlbum> createState() => _StampAlbumState();
}

enum _Filter { all, owned, missing }

class _StampAlbumState extends State<StampAlbum> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stamps = widget.stamps;
    final owned = stamps.where((stamp) => stamp.isOwned).length;
    final shown = [
      for (var i = 0; i < stamps.length; i++)
        if (switch (_filter) {
          _Filter.all => true,
          _Filter.owned => stamps[i].isOwned,
          _Filter.missing => !stamps[i].isOwned,
        })
          (i, stamps[i]),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md - 2,
          ),
          sliver: SliverList.list(
            children: [
              _Banner(title: l10n.collectionTitle),
              const SizedBox(height: AppSpacing.md - 2),
              if (stamps.isEmpty)
                _EmptyNote(message: l10n.collectionEmpty)
              else
                _ProgressCard(stamps: stamps, owned: owned),
              const SizedBox(height: AppSpacing.md - 2),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (filter, label) in <(_Filter, String)>[
                    (_Filter.all, l10n.collectionFilterAll(stamps.length)),
                    (_Filter.owned, l10n.collectionFilterOwned(owned)),
                    (
                      _Filter.missing,
                      l10n.collectionFilterMissing(stamps.length - owned),
                    ),
                  ])
                    _FilterChip(
                      label: label,
                      isSelected: filter == _filter,
                      onSelected: () => setState(() => _filter = filter),
                    ),
                ],
              ),
            ],
          ),
        ),
        SliverPadding(
          // The bottom inset is room for the lens bar, which floats over the
          // album; without it the last row of stamps sits under the bar.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: StampAlbum.maxTileWidth,
              mainAxisSpacing: AppSpacing.md - 2,
              crossAxisSpacing: AppSpacing.sm + 2,
              // Room under the building for two lines of name and a date.
              childAspectRatio: 0.8,
            ),
            itemCount: shown.length,
            itemBuilder: (context, index) {
              final (position, stamp) = shown[index];
              return _StampTile(
                stamp: stamp,
                art: widget.landmarkOf(stamp.checkpointId),
                // Lean alternates by position in the full album, not in the
                // filtered view, so a stamp keeps its angle when filtering.
                tilt: switch (position % 3) {
                  0 => -AppSticker.tilt,
                  1 => AppSticker.tilt * 0.8,
                  _ => -AppSticker.tilt * 0.5,
                },
                fill: _fills[position % _fills.length](AppColors.of(context)),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Earned stamps cycle through the decorative fills, so a full album reads
  /// as a sheet of different stamps rather than twelve copies of one.
  static final List<Color Function(AppColors)> _fills = [
    (c) => c.highlightSurface,
    (c) => c.infoSurface,
    (c) => c.decorativeMint,
    (c) => c.card,
  ];
}

/// The title of a full-screen lens, as a yellow ribbon.
class _Banner extends StatelessWidget {
  const _Banner({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StickerSurface(
      color: colors.accentYellow,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIcon(AppIcons.lensCollection),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: AppTypography.banner.copyWith(color: colors.onAccentYellow),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stamps, required this.owned});

  static const int _maxSegments = 24;

  final List<Stamp> stamps;
  final int owned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return StickerSurface(
      padding: const EdgeInsets.all(AppSpacing.md - 4),
      child: Row(
        children: [
          const AppIcon(AppIcons.trophy, size: AppIconSize.place + 4),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$owned',
                      style: AppTypography.display.copyWith(color: colors.ink),
                    ),
                    Text(
                      ' / ${stamps.length}',
                      style: AppTypography.badge.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        l10n.collectionReached,
                        style: AppTypography.label.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                // One pill per place reads at a glance up to a couple of
                // dozen; past that it turns into a hatched stripe.
                if (stamps.length <= _maxSegments)
                  StickerSegments(
                    total: stamps.length,
                    done: {
                      for (var i = 0; i < stamps.length; i++)
                        if (stamps[i].isOwned) i,
                    },
                  )
                else
                  StickerProgressBar(value: owned / stamps.length),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.linearCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentYellow : colors.card,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: colors.outline,
              width: AppSticker.strokeThin,
            ),
            boxShadow: AppShadows.sticker(colors, depth: AppSticker.depthSmall),
          ),
          child: Text(
            label,
            style: AppTypography.tab.copyWith(
              color: isSelected ? colors.onAccentYellow : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _StampTile extends StatelessWidget {
  const _StampTile({
    required this.stamp,
    required this.art,
    required this.tilt,
    required this.fill,
  });

  final Stamp stamp;
  final String art;
  final double tilt;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Semantics(
      label: stamp.name,
      value: stamp.isOwned
          ? l10n.checkpointUnlockedLabel
          : l10n.checkpointLockedLabel,
      child: Transform.rotate(
        angle: tilt,
        child: StickerSurface(
          color: stamp.isOwned ? fill : colors.lockedSurface,
          borderRadius: AppRadius.chip,
          depth: stamp.isOwned ? AppSticker.depth + 1 : AppSticker.depthSmall,
          isPerforated: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm - 2,
            AppSpacing.sm + 2,
            AppSpacing.sm - 2,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Section 8: "colour returns to where you have been".
                    LandmarkImage(
                      art,
                      size: AppIconSize.place,
                      isMuted: !stamp.isOwned,
                    ),
                    if (!stamp.isOwned)
                      const Positioned(
                        right: AppSpacing.xs,
                        bottom: 0,
                        child: AppIcon(
                          AppIcons.locked,
                          size: AppIconSize.inline,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                stamp.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.tag.copyWith(color: colors.ink),
              ),
              if (!stamp.isOwned)
                Text(
                  l10n.stampNotYet,
                  style: AppTypography.tag.copyWith(color: colors.inkMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StickerSurface(
      child: Text(
        message,
        style: AppTypography.body.copyWith(color: colors.ink),
      ),
    );
  }
}
