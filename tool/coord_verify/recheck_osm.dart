// Re-checks every authored coordinate against OpenStreetMap, the place it came
// from, and writes what a human still has to look at.
//
// Why this exists: 265 places were imported from OpenStreetMap in one pass, and
// nobody can review that many satellite tiles without a reason to look. This
// narrows the pile. It answers the cheap question — "is the coordinate still
// what the source says?" — so the expensive question — "does it point at the
// right building?" — only has to be asked where it might matter.
//
// It does NOT decide `verified`. Agreeing with OpenStreetMap proves the import
// copied correctly, not that OpenStreetMap is right; a volunteer's guess copied
// faithfully is still a guess. Only a person looking at imagery sets verified,
// which is what tool/coord_verify's page is for. This file feeds that page.
//
// Usage, from the repository root:
//   dart run tool/coord_verify/recheck_osm.dart
//
// Writes tool/coord_verify/osm_recheck.json. Needs the network.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../support/repo_root.dart';

/// Overpass rejects one query carrying every id at once with a gateway
/// timeout, so ids go up in batches with a pause between them. The public
/// endpoint is a shared free service; hammering it is how you get blocked.
const int _batchSize = 50;
const Duration _pauseBetweenBatches = Duration(seconds: 2);
const int _attemptsPerBatch = 5;

/// How far the authored coordinate may sit from the source before a human
/// should look. Below this, the gap is polygon-centroid noise.
const double _movedThresholdMetres = 30;

const String _endpoint = 'https://overpass-api.de/api/interpreter';

/// Ground distance in metres. Equirectangular: at city scale the error against
/// the haversine is far below the tens of metres this tool reasons about.
double metresBetween(double aLat, double aLon, double bLat, double bLon) {
  const metresPerDegree = 111320.0;
  final meanLatitude = (aLat + bLat) / 2 * math.pi / 180;
  final dy = (bLat - aLat) * metresPerDegree;
  final dx = (bLon - aLon) * metresPerDegree * math.cos(meanLatitude);
  return math.sqrt(dx * dx + dy * dy);
}

