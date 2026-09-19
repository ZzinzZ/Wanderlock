import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/app/lenses/journey_panel.dart';
import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/app/lenses/lens_switcher.dart';
import 'package:wanderlock/app/screens/checkpoint_sheet.dart';
import 'package:wanderlock/app/screens/explore_hud.dart';
import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/core/map/map_projection.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/pattern_background.dart';
import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_icons.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_map_canvas.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_marker_overlay.dart';
import 'package:wanderlock/features/collection/presentation/stamp_album.dart';
import 'package:wanderlock/features/fog/application/fog_trail_providers.dart';
import 'package:wanderlock/features/fog/domain/fog_trail.dart';
import 'package:wanderlock/features/fog/presentation/fog_overlay.dart';
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
  /// Clear of the lens bar: its height (a lifted chip, an icon, a label and
  /// the sticker padding round them) plus the gap it floats at.
  static const double _aboveLensBar =
      AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xl;

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

  /// Explore by panning: in a build with no server, a point on the map stands
  /// in for the player. Dragging the map walks it; wherever it goes the fog
  /// clears, and passing through a checkpoint's radius asks for a check-in
  /// exactly as a real arrival would — through the same controller, to the
  /// stand-in authority, which measures the distance itself.
  ///
  /// Never in a build with a server: there, sending the camera as a position
  /// would be a cheat compiled into the product.
  static bool get _exploresByPanning => !AppConfig.hasSupabase;

  /// Checkpoints already asked about during this pan-exploration, so hovering
  /// inside a radius does not fire a check-in on every frame.
  final Set<String> _askedWhilePanning = {};

  /// Where the pan explorer stands.
  ///
  /// **Moved by drags, never by zooms.** It used to simply be the centre of
  /// the map, and a pinch zooms about the point between the fingers — so the
  /// centre, and with it the player, slid across the city whenever the user
  /// zoomed. Now a frame whose zoom changed moves nothing, a frame whose zoom
  /// held moves the explorer by exactly the drag, and once a zoom settles the
  /// camera glides back to wherever the explorer is standing.
  final ValueNotifier<TrailPoint?> _explorer = ValueNotifier(null);

  LatLng? _lastCentre;
  double? _lastZoom;
  bool _zoomedThisGesture = false;

  /// True while the camera is gliding back to the explorer after a zoom. That
  /// movement is the camera's, not the player's, and must not walk them.
  bool _isRecentring = false;
  bool _recentringHasMoved = false;

  /// Below this a change in zoom is rounding in the reported camera rather
  /// than the user zooming.
  static const double _zoomTolerance = 0.001;

  Future<void> _attach(MapLibreMapController controller) async {
    setState(() => _controller = controller);
    if (!_exploresByPanning) return;

    // Start where the last session ended, so the trail resumes from the
    // explorer's feet rather than drawing a road from the city centre to it.
    final last = await ref.read(fogTrailControllerProvider.notifier).resume();
    if (last != null) {
      await controller.moveCamera(
        CameraUpdate.newLatLng(LatLng(last.latitude, last.longitude)),
      );
    }
    if (!mounted) return;
    controller.addListener(_onCameraMoved);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onCameraMoved);
    _explorer.dispose();
    super.dispose();
  }

  void _onCameraMoved() {
    final controller = _controller;
    final camera = controller?.cameraPosition;
    if (controller == null || camera == null) return;

    final centre = camera.target;
    final lastCentre = _lastCentre;
    final lastZoom = _lastZoom;
    _lastCentre = centre;
    _lastZoom = camera.zoom;

    if (_isRecentring) {
      if (controller.isCameraMoving) {
        _recentringHasMoved = true;
      } else if (_recentringHasMoved) {
        _isRecentring = false;
      }
      return;
    }

    final explorer = _explorer.value;
    if (explorer == null || lastCentre == null || lastZoom == null) {
      _walkTo(centre.latitude, centre.longitude);
    } else if ((camera.zoom - lastZoom).abs() > _zoomTolerance) {
      _zoomedThisGesture = true;
    } else {
      _walkTo(
        explorer.latitude + centre.latitude - lastCentre.latitude,
        explorer.longitude + centre.longitude - lastCentre.longitude,
      );
    }

    if (_zoomedThisGesture && !controller.isCameraMoving) {
      _zoomedThisGesture = false;
      _recentre(controller);
    }
  }

  void _walkTo(double latitude, double longitude) {
    _explorer.value = TrailPoint(latitude: latitude, longitude: longitude);
    _explore(latitude, longitude, mayUnlock: true);
  }

  Future<void> _recentre(MapLibreMapController controller) async {
    final explorer = _explorer.value;
    if (explorer == null) return;
    _isRecentring = true;
    _recentringHasMoved = false;
    await controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(explorer.latitude, explorer.longitude)),
    );
    // A glide too short to report any movement never sends the idle that
    // would end it, so end it here when the camera has already stopped.
    if (!controller.isCameraMoving) _isRecentring = false;
  }

  /// Taps land on the map, never on the markers — see
  /// [CheckpointMarkerOverlay] — so the map works out which marker was hit.
  void _onMapTapped(LatLng position) {
    final camera = _controller?.cameraPosition;
    final checkpoints = ref.read(checkpointsProvider).value ?? const [];
    final hit = camera == null
        ? null
        : CheckpointMarkerOverlay.checkpointAt(
            camera: camera,
            size: MediaQuery.sizeOf(context),
            checkpoints: checkpoints,
            latitude: position.latitude,
            longitude: position.longitude,
          );
    setState(() => _selected = hit);
  }

  /// Where the pan explorer was on the previous camera frame.
  TrailPoint? _lastPanPoint;

  /// The explorer is at this point: clear the fog there, and — when the
  /// position is the pan stand-in — try the checkpoint whose radius it passed
  /// through.
  ///
  /// "Passed through", not "is in": the map reports only a handful of camera
  /// positions per swipe, so a quick drag across a checkpoint can jump from
  /// one side of its 60 m radius to the other without a single sample inside.
  /// Each step is checked as the segment it is, and the check-in is sent from
  /// the point on it nearest the checkpoint — somewhere the explorer really
  /// went, which the stand-in authority then measures for itself.
  void _explore(double latitude, double longitude, {required bool mayUnlock}) {
    ref.read(fogTrailControllerProvider.notifier).record(latitude, longitude);
    if (!mayUnlock) return;

    final here = TrailPoint(latitude: latitude, longitude: longitude);
    final from = _lastPanPoint ?? here;
    _lastPanPoint = here;
    // A jump is not a walk: nothing between the two ends was visited.
    final isJump = FogTrail.distanceMeters(from, here) > FogTrail.maxJoinMeters;

    final visited = ref.read(visitedCheckpointIdsProvider);
    final checkpoints = ref.read(checkpointsProvider).value ?? const [];
    for (final checkpoint in checkpoints) {
      if (visited.contains(checkpoint.id)) continue;
      final target = TrailPoint(
        latitude: checkpoint.latitude,
        longitude: checkpoint.longitude,
      );
      final nearest = isJump
          ? here
          : FogTrail.nearestOnSegment(from, here, target);
      if (FogTrail.distanceMeters(nearest, target) > checkpoint.radiusMeters) {
        _askedWhilePanning.remove(checkpoint.id);
        continue;
      }
      if (_celebrating != null || !_askedWhilePanning.add(checkpoint.id)) {
        continue;
      }
      ref
          .read(checkInControllerProvider.notifier)
          .checkIn(
            checkpointId: checkpoint.id,
            latitude: nearest.latitude,
            longitude: nearest.longitude,
          );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lens = ref.watch(lensProvider);
    final checkpoints = ref.watch(checkpointsProvider).value ?? const [];
    final visitedIds = ref.watch(visitedCheckpointIdsProvider);

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
            onControllerReady: _attach,
            // A real fix clears fog wherever the phone actually goes, in
            // every build. It never unlocks: that stays with the check-in.
            onUserLocationUpdated: (latitude, longitude) =>
                _explore(latitude, longitude, mayUnlock: false),
            onStyleLoaded: () => setState(() => _styleGeneration++),
            onMapTapped: _onMapTapped,
          ),

          if (canDrawLayers) ...[
            if (lens == Lens.fog)
              // A Consumer of its own: the trail grows on every step of a pan,
              // and rebuilding the whole screen for it was a large part of
              // why panning stuttered.
              Positioned.fill(
                child: RepaintBoundary(
                  child: Consumer(
                    builder: (context, ref, _) => FogOverlay(
                      controller: controller,
                      fallbackCamera: CheckpointMapCanvas.initialCamera,
                      // Checkpoint clearings from `visit_state`, plus the
                      // trail the explorer has walked or panned.
                      holes: [
                        ...ref.watch(fogHolesProvider),
                        ...ref.watch(fogTrailHolesProvider),
                      ],
                    ),
                  ),
                ),
              ),
            // Widgets, not a map layer — see CheckpointMarkerOverlay for why.
            // They no longer wait for the fog: nothing MapLibre draws can end
            // up on top of a Flutter widget, so the ordering race is gone.
            Positioned.fill(
              child: RepaintBoundary(
                child: CheckpointMarkerOverlay(
                  controller: controller,
                  fallbackCamera: CheckpointMapCanvas.initialCamera,
                  checkpoints: checkpoints,
                  visitedIds: visitedIds,
                  onTap: (checkpoint) => setState(() => _selected = checkpoint),
                ),
              ),
            ),
            // The explorer, pinned to the centre of the map while panning
            // stands in for walking.
            if (_exploresByPanning && lens == Lens.fog)
              Positioned.fill(
                child: IgnorePointer(
                  child: _ExplorerLayer(
                    controller: controller,
                    explorer: _explorer,
                  ),
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
              child: PatternBackground(
                child: SafeArea(
                  child: StampAlbum(
                    stamps: ref.watch(stampsProvider),
                    landmarkOf: CheckpointIcons.landmarkOfId,
                  ),
                ),
              ),
            ),
          ),

          // The journey lens. Same treatment as the album: drawn over the map,
          // never instead of it, so the camera underneath is untouched.
          IgnorePointer(
            ignoring: lens != Lens.journey,
            child: AnimatedOpacity(
              opacity: lens == Lens.journey ? 1 : 0,
              duration: AppMotion.lensSwitch,
              curve: AppMotion.linearCurve,
              child: const PatternBackground(
                child: SafeArea(child: JourneyPanel()),
              ),
            ),
          ),

          // The game HUD, over the map only: the album and the journey carry
          // their own banner, and a second header above it said the same
          // thing twice.
          if (lens == Lens.fog)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md - 2,
                  AppSpacing.sm,
                  AppSpacing.md - 2,
                  0,
                ),
                child: ExploreHud(),
              ),
            ),

          // Bottom left, just above the lens bar, in every lens: the label
          // has to stay visible wherever the user is, and the top of every
          // lens now belongs to a HUD or a banner.
          if (!AppConfig.hasSupabase)
            const Positioned(
              left: AppSpacing.md,
              bottom: _aboveLensBar,
              child: _StandInBanner(),
            ),

          // Gutters on both sides: the bar is no longer intrinsically sized,
          // so without them it would run edge to edge on the map.
          const Positioned(
            left: AppSpacing.md - 2,
            right: AppSpacing.md - 2,
            bottom: AppSpacing.lg,
            child: LensSwitcher(),
          ),

          // The follow button, above the bar rather than in the Scaffold's own
          // slot. With three chips the bar reaches the right edge, and the
          // floating slot put the button straight on top of the third one.
          if (lens == Lens.fog && _selected == null)
            const Positioned(
              right: AppSpacing.md,
              bottom: _aboveLensBar,
              child: MapFollowButton(),
            ),

          // Only over the map. The sheet describes a place you tapped on the
          // map, and it kept floating over the album after a lens switch —
          // a card about a pin, on a screen with no pins.
          if (_selected != null && lens == Lens.fog)
            Positioned(
              left: AppSpacing.md - 2,
              right: AppSpacing.md - 2,
              bottom: _aboveLensBar,
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
              landmark: CheckpointIcons.landmarkOf(_celebrating!),
              onCompleted: () {
                ref.read(checkInControllerProvider.notifier).acknowledge();
                setState(() => _celebrating = null);
              },
            ),
        ],
      ),
      // No floatingActionButton. The follow button is positioned in the stack
      // above, so it can sit clear of a lens bar that now spans the screen.
      //
      // No AppBar either. The album writes its own heading, with the progress
      // line under it, and a bar above that repeated the same word twice.
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
        // Either the place tapped on the map, or one reached by panning.
        final checkpoint = (ref.read(checkpointsProvider).value ?? const [])
            .where((candidate) => candidate.id == next.checkpointId)
            .firstOrNull;
        if (checkpoint == null) return;
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentYellow,
        borderRadius: AppRadius.pill,
        border: Border.all(color: colors.outline, width: AppSticker.strokeThin),
        boxShadow: AppShadows.sticker(colors, depth: AppSticker.depthSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          l10n.standInModeBadge,
          style: AppTypography.tag.copyWith(color: colors.onAccentYellow),
        ),
      ),
    );
  }
}

