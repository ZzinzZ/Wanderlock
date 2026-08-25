import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/app/lenses/lens_switcher.dart';
import 'package:wanderlock/app/screens/checkpoint_sheet.dart';
import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_map_canvas.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_marker_overlay.dart';
import 'package:wanderlock/features/collection/presentation/stamp_album.dart';
import 'package:wanderlock/features/fog/presentation/fog_layer.dart';
import 'package:wanderlock/features/unlock/application/check_in_controller.dart';
import 'package:wanderlock/features/unlock/domain/check_in_service.dart';
import 'package:wanderlock/features/unlock/presentation/unlock_moment.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The product screen: one map, seen through whichever lens is selected.
///
/// **The map is built once and never rebuilt on a lens change.** Everything a
/// lens contributes is an overlay above it or a MapLibre layer inside it, so
/// switching keeps the camera exactly where the user left it — which is the
/// F5 requirement, and also the argument: it is the same map, the same
/// unlocks, seen differently.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  MapLibreMapController? _controller;

  /// Counts style loads, and is the key the map layers are mounted under.
  ///
  /// A style reload — which is what a theme change is — throws away every
  /// layer added at runtime, while the widgets that added them stay mounted
  /// and none the wiser. Switching to light mode duly produced a map with no
  /// fog and no markers on it.
  ///
  /// Incrementing this remounts the layer widgets, so they install onto the
  /// style that now exists. Driving it from the callback rather than from the
  /// brightness is what gets the ordering right: the new style is up by the
  /// time anything tries to add to it.
  int _styleGeneration = 0;

  Checkpoint? _selected;

  /// The place currently having its three seconds. Held here rather than read
  /// from the check-in state so the animation cannot be cut short by the
  /// controller being reset underneath it.
  Checkpoint? _celebrating;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final lens = ref.watch(lensProvider);
    final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
    final visitedIds = ref.watch(visitedCheckpointIdsProvider);
    final holes = ref.watch(fogHolesProvider);

    // Content is pulled once, here, because this is the first screen. Watched
    // rather than read so the outcome is not thrown away.
    ref.watch(contentBootstrapProvider);

    ref.listen(checkInControllerProvider, _onCheckInChanged);

    final controller = _controller;
    final canDrawLayers = controller != null && _styleGeneration > 0;

    return Scaffold(
      body: Stack(
        children: [
          CheckpointMapCanvas(
            onControllerReady: (value) => setState(() => _controller = value),
            onStyleLoaded: () => setState(() => _styleGeneration++),
            onMapTapped: (_) => setState(() => _selected = null),
          ),

          if (canDrawLayers) ...[
            FogLayer(
              key: ValueKey('fog-$_styleGeneration'),
              controller: controller,
              holes: holes,
              isVisible: lens == Lens.fog,
            ),
            // Widgets, not a map layer — see CheckpointMarkerOverlay for why.
            // They no longer wait for the fog: nothing MapLibre draws can end
            // up on top of a Flutter widget, so the ordering race is gone.
            Positioned.fill(
              child: CheckpointMarkerOverlay(
                controller: controller,
                fallbackCamera: CheckpointMapCanvas.initialCamera,
                checkpoints: checkpoints,
                visitedIds: visitedIds,
                onTap: (checkpoint) => setState(() => _selected = checkpoint),
              ),
            ),
          ],

          // The collection lens. Drawn over the map rather than instead of it,
          // which is what keeps the switch instant and the camera intact.
          IgnorePointer(
            ignoring: lens != Lens.collection,
            child: AnimatedOpacity(
              opacity: lens == Lens.collection ? 1 : 0,
              duration: AppMotion.lensSwitch,
              curve: AppMotion.linearCurve,
              child: ColoredBox(
                color: colors.background,
                child: SafeArea(
                  child: StampAlbum(stamps: ref.watch(stampsProvider)),
                ),
              ),
            ),
          ),

          if (!AppConfig.hasSupabase) const _StandInBanner(),

          const Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: Center(child: LensSwitcher()),
          ),

          // Only over the map. The sheet describes a place you tapped on the
          // map, and it kept floating over the album after a lens switch —
          // a card about a pin, on a screen with no pins.
          if (_selected != null && lens == Lens.fog)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xxl + AppSpacing.xl,
              child: CheckpointSheet(
                checkpoint: _selected!,
                isVisited: visitedIds.contains(_selected!.id),
                onDismiss: () => setState(() => _selected = null),
              ),
            ),

          if (_celebrating != null)
            UnlockMoment(
              placeName: _celebrating!.name,
              photoUrl: _celebrating!.photoUrl,
              onCompleted: () {
                ref.read(checkInControllerProvider.notifier).acknowledge();
                setState(() => _celebrating = null);
              },
            ),
        ],
      ),
      floatingActionButton: lens == Lens.fog ? const MapFollowButton() : null,
      // Rebuilt only when the lens changes, so the tooltip and semantics of
      // the map controls do not linger over the album.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // No AppBar. The album writes its own heading, with the progress line
      // under it, and a bar above that repeated the same word twice.
    );
  }

  /// Reacts to whatever the authority answered.
  ///
  /// The unlock moment starts here and not where the button was pressed: it
  /// celebrates `visit_state` changing, and the only thing allowed to change
  /// it is a grant coming back.
  void _onCheckInChanged(CheckInState? previous, CheckInState next) {
    final outcome = next.outcome;
    if (outcome == null) return;

    switch (outcome) {
      case CheckInGranted():
        final checkpoint = _selected;
        if (checkpoint == null || checkpoint.id != next.checkpointId) return;
        setState(() {
          _celebrating = checkpoint;
          _selected = null;
        });
      case CheckInTooFar(:final distanceMeters, :final radiusMeters):
        _say(
          AppLocalizations.of(
            context,
          ).checkInTooFar(distanceMeters.round(), radiusMeters),
        );
        ref.read(checkInControllerProvider.notifier).acknowledge();
      case CheckInUnavailable():
        _say(AppLocalizations.of(context).checkInUnavailable);
        ref.read(checkInControllerProvider.notifier).acknowledge();
      case CheckInRejected(:final reason):
        _say(AppLocalizations.of(context).checkInRejected(reason));
        ref.read(checkInControllerProvider.notifier).acknowledge();
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Says out loud that this build has no server behind it.
///
/// A demonstration that quietly looks like the real thing is how a stand-in
/// ends up being mistaken for a verified unlock. It is cheap to label and
/// expensive to explain later.
class _StandInBanner extends StatelessWidget {
  const _StandInBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return SafeArea(
      child: Align(
        // Top right. Top centre sat on the collection's heading and bottom
        // left ran into the lens switcher, which is wider than it looks.
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.accentYellow,
              borderRadius: AppRadius.pill,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.standInModeBadge,
                style: AppTypography.label.copyWith(
                  color: colors.onAccentYellow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