/// One element as OpenStreetMap holds it today.
class OsmElement {
  const OsmElement({
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  final String kind;
  final double latitude;
  final double longitude;
  final String? name;

  /// A way or relation is drawn as a shape, so its centre is computed from the
  /// outline. A node is a single point somebody dropped by hand — the same
  /// coordinate carries much less confidence.
  bool get isBareNode => kind == 'node';
}

/// The reason a place is worth a human's attention, or null when it is not.
///
/// Ordered: a place that both moved and is a bare node is reported as moved,
/// because that is the stronger signal.
String? flagFor({
  required double authoredLat,
  required double authoredLon,
  required String authoredName,
  required OsmElement live,
}) {
  final drift = metresBetween(
    authoredLat,
    authoredLon,
    live.latitude,
    live.longitude,
  );
  if (drift > _movedThresholdMetres) return 'moved';
  if (live.isBareNode) return 'dot';

  final sourceName = live.name?.trim();
  if (sourceName != null &&
      sourceName.isNotEmpty &&
      sourceName != authoredName.trim() &&
      !authoredName.startsWith(sourceName)) {
    return 'name';
  }
  return null;
}

Future<List<Object?>> _ask(HttpClient client, String query) async {
  for (var attempt = 1; attempt <= _attemptsPerBatch; attempt++) {
    try {
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers
        ..set('User-Agent', 'Wanderlock-coord-recheck/1.0')
        ..set('Content-Type', 'application/x-www-form-urlencoded');
      request.write('data=${Uri.encodeQueryComponent(query)}');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return (jsonDecode(body) as Map<String, Object?>)['elements']! as List;
    } on Exception catch (error) {
      stdout.writeln('  ... thử lại ($error)');
      await Future<void>.delayed(Duration(seconds: 10 * attempt));
    }
  }
  stderr.writeln(
    'recheck_osm: Overpass không trả lời sau $_attemptsPerBatch lần.',
  );
  exit(1);
}

Future<void> main() async {
  final root = repoRootPath();
  final sourceFile = File('$root/content/checkpoints.json');
  final outputFile = File('$root/tool/coord_verify/osm_recheck.json');

  final decoded =
      jsonDecode(sourceFile.readAsStringSync()) as Map<String, Object?>;
  final checkpoints = (decoded['checkpoints']! as List)
      .cast<Map<String, Object?>>();

  // Grouped by kind because Overpass asks for nodes, ways and relations in
  // separate clauses.
  final byKind = <String, List<String>>{};
  final byRef = <String, Map<String, Object?>>{};
  for (final checkpoint in checkpoints) {
    final coordinates = checkpoint['coordinates'] as Map<String, Object?>?;
    final source = coordinates?['source'] as String?;
    if (source == null || !source.startsWith('openstreetmap:')) continue;
    final ref = source.split(':')[1];
    final kind = ref.split('/')[0];
    byKind.putIfAbsent(kind, () => []).add(ref.split('/')[1]);
    byRef[ref] = checkpoint;
  }

  final client = HttpClient();
  final live = <String, OsmElement>{};
  try {
    final batches = <MapEntry<String, List<String>>>[];
    for (final entry in byKind.entries) {
      for (var i = 0; i < entry.value.length; i += _batchSize) {
        final end = math.min(i + _batchSize, entry.value.length);
        batches.add(MapEntry(entry.key, entry.value.sublist(i, end)));
      }
    }

    for (var i = 0; i < batches.length; i++) {
      final batch = batches[i];
      stdout.writeln(
        'lô ${i + 1}/${batches.length} (${batch.key} x${batch.value.length})',
      );
      final elements = await _ask(
        client,
        '[out:json][timeout:180];'
        '${batch.key}(id:${batch.value.join(',')});'
        'out center tags;',
      );
      for (final raw in elements) {
        final element = raw! as Map<String, Object?>;
        final centre = element['center'] as Map<String, Object?>?;
        final tags = element['tags'] as Map<String, Object?>?;
        live['${element['type']}/${element['id']}'] = OsmElement(
          kind: element['type']! as String,
          latitude: ((centre?['lat'] ?? element['lat'])! as num).toDouble(),
          longitude: ((centre?['lon'] ?? element['lon'])! as num).toDouble(),
          name: tags?['name'] as String?,
        );
      }
      await Future<void>.delayed(_pauseBetweenBatches);
    }
  } finally {
    client.close();
  }

  final flags = <String, String>{};
  final missing = <String>[];
  for (final entry in byRef.entries) {
    final checkpoint = entry.value;
    final id = checkpoint['id']! as String;
    final element = live[entry.key];
    if (element == null) {
      // The source deleted it. Nothing to review — the place may not exist.
      missing.add(id);
      continue;
    }
    final coordinates = checkpoint['coordinates']! as Map<String, Object?>;

    // A place somebody already confirmed against imagery is settled, and its
    // coordinate is deliberately not the source's any more — the twelve pilot
    // landmarks were nudged by hand in 2026-08, Independence Palace by 35 m.
    // Flagging that as drift would send the reviewer back over finished work.
    if (coordinates['verified'] == true) continue;

    final flag = flagFor(
      authoredLat: (coordinates['lat']! as num).toDouble(),
      authoredLon: (coordinates['lon']! as num).toDouble(),
      authoredName: checkpoint['name']! as String,
      live: element,
    );
    if (flag != null) flags[id] = flag;
  }

  outputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'_readme': 'Sinh bởi tool/coord_verify/recheck_osm.dart. '
        'flags: moved = nguồn đã dời chỗ, dot = chỉ là một cái chấm, '
        'name = tên khác nguồn. missing = nguồn đã xoá.', 'checkedAt': DateTime.now().toIso8601String().split('T').first, 'missing': missing, 'flags': flags})}\n',
    flush: true,
  );

  final counts = <String, int>{};
  for (final flag in flags.values) {
    counts[flag] = (counts[flag] ?? 0) + 1;
  }
  stdout.writeln(
    '\nrecheck_osm: ${byRef.length} điểm đối chiếu xong.\n'
    '  biến mất bên nguồn: ${missing.length}\n'
    '  cần nhìn bằng mắt: ${flags.length} $counts\n'
    'Đã ghi ${outputFile.path}.',
  );
}
