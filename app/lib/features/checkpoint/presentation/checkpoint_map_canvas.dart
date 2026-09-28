import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';
import 'package:wanderlock/features/checkpoint/application/location_providers.dart';
import 'package:wanderlock/features/checkpoint/application/map_cache_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/user_location.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The map surface, with the two banners that explain why it might be limited.
///
/// Extracted so more than one screen can show the same map without a second
/// copy of the location and offline logic. It hands its controller out through
/// [onControllerReady] and says when the style is up through [onStyleLoaded],
/// because a layer added before the style exists is silently dropped.
class CheckpointMapCanvas extends ConsumerWidget {
  const CheckpointMapCanvas({
    this.onControllerReady,
    this.onStyleLoaded,
    this.onMapTapped,
    this.onUserLocationUpdated,
    super.key,
  });

  /// Ho Chi Minh City centre. A starting camera, not a claim about where the
  /// user is — the dot appears only once they ask for it.
  static const initialCamera = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 13,
  );

  final void Function(MapLibreMapController controller)? onControllerReady;
  final VoidCallback? onStyleLoaded;
  final void Function(LatLng position)? onMapTapped;

  /// Every fix the map receives for the device, as plain coordinates.
  final void Function(double latitude, double longitude)? onUserLocationUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final cache = ref.watch(mapCacheProvider);
    final location = ref.watch(userLocationProvider).value;
    final following = ref.watch(cameraFollowProvider) == CameraFollow.following;

    final styleJson = MapStyle.toJson(
      tilesUrl: AppConfig.mapTilesUrl,
      glyphsUrl: AppConfig.mapGlyphsUrl,
      brightness: brightness,
    );

    return Column(
      children: [
        if (cache is! MapCacheIdle) MapCacheBanner(state: cache),
        if (location is LocationBlocked || location is LocationServiceOff)
          MapLocationBanner(availability: location!),
        Expanded(
          child: MapLibreMap(
            // Rebuilt when the theme changes, which is what gives dark mode
            // its own map instead of a tinted copy of the light one.
            styleString: styleJson,
            initialCameraPosition: initialCamera,
            // Nothing in this product is served by tilting or rotating the
            // map, and both make a fog overlay considerably harder to draw
            // correctly.
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            // Without this the controller never reports the camera, and
            // everything drawn over the map in Flutter — markers, fog, the
            // pan explorer — stays pinned where the map first opened while
            // the tiles slide away underneath. Found on the first real pan.
            trackCameraPosition: true,
            // Drawing the dot needs permission in hand. Asking the map to
            // show it without permission gets a silent nothing.
            myLocationEnabled: location is LocationReady,
            myLocationTrackingMode: following
                ? MyLocationTrackingMode.tracking
                : MyLocationTrackingMode.none,
            // myLocationRenderMode stays at its default of `normal`, which
            // is a plain dot with no heading arrow. The compass and GPS
            // render modes rotate the map, and rotation is off above.
            //
            // The map reports when a drag has taken the camera off the
            // user's location. Without this the button would go on claiming
            // to follow while the map sat where it was dragged.
            onCameraTrackingDismissed: () =>
                ref.read(cameraFollowProvider.notifier).stop(),
            onMapCreated: onControllerReady,
            onStyleLoadedCallback: onStyleLoaded,
            onMapClick: (point, latLng) => onMapTapped?.call(latLng),
            onUserLocationUpdated: (location) => onUserLocationUpdated?.call(
              location.position.latitude,
              location.position.longitude,
            ),
          ),
        ),
      ],
    );
  }
}

/// Centres the map on the user, or does whatever has to happen first.
///
/// One button rather than a permission prompt on arrival: a dialog that
/// appears merely because a screen was opened teaches people to dismiss it.
/// This one asks only after the user has said what they want.
class MapFollowButton extends ConsumerWidget {
  const MapFollowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final availability = ref.watch(userLocationProvider).value;
    final following = ref.watch(cameraFollowProvider) == CameraFollow.following;

    // Null while the first permission read is still in flight. Treated as
    // "ask", because that is what it turns out to be on a fresh install.
    // Two clay icons rather than three Material ones. The set has no
    // "location disabled" glyph, and inventing one from a crossed-out pin was
    // not worth it: the shield already says "something is in the way", which
    // is the only distinction the button needs to make.
    final (icon, tooltip) = switch (availability) {
      LocationReady() when following => (
        AppIcons.myLocation,
        l10n.mapFollowStop,
      ),
      LocationReady() => (AppIcons.myLocation, l10n.mapFollowStart),
      LocationBlocked() => (AppIcons.warning, l10n.mapLocationBlocked),
      LocationServiceOff() => (AppIcons.warning, l10n.mapLocationServiceOff),
      LocationNeedsPermission() ||
      null => (AppIcons.myLocation, l10n.mapLocationAsk),
    };

    // A square sticker rather than a Material FAB: outline and hard shadow,
    // like every other control floating on the map (section 0). The icon
    // carries the state — full colour while the camera is locked to the
    // user, grey when it is not.
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => _onPressed(ref, availability),
          child: Container(
            width: AppIconSize.place,
            height: AppIconSize.place,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: colors.outline,
                width: AppSticker.stroke,
              ),
              boxShadow: AppShadows.sticker(colors),
            ),
            alignment: Alignment.center,
            child: AppIcon(icon, isMuted: !following),
          ),
        ),
      ),
    );
  }

  Future<void> _onPressed(
    WidgetRef ref,
    LocationAvailability? availability,
  ) async {
    final follow = ref.read(cameraFollowProvider.notifier);
    final location = ref.read(userLocationProvider.notifier);

    switch (availability) {
      case LocationReady():
        if (ref.read(cameraFollowProvider) == CameraFollow.following) {
          follow.stop();
        } else {
          follow.follow();
        }
      case LocationBlocked():
        await location.openAppSettings();
      case LocationServiceOff():
        await location.openLocationSettings();
      case LocationNeedsPermission():
      case null:
        // Start following only if the answer was yes. Moving the camera after
        // a refusal would be the app arguing with the user.
        if (await location.requestPermission()) follow.follow();
    }
  }
}

/// Explains the two obstacles the button cannot clear on its own, because the
/// fix for both of them lives outside the app.
class MapLocationBanner extends StatelessWidget {
  const MapLocationBanner({required this.availability, super.key});

  final LocationAvailability availability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return ColoredBox(
      color: colors.accentYellow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          availability is LocationBlocked
              ? l10n.mapLocationBlockedBanner
              : l10n.mapLocationServiceOffBanner,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: colors.onAccentYellow),
        ),
      ),
    );
  }
}

/// Says what the download is doing, above the map rather than over it: a
/// message floating on the map is a message competing with the map.
class MapCacheBanner extends StatelessWidget {
  const MapCacheBanner({required this.state, super.key});

  final MapCacheState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    final (text, background, foreground) = switch (state) {
      MapCacheDownloading(:final progress) => (
        l10n.mapCacheDownloading((progress * 100).round()),
        colors.accentYellow,
        colors.onAccentYellow,
      ),
      MapCacheReady() => (l10n.mapCacheReady, colors.surfaceMuted, colors.ink),
      MapCacheEmpty() => (
        l10n.mapCacheEmpty,
        colors.accentYellow,
        colors.onAccentYellow,
      ),
      MapCacheFailed() => (l10n.mapCacheFailed, colors.coral, colors.ink),
      MapCacheIdle() => ('', colors.accentYellow, colors.onAccentYellow),
    };

    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: foreground),
        ),
      ),
    );
  }
}
