import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/checkpoint/application/location_providers.dart';
import 'package:wanderlock/features/checkpoint/application/map_cache_providers.dart';
import 'package:wanderlock/features/checkpoint/domain/user_location.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The base map.
///
/// F3's job is to make this look like our product rather than a map
/// provider's demo. Checkpoint markers arrive once there are verified
/// coordinates and processed photographs to put on them.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  /// Ho Chi Minh City centre. A starting camera, not a claim about where the
  /// user is — the dot appears only once they ask for it.
  static const _initialCamera = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final cache = ref.watch(mapCacheProvider);
    final location = ref.watch(userLocationProvider).value;
    final following = ref.watch(cameraFollowProvider) == CameraFollow.following;

    final styleJson = MapStyle.toJson(
      tilesUrl: AppConfig.mapTilesUrl,
      glyphsUrl: AppConfig.mapGlyphsUrl,
      brightness: brightness,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            onPressed: cache is MapCacheDownloading
                ? null
                : () => ref.read(mapCacheProvider.notifier).download(styleJson),
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: l10n.mapCacheDownload,
          ),
        ],
      ),
      floatingActionButton: _FollowButton(availability: location),
      body: Column(
        children: [
          if (cache is! MapCacheIdle) _CacheBanner(state: cache),
          if (location is LocationBlocked || location is LocationServiceOff)
            _LocationBanner(availability: location!),
          Expanded(
            child: MapLibreMap(
              // Rebuilt when the theme changes, which is what gives dark mode
              // its own map instead of a tinted copy of the light one.
              styleString: styleJson,
              initialCameraPosition: _initialCamera,
              // Nothing in this product is served by tilting or rotating the
              // map, and both make a fog overlay considerably harder to draw
              // correctly.
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
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
              // The camera's trackingCompass and trackingGps modes are out for
              // the same reason, which leaves `tracking` as the only usable
              // follow mode.
              //
              // The map reports when a drag has taken the camera off the
              // user's location. Without this the button would go on claiming
              // to follow while the map sat where it was dragged.
              onCameraTrackingDismissed: () =>
                  ref.read(cameraFollowProvider.notifier).stop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centres the map on the user, or does whatever has to happen first.
///
/// One button rather than a permission prompt on arrival: a dialog that
/// appears merely because a screen was opened teaches people to dismiss it.
/// This one asks only after the user has said what they want.
class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.availability});

  final LocationAvailability? availability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final following = ref.watch(cameraFollowProvider) == CameraFollow.following;

    // Null while the first permission read is still in flight. Treated as
    // "ask", because that is what it turns out to be on a fresh install.
    final (icon, tooltip) = switch (availability) {
      LocationReady() when following => (Icons.my_location, l10n.mapFollowStop),
      LocationReady() => (Icons.my_location, l10n.mapFollowStart),
      LocationBlocked() => (Icons.location_disabled, l10n.mapLocationBlocked),
      LocationServiceOff() => (
        Icons.location_disabled,
        l10n.mapLocationServiceOff,
      ),
      LocationNeedsPermission() ||
      null => (Icons.location_searching, l10n.mapLocationAsk),
    };

    return FloatingActionButton(
      onPressed: () => _onPressed(ref),
      tooltip: tooltip,
      backgroundColor: following ? colors.primary : colors.card,
      foregroundColor: colors.ink,
      child: Icon(icon),
    );
  }

  Future<void> _onPressed(WidgetRef ref) async {
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
class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.availability});

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
class _CacheBanner extends StatelessWidget {
  const _CacheBanner({required this.state});

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
      MapCacheReady() => (l10n.mapCacheReady, colors.primary, colors.ink),
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
