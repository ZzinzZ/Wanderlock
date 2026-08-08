import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/features/checkpoint/application/checkpoint_providers.dart';
import 'package:wanderlock/features/checkpoint/data/map_tile_cache.dart';
import 'package:wanderlock/features/checkpoint/domain/map_cache_region.dart';

/// Where the offline download has got to.
sealed class MapCacheState {
  const MapCacheState();
}

/// Nothing running. The map still draws whatever the ambient cache holds.
class MapCacheIdle extends MapCacheState {
  const MapCacheIdle();
}

/// [progress] runs 0 to 1.
class MapCacheDownloading extends MapCacheState {
  const MapCacheDownloading(this.progress);

  final double progress;
}

class MapCacheReady extends MapCacheState {
  const MapCacheReady();
}

/// No checkpoints, so there is no region to work out. Its own state rather
/// than a silent no-op: a button that does nothing when pressed reads as a
/// broken button.
class MapCacheEmpty extends MapCacheState {
  const MapCacheEmpty();
}

/// Held rather than thrown: a failed download is a thing the user should be
/// told about and be able to retry, not a crash.
class MapCacheFailed extends MapCacheState {
  const MapCacheFailed(this.error);

  final Object error;
}

final mapTileCacheProvider = Provider<MapTileCache>(
  (ref) => const MapTileCache(),
);

/// Drives the deliberate, before-you-leave download.
///
/// The region is computed from the checkpoints on every run rather than stored,
/// so adding a place — or finally verifying its coordinates — changes what gets
/// downloaded without anyone remembering to update a constant.
class MapCacheController extends Notifier<MapCacheState> {
  @override
  MapCacheState build() => const MapCacheIdle();

  /// [styleJson] comes from the caller because which theme is on screen is a
  /// UI question, and the download needs a concrete style document.
  Future<void> download(String styleJson) async {
    if (state is MapCacheDownloading) return;

    final checkpoints = ref.read(checkpointsProvider).value ?? const [];
    final bounds = cacheRegionFor(checkpoints);

    // No checkpoints means no region. Saying so beats downloading a default
    // box that happens to be somewhere else entirely.
    if (bounds == null) {
      state = const MapCacheEmpty();
      return;
    }

    state = const MapCacheDownloading(0);
    try {
      await ref
          .read(mapTileCacheProvider)
          .download(
            bounds: bounds,
            styleJson: styleJson,
            onProgress: (progress) {
              state = MapCacheDownloading(progress);
            },
          );
      state = const MapCacheReady();
    } on Object catch (error) {
      state = MapCacheFailed(error);
    }
  }
}

final mapCacheProvider = NotifierProvider<MapCacheController, MapCacheState>(
  MapCacheController.new,
);