/// Where the explorer stands while panning plays the part of walking: the
/// same blue dot the map draws for a real position.
class _ExplorerPuck extends StatelessWidget {
  const _ExplorerPuck();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: AppIconSize.inline,
      height: AppIconSize.inline,
      decoration: BoxDecoration(
        color: colors.info,
        shape: BoxShape.circle,
        border: Border.all(color: colors.card, width: AppSticker.strokeHeavy),
        boxShadow: AppShadows.sticker(colors, depth: AppSticker.depthSmall),
      ),
    );
  }
}

/// Draws the pan explorer where it stands on the map — usually the centre,
/// but not while a zoom is under way, which is the point: zooming does not
/// move the player.
class _ExplorerLayer extends StatelessWidget {
  const _ExplorerLayer({required this.controller, required this.explorer});

  final MapLibreMapController controller;
  final ValueListenable<TrailPoint?> explorer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([controller, explorer]),
        builder: (context, _) {
          final camera =
              controller.cameraPosition ?? CheckpointMapCanvas.initialCamera;
          final at = explorer.value;
          final projection = MapProjection(
            centerLatitude: camera.target.latitude,
            centerLongitude: camera.target.longitude,
            zoom: camera.zoom,
            widthPixels: constraints.maxWidth,
            heightPixels: constraints.maxHeight,
          );
          final screen = at == null
              ? (x: constraints.maxWidth / 2, y: constraints.maxHeight / 2)
              : projection.toScreen(at.latitude, at.longitude);

          return Stack(
            children: [
              Positioned(
                left: screen.x - AppIconSize.inline / 2,
                top: screen.y - AppIconSize.inline / 2,
                child: const _ExplorerPuck(),
              ),
            ],
          );
        },
      ),
    );
  }
}
