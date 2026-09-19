import 'package:flutter/material.dart';

import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/sticker_button.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/itinerary/domain/itinerary_entry.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The itinerary lens: the user's own order, draggable.
///
/// The one lens that writes. What it writes is an intention — see
/// [ItineraryEntry] — and the tick beside a visited stop is still read from
/// `visit_state`, so nothing here can mark a place as reached.
class ItineraryEditor extends StatelessWidget {
  const ItineraryEditor({
    required this.entries,
    required this.onReorder,
    required this.onRemove,
    required this.onClear,
    super.key,
  });

  final List<ItineraryEntry> entries;

  /// Receives the complete new order. See `ItineraryController.reorder` for
  /// why the whole list rather than a from/to pair.
  final ValueChanged<List<String>> onReorder;

  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          child: StickerSurface(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(AppIcons.lensJourney, size: AppIconSize.tile),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.itineraryEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.hudTitle.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.itineraryEmptyHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.itineraryCount(entries.length),
                  style: AppTypography.tab.copyWith(color: colors.ink),
                ),
              ),
              StickerButton(
                variant: StickerButtonVariant.secondary,
                onPressed: onClear,
                label: l10n.itineraryClear,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              0,
              AppSpacing.pageGutter,
              AppSpacing.lg,
            ),
            itemCount: entries.length,
            // `onReorderItem`, not the deprecated `onReorder`: the older
            // callback reported `newIndex` counted before the dragged row was
            // lifted out, so every caller had to subtract one on a downward
            // move. This one has already done that.
            onReorderItem: (oldIndex, newIndex) {
              final ids = [for (final entry in entries) entry.checkpointId];
              ids.insert(newIndex, ids.removeAt(oldIndex));
              onReorder(ids);
            },
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _EntryRow(
                // Keyed by the place, not the index: a ReorderableListView
                // keyed by position animates the wrong row back after a drag.
                key: ValueKey(entry.checkpointId),
                entry: entry,
                ordinal: index + 1,
                onRemove: () => onRemove(entry.checkpointId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.ordinal,
    required this.onRemove,
    super.key,
  });

  final ItineraryEntry entry;
  final int ordinal;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: entry.name,
        value: entry.isVisited
            ? l10n.checkpointUnlockedLabel
            : l10n.checkpointLockedLabel,
        child: StickerSurface(
          depth: AppSticker.depthSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              // The stop number as a yellow sticker, like a quest step.
              Container(
                width: AppIconSize.inline + 6,
                height: AppIconSize.inline + 6,
                decoration: BoxDecoration(
                  color: colors.accentYellow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outline,
                    width: AppSticker.stroke,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$ordinal',
                  style: AppTypography.badge.copyWith(
                    color: colors.onAccentYellow,
                    fontSize: AppTypography.tab.fontSize! + 2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              // A tick only where `visit_state` says so. There is no way to
              // put one here by hand, which is the whole argument of the
              // architecture standing in a single widget.
              if (entry.isVisited)
                const AppIcon(AppIcons.visited, size: AppIconSize.inline)
              else
                const AppIcon(
                  AppIcons.revealed,
                  size: AppIconSize.inline,
                  isMuted: true,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  entry.name,
                  style: AppTypography.hudTitle.copyWith(color: colors.ink),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: l10n.itineraryRemove,
                icon: const AppIcon(
                  AppIcons.removeFromItinerary,
                  size: AppIconSize.inline,
                ),
              ),
              ReorderableDragStartListener(
                index: ordinal - 1,
                // clay-icon-gap: the 120-icon set has no drag handle, and
                // no other glyph in it reads as "grab this row". The grip
                // is the one control here whose whole job is to look like
                // the platform convention.
                child: Icon(Icons.drag_handle, color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
