import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/app/lenses/journey_panel.dart';
import 'package:wanderlock/app/lenses/lens.dart';
import 'package:wanderlock/app/lenses/lens_providers.dart';
import 'package:wanderlock/app/lenses/lens_switcher.dart';
import 'package:wanderlock/app/lenses/map_filter.dart';
import 'package:wanderlock/app/screens/checkpoint_sheet.dart';
import 'package:wanderlock/app/screens/explore_hud.dart';
import 'package:wanderlock/app/screens/explore_overlays.dart';
import 'package:wanderlock/app/screens/map_filter_button.dart';
import 'package:wanderlock/app/screens/pan_exploration.dart';
import 'package:wanderlock/core/config/app_config.dart';
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
import 'package:wanderlock/features/story/domain/story_chapter.dart';
import 'package:wanderlock/features/story/presentation/story_player.dart';
import 'package:wanderlock/features/unlock/application/check_in_controller.dart';
import 'package:wanderlock/features/unlock/domain/check_in_service.dart';
import 'package:wanderlock/features/unlock/presentation/unlock_moment.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The product screen: one map, seen through whichever lens is selected.
///
/// **The map is built once and never rebuilt on a lens change.** Every lens is
/// an overlay above it, so switching keeps the camera where the user left it:
/// the same map, the same unlocks, seen differently.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  MapLibreMapController? _controller;

  /// Counts style loads, and keys the overlays so a style reload remounts
  /// them. A reload — a theme change — discards every layer added at runtime
  /// while the widgets that added them stay mounted and none the wiser. Driven
  /// from the callback, not the brightness, so the new style is up first.
  int _styleGeneration = 0;

  Checkpoint? _selected;

  /// The place currently having its three seconds. Held here rather than read
  /// from the check-in state, which can reset mid-animation.
  Checkpoint? _celebrating;

  /// With no server, dragging the map walks a stand-in player and arrivals go
  /// through the same check-in path a real one would.
  ///
  /// Never with a server: sending the camera as a position would be a cheat
  /// compiled into the product.
  static bool get _exploresByPanning => !AppConfig.hasSupabase;

  /// Checkpoints already asked about during this pan-exploration, so hovering
  /// inside a radius does not fire a check-in on every frame.
  final Set<String> _askedWhilePanning = {};

  /// Where the pan explorer was on the previous camera frame.
  TrailPoint? _lastPanPoint;

  /// Where the pan explorer stands. Moved by drags, never by zooms — see
  /// [panStepFor]. Once a zoom settles the camera glides back to it.
  final ValueNotifier<TrailPoint?> _explorer = ValueNotifier(null);

  LatLng? _lastCentre;
  double? _lastZoom;
  bool _zoomedThisGesture = false;

  /// True while the camera glides back after a zoom: that movement is the
  /// camera's, not the player's, and must not walk them.
  bool _isRecentring = false;
  bool _recentringHasMoved = false;

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

    switch (panStepFor(
      centre: centre,
      zoom: camera.zoom,
      lastCentre: lastCentre,
      lastZoom: lastZoom,
      explorer: _explorer.value,
    )) {
      // Setting the explorer down is not arriving: the default camera sits
      // inside the radius of a place in the city centre.
      case PanSetDown(:final at):
        _walkTo(at, mayUnlock: false);
      case PanWalk(:final to):
        _walkTo(to);
      case PanZoomed():
        _zoomedThisGesture = true;
    }

    if (_zoomedThisGesture && !controller.isCameraMoving) {
      _zoomedThisGesture = false;
      _recentre(controller);
    }
  }

  void _walkTo(TrailPoint point, {bool mayUnlock = true}) {
    _explorer.value = point;
    if (!mayUnlock) _lastPanPoint = point;
    _explore(point.latitude, point.longitude, mayUnlock: mayUnlock);
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
    // What the filter hides cannot be tapped: a pin nobody can see is not a
    // target. Arrival below is the opposite case and deliberately unfiltered.
    final checkpoints = ref.read(visibleCheckpointsProvider);
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

  /// The explorer is at this point: clear the fog there, and — when the
  /// position is the pan stand-in — ask about whatever radius it crossed into.
  void _explore(double latitude, double longitude, {required bool mayUnlock}) {
    ref.read(fogTrailControllerProvider.notifier).record(latitude, longitude);
    if (!mayUnlock) return;

    final here = TrailPoint(latitude: latitude, longitude: longitude);
    final arrival = arrivalBetween(
      from: _lastPanPoint ?? here,
      here: here,
      checkpoints: ref.read(checkpointsProvider).value ?? const [],
      visited: ref.read(visitedCheckpointIdsProvider),
      asked: _askedWhilePanning,
      isCelebrating: _celebrating != null,
    );
    _lastPanPoint = here;
    if (arrival == null) return;

    ref
        .read(checkInControllerProvider.notifier)
        .checkIn(
          checkpointId: arrival.checkpoint.id,
          latitude: arrival.at.latitude,
          longitude: arrival.at.longitude,
        );
  }

  /// A route rather than another overlay: the chapter is somewhere you leave
  /// the map for, so the system back gesture should close it.
  void _openStory(StoryChapter chapter, Checkpoint checkpoint) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryPlayer(
          chapter: chapter,
          placeName: checkpoint.name,
          landmark: ref.read(landmarkLookupProvider)(checkpoint.id),
        ),
      ),
    );
  }

  /// A lens laid over the map rather than instead of it, which keeps a switch
  /// instant and the camera untouched. Stays mounted while hidden so it keeps
  /// its scroll position and can fade.
  Widget _lensOverlay({
    required Lens lens,
    required Lens shown,
    required Widget child,
  }) {
    return IgnorePointer(
      ignoring: lens != shown,
      child: AnimatedOpacity(
        opacity: lens == shown ? 1 : 0,
        duration: AppMotion.lensSwitch,
        curve: AppMotion.linearCurve,
        child: PatternBackground(child: SafeArea(child: child)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lens = ref.watch(lensProvider);
    final checkpoints = ref.watch(visibleCheckpointsProvider);
    final visitedIds = ref.watch(visitedCheckpointIdsProvider);

    // Watched, not read, so the first screen does not throw the outcome away.
    ref.watch(contentBootstrapProvider);

    ref.listen(checkInControllerProvider, _onCheckInChanged);

    final controller = _controller;
    final canDrawLayers = controller != null && _styleGeneration > 0;

    return Scaffold(
      body: Stack(
        children: [
          CheckpointMapCanvas(
            onControllerReady: _attach,
            // A real fix clears fog but never unlocks: that is the check-in's.
            onUserLocationUpdated: (latitude, longitude) =>
                _explore(latitude, longitude, mayUnlock: false),
            onStyleLoaded: () => setState(() => _styleGeneration++),
            onMapTapped: _onMapTapped,
          ),

          if (canDrawLayers) ...[
            if (lens == Lens.fog)
              // Its own Consumer: the trail grows on every step of a pan, and
              // rebuilding the whole screen for it is what made panning stutter.
              Positioned.fill(
                child: RepaintBoundary(
                  child: Consumer(
                    builder: (context, ref, _) => FogOverlay(
                      controller: controller,
                      fallbackCamera: CheckpointMapCanvas.initialCamera,
                      // Clearings from `visit_state`, plus the walked trail.
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
            if (_exploresByPanning && lens == Lens.fog)
              Positioned.fill(
                child: IgnorePointer(
                  child: ExplorerLayer(
                    controller: controller,
                    explorer: _explorer,
                  ),
                ),
              ),
          ],

          _lensOverlay(
            lens: lens,
            shown: Lens.collection,
            child: StampAlbum(
              stamps: ref.watch(stampsProvider),
              landmarkOf: ref.watch(landmarkLookupProvider),
            ),
          ),

          _lensOverlay(
            lens: lens,
            shown: Lens.journey,
            child: const JourneyPanel(),
          ),

          // Over the map only: the album and the journey carry their own
          // banner, and a second header above it says the same thing twice.
          if (lens == Lens.fog)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md - 2,
                  AppSpacing.sm,
                  AppSpacing.md - 2,
                  0,
                ),
                // Stacked under the HUD, not offset from the top: the HUD's
                // height is its own business.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExploreHud(),
                    SizedBox(height: AppSpacing.sm),
                    MapFilterButton(),
                  ],
                ),
              ),
            ),

          // In every lens: the label has to stay visible wherever the user
          // is, and the top of each lens belongs to a HUD or a banner.
          if (!AppConfig.hasSupabase)
            const Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.aboveLensBar,
              child: StandInBanner(),
            ),

          // Gutters: the bar is not intrinsically sized and would otherwise
          // run edge to edge.
          const Positioned(
            left: AppSpacing.md - 2,
            right: AppSpacing.md - 2,
            bottom: AppSpacing.lg,
            child: LensSwitcher(),
          ),

          // Above the bar, not in the Scaffold's floating slot: with three
          // chips the bar reaches the right edge and they would overlap.
          if (lens == Lens.fog && _selected == null)
            const Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.aboveLensBar,
              child: MapFollowButton(),
            ),

          // Only over the map: it describes a pin, and the album has none.
          if (_selected != null && lens == Lens.fog)
            Positioned(
              left: AppSpacing.md - 2,
              right: AppSpacing.md - 2,
              bottom: AppSpacing.aboveLensBar,
              child: CheckpointSheet(
                checkpoint: _selected!,
                isVisited: visitedIds.contains(_selected!.id),
                onDismiss: () => setState(() => _selected = null),
                onReadStory: (chapter) => _openStory(chapter, _selected!),
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
      // No floatingActionButton and no AppBar: the follow button is placed in
      // the stack above, and each lens writes its own heading.
    );
  }

  /// Reacts to whatever the authority answered. The unlock moment starts
  /// here, not at the button: it celebrates `visit_state` changing, and only a
  /// grant coming back can change that.
  void _onCheckInChanged(CheckInState? previous, CheckInState next) {
    final outcome = next.outcome;
    if (outcome == null) return;

    final l10n = AppLocalizations.of(context);
    // Exhaustive over the sealed outcome, so a new kind of answer cannot be
    // added without this screen being made to say what it does about it.
    final refusal = switch (outcome) {
      CheckInGranted() => null,
      CheckInTooFar(:final distanceMeters, :final radiusMeters) =>
        l10n.checkInTooFar(distanceMeters.round(), radiusMeters),
      CheckInUnavailable() => l10n.checkInUnavailable,
      CheckInRejected(:final reason) => l10n.checkInRejected(reason),
    };

    if (refusal != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(refusal)));
      ref.read(checkInControllerProvider.notifier).acknowledge();
      return;
    }

    // Granted. The outcome is left standing for the animation to acknowledge.
    final checkpoint = (ref.read(checkpointsProvider).value ?? const [])
        .where((candidate) => candidate.id == next.checkpointId)
        .firstOrNull;
    if (checkpoint == null) return;
    setState(() {
      _celebrating = checkpoint;
      _selected = null;
    });
  }
}
