import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/design/tokens/tokens.dart';
import 'package:wanderlock/features/checkpoint/application/map_cache_providers.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The base map.
///
/// F3's job is to make this look like our product rather than a map
/// provider's demo. Checkpoint markers arrive once there are verified
/// coordinates and processed photographs to put on them.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  /// Ho Chi Minh City centre. A starting camera, not a claim about where the
  /// user is — that arrives with location permission in F4.
  static const _initialCamera = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final cache = ref.watch(mapCacheProvider);

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
      body: Column(
        children: [
          if (cache is! MapCacheIdle) _CacheBanner(state: cache),
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
            ),
          ),
        ],
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
