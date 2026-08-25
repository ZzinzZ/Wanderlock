import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/core/config/app_config.dart';
import 'package:wanderlock/design/map/map_style.dart';
import 'package:wanderlock/features/checkpoint/application/map_cache_providers.dart';
import 'package:wanderlock/features/checkpoint/presentation/checkpoint_map_canvas.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// The bare base map, kept from F3.
///
/// The product screen is the lens shell; this one stays because it is the
/// place to look at the map style on its own, with no fog over it and no
/// markers on it — which is exactly what is needed when the question is
/// whether the style itself is right.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final cache = ref.watch(mapCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            onPressed: cache is MapCacheDownloading
                ? null
                : () => ref
                      .read(mapCacheProvider.notifier)
                      .download(
                        MapStyle.toJson(
                          tilesUrl: AppConfig.mapTilesUrl,
                          glyphsUrl: AppConfig.mapGlyphsUrl,
                          brightness: brightness,
                        ),
                      ),
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: l10n.mapCacheDownload,
          ),
        ],
      ),
      floatingActionButton: const MapFollowButton(),
      body: const CheckpointMapCanvas(),
    );
  }
}
