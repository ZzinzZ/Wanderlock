import 'dart:async';
import 'dart:io';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:wanderlock/features/checkpoint/domain/map_cache_region.dart';

/// Thrown when a download finishes without having fetched anything.
///
/// Its own type because the engine reports success for an empty region just as
/// cheerfully as for a full one, and a banner saying the map is saved when it
/// is not is worse than no banner at all.
class EmptyDownloadException implements Exception {
  const EmptyDownloadException();

  @override
  String toString() =>
      'EmptyDownloadException: the region completed without downloading '
      'any resources, so nothing was actually saved';
}

/// Downloads the pilot area's tiles so the map still draws with the radio off.
///
/// MapLibre's own ambient cache already holds whatever has been on screen.
/// This is the other half: a deliberate download made before leaving, covering
/// ground not yet looked at, which the engine will not evict.
class MapTileCache {
  const MapTileCache();

  /// Metadata key stamped on our region, so a later download replaces the
  /// previous one instead of stacking a second copy beside it.
  static const _regionNameKey = 'wanderlock.region';
  static const _regionName = 'pilot';

  /// OpenFreeMap's vector tiles stop at zoom 14, and MapLibre over-zooms that
  /// tile for closer views, so z14 is genuinely the whole map.
  static const maxZoom = 14.0;

  /// Below this the city is a smudge and there is nothing to walk to.
  static const minZoom = 10.0;

  /// Replaces any previously downloaded region with one covering [bounds].
  ///
  /// One style is enough for both themes: light and dark differ in paint
  /// alone, and it is the resources that get cached, not the colours.
  ///
  /// Throws [EmptyDownloadException] if it fetches nothing.
  Future<void> download({
    required GeoBounds bounds,
    required String styleJson,
    void Function(double progress)? onProgress,
  }) async {
    await _removePreviousRegion();

    final server = await _StyleServer.start(styleJson);
    var requiredResources = 0;

    // `downloadOfflineRegion` resolves as soon as the platform has accepted
    // the region, not when the tiles have arrived — the outcome comes back
    // through onEvent. Awaiting the wrong one closed the style server before
    // MapLibre had fetched from it, and the download died with a connection
    // error to our own port.
    final finished = Completer<void>();
    void settle([Object? error]) {
      if (finished.isCompleted) return;
      error == null ? finished.complete() : finished.completeError(error);
    }

    try {
      await downloadOfflineRegion(
        OfflineRegionDefinition(
          bounds: LatLngBounds(
            southwest: LatLng(bounds.south, bounds.west),
            northeast: LatLng(bounds.north, bounds.east),
          ),
          mapStyleUrl: server.url,
          minZoom: minZoom,
          maxZoom: maxZoom,
        ),
        metadata: const {_regionNameKey: _regionName},
        onEvent: (event) {
          switch (event) {
            case InProgress():
              requiredResources = event.requiredResourceCount;
              onProgress?.call(event.progress / 100);
            case Success():
              settle();
            case Error():
              settle(event.cause);
          }
        },
      );
      await finished.future;
    } finally {
      await server.close();
    }

    // A region that required nothing means the style never loaded, which the
    // engine reports as a completed download. Found the hard way: a `file://`
    // style URL is handed to the HTTP stack on Android, fails to parse, and
    // the region completes instantly with zero tiles.
    if (requiredResources == 0) throw const EmptyDownloadException();
  }

  /// Whether a region has already been downloaded.
  Future<bool> hasRegion() async => (await _ourRegions()).isNotEmpty;

  Future<void> _removePreviousRegion() async {
    for (final region in await _ourRegions()) {
      await deleteOfflineRegion(region.id);
    }
    // Tiles shared with the ambient cache survive deleteOfflineRegion, which
    // is what we want: dropping the region must not blank a map on screen.
  }

  Future<List<OfflineRegion>> _ourRegions() async {
    final regions = await getListOfRegions();
    return regions
        .where((region) => region.metadata[_regionNameKey] == _regionName)
        .toList();
  }
}

/// Serves the generated style to MapLibre over loopback for one download.
///
/// The offline API takes a style *URL*, and on Android it resolves that URL
/// through the HTTP stack alone: `file://` and `asset://` never reach a file
/// source. A bundled second copy would work but would fork the style into two
/// documents kept in step by hand, and would ignore `MAP_TILES_URL`. So the
/// style is served from this process to this process, for a few seconds.
class _StyleServer {
  _StyleServer(this._server, this.url);

  final HttpServer _server;
  final String url;

  static Future<_StyleServer> start(String styleJson) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = 'http://127.0.0.1:${server.port}/style.json';

    // Every path answers with the style: MapLibre asks for exactly this one
    // URL, and a router here would be ceremony around a single response.
    server.listen((request) async {
      request.response
        ..headers.contentType = ContentType.json
        ..write(styleJson);
      await request.response.close();
    }, onError: (_) {});

    return _StyleServer(server, url);
  }

  Future<void> close() => _server.close(force: true);
}
