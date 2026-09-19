import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/landmark_art.dart';
import 'package:wanderlock/design/widgets/primary_button.dart';
import 'package:wanderlock/design/widgets/sticker_button.dart';
import 'package:wanderlock/design/widgets/sticker_surface.dart';
import 'package:wanderlock/features/checkpoint/application/location_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_icons.dart';
import 'package:wanderlock/features/itinerary/application/itinerary_providers.dart';
import 'package:wanderlock/features/unlock/application/check_in_controller.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// What a tapped checkpoint says about itself, and the one action it offers.
///
/// Lives in `app/` rather than in either feature: it shows a `Checkpoint`,
/// reads unlock state, and asks `unlock` for a check-in. A feature holding all
/// three would be a feature that knows too much.
class CheckpointSheet extends ConsumerWidget {
  const CheckpointSheet({
    required this.checkpoint,
    required this.isVisited,
    required this.onDismiss,
    super.key,
  });

  final Checkpoint checkpoint;

  /// Read from `visit_state` by the caller. Never stored here — a sheet that
  /// remembered whether a place was unlocked would be a second answer.
  final bool isVisited;

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final checkIn = ref.watch(checkInControllerProvider);
    final isBusy = checkIn.isInFlight && checkIn.checkpointId == checkpoint.id;

    // A sticker card, not a Material sheet: outline and hard shadow, so it
    // holds its own on top of the map — section 0 of the art direction.
    return Material(
      type: MaterialType.transparency,
      child: StickerSurface(
        borderRadius: AppRadius.hero,
        depth: AppSticker.depthLarge,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The same building sticker the marker wears, larger: the
                // subject of the card rather than a bullet beside the title.
                Container(
                  width: AppIconSize.tile,
                  height: AppIconSize.tile,
                  decoration: BoxDecoration(
                    color: isVisited
                        ? colors.highlightSurface
                        : colors.lockedSurface,
                    borderRadius: AppRadius.chip,
                    border: Border.all(
                      color: colors.outline,
                      width: AppSticker.stroke,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: LandmarkImage(
                    CheckpointIcons.landmarkOf(checkpoint),
                    size: AppIconSize.place + AppSpacing.xs,
                    isMuted: !isVisited,
                  ),
                ),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkpoint.name,
                        style: AppTypography.placeTitle.copyWith(
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      _StatusChip(isVisited: isVisited),
                    ],
                  ),
                ),
                _CloseButton(onPressed: onDismiss),
              ],
            ),
            if (checkpoint.address != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                checkpoint.address!,
                style: AppTypography.label.copyWith(color: colors.inkMuted),
              ),
            ],
            if (!isVisited) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                key: const Key('unlock-checkpoint'),
                label: l10n.checkpointUnlockAction,
                icon: AppIcons.unlock,
                isLarge: true,
                onPressed: isBusy ? null : () => _requestCheckIn(ref),
              ),
            ],

            // Offered whether or not the place is visited. A finished stop
            // still belongs on a plan someone is building for a friend, and
            // hiding the button once it is unlocked would make the plan a
            // to-do list rather than an itinerary.
            const SizedBox(height: AppSpacing.sm),
            _AddToPlanButton(checkpointId: checkpoint.id),
          ],
        ),
      ),
    );
  }

  /// Sends where we think we are and waits to be told.
  ///
  /// The two builds take deliberately separate paths.
  ///
  /// With a server, the device is asked for a fix and that fix is sent; no fix
  /// means no request at all. A client that quietly substituted the
  /// destination for the user's position would be a cheat compiled into the
  /// product, and one the server could not see through. Detecting a *forged*
  /// position is F4's separate job — shipping the forgery ourselves is not
  /// something a detector could excuse.
  ///
  /// Without a server, the device is not asked at all. The stand-in measures
  /// against the checkpoint either way, so a GPS read would change nothing
  /// except to raise a system Location Accuracy dialog on every unlock — which
  /// it duly did, on the emulator, before this was split in two.
  Future<void> _requestCheckIn(WidgetRef ref) async {
    final controller = ref.read(checkInControllerProvider.notifier);

    if (!AppConfig.hasSupabase) {
      await controller.checkIn(
        checkpointId: checkpoint.id,
        latitude: checkpoint.latitude,
        longitude: checkpoint.longitude,
      );
      return;
    }

    final position = await ref
        .read(userLocationProvider.notifier)
        .readPosition();
    if (position == null) {
      controller.reportNoFix(checkpoint.id);
      return;
    }

    await controller.checkIn(
      checkpointId: checkpoint.id,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

/// Puts a place on the user's plan, or says it is already there.
///
/// A separate widget so the sheet does not rebuild its whole body when the
/// plan changes underneath it.
class _AddToPlanButton extends ConsumerWidget {
  const _AddToPlanButton({required this.checkpointId});

  final String checkpointId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOnPlan = ref.watch(isOnItineraryProvider(checkpointId));

    return StickerButton(
      variant: StickerButtonVariant.secondary,
      onPressed: isOnPlan
          ? null
          : () => ref.read(itineraryControllerProvider).add(checkpointId),
      icon: isOnPlan ? AppIcons.visited : AppIcons.addToItinerary,
      label: isOnPlan ? l10n.itineraryAdded : l10n.itineraryAdd,
    );
  }
}

/// Locked or reached, as a small sticker under the name.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isVisited});

  final bool isVisited;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isVisited ? colors.card : colors.lockedSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.strokeThin),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs / 2,
          AppSpacing.sm + 2,
          AppSpacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The tick is green and the padlock amber in the artwork itself.
            AppIcon(
              isVisited ? AppIcons.visited : AppIcons.locked,
              size: AppIconSize.inline,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isVisited
                  ? l10n.checkpointUnlockedLabel
                  : l10n.checkpointLockedLabel,
              style: AppTypography.tag.copyWith(color: colors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round sticker with a cross.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).closeButtonLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: AppIconSize.navigation,
          height: AppIconSize.navigation,
          decoration: BoxDecoration(
            color: colors.card,
            shape: BoxShape.circle,
            border: Border.all(color: colors.outline, width: AppSticker.stroke),
            boxShadow: AppShadows.sticker(colors, depth: AppSticker.depthSmall),
          ),
          alignment: Alignment.center,
          // clay-icon-gap: no close glyph in the clay set; a rotated
          // plus reads as a hack rather than as a control.
          child: Icon(Icons.close, color: colors.ink, size: AppIconSize.inline),
        ),
      ),
    );
  }
}
