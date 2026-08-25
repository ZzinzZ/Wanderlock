import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/design/widgets/primary_button.dart';
import 'package:wanderlock/features/checkpoint/application/location_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_icons.dart';
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

    return Material(
      color: colors.card,
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // The same icon the marker on the map is wearing, at the
                // size that makes it the subject of the sheet rather than a
                // bullet beside the title.
                AppIcon(
                  CheckpointIcons.of(checkpoint),
                  size: AppIconSize.place,
                  isMuted: !isVisited,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(checkpoint.name, style: AppTypography.cardTitle),
                ),
                IconButton(
                  onPressed: onDismiss,
                  // clay-icon-gap: no close glyph in the clay set; a rotated
                  // plus reads as a hack rather than as a control.
                  icon: const Icon(Icons.close),
                  color: colors.inkMuted,
                ),
              ],
            ),
            if (checkpoint.address != null)
              Text(
                checkpoint.address!,
                style: AppTypography.label.copyWith(color: colors.inkMuted),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // The tick is green and the padlock is amber in the artwork
                // itself, which is the same story the old tinted icons told.
                AppIcon(
                  isVisited ? AppIcons.visited : AppIcons.locked,
                  size: AppIconSize.inline,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isVisited
                      ? l10n.checkpointUnlockedLabel
                      : l10n.checkpointLockedLabel,
                  style: AppTypography.label.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
            if (!isVisited) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                key: const Key('unlock-checkpoint'),
                label: l10n.checkpointUnlockAction,
                onPressed: isBusy ? null : () => _requestCheckIn(ref),
              ),
            ],
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
