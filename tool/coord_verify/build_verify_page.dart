// Builds the coordinate verification page from content/checkpoints.json.
//
// The page exists to close one Definition of Done item of F2: every checkpoint
// carries verified: false until somebody has looked at satellite imagery and
// confirmed the point falls inside the building. Polygon centroids drift off
// the visible centre whenever a site has a large courtyard or an L-shaped
// footprint, so this is a judgement only a human eye can make.
//
// The page is generated rather than committed for the same reason
// tool/map_preview generates its styles: content/checkpoints.json is the
// source of truth, and a second copy of the coordinates would be a second
// truth. The generated file is self-contained so it can be opened straight
// from disk with no server — everything it needs at runtime comes over https.
//
// Usage, from the repository root:
//   dart run tool/coord_verify/build_verify_page.dart

import 'dart:convert';
import 'dart:io';

import '../support/repo_root.dart';

/// This script sits one directory deeper than the other tools, so it climbs
/// two levels rather than one.
/// Replaces [placeholder] in [template], failing loudly when it is absent.
///
/// A silent miss would produce a page that opens, renders a header and shows
/// no checkpoints — which reads as "nothing to verify" rather than as a bug.
String inject(String template, String placeholder, String value) {
  if (!template.contains(placeholder)) {
    stderr.writeln(
      'build_verify_page: không tìm thấy chỗ chèn "$placeholder" trong '
      'template.html. Template đã bị sửa mà script chưa cập nhật theo.',
    );
    exit(1);
  }
  return template.replaceFirst(placeholder, value);
}

void main() {
  final root = repoRootPath();
  final sourceFile = File('$root/content/checkpoints.json');
  final templateFile = File('$root/tool/coord_verify/template.html');
  final recheckFile = File('$root/tool/coord_verify/osm_recheck.json');
  final gmapsFile = File('$root/tool/coord_verify/gmaps_recheck.json');
  final outputFile = File('$root/tool/coord_verify/verify.html');

  for (final file in [sourceFile, templateFile]) {
    if (!file.existsSync()) {
      stderr.writeln('build_verify_page: thiếu file ${file.path}');
      exit(1);
    }
  }

  // Optional: without it every card is simply unflagged. Reviewing 272 places
  // in authored order works, it is just slower than starting with the ones
  // recheck_osm found a reason to doubt.
  var flags = const <String, dynamic>{};
  if (recheckFile.existsSync()) {
    final recheck =
        jsonDecode(recheckFile.readAsStringSync()) as Map<String, dynamic>;
    flags = recheck['flags'] as Map<String, dynamic>;
  } else {
    stdout.writeln(
      'build_verify_page: chưa có osm_recheck.json — trang sẽ không đánh dấu '
      'điểm đáng ngờ. Chạy recheck_osm.dart trước nếu muốn có.',
    );
  }

  // Optional in the same way, and from a second source on purpose: OpenStreetMap
  // checks that the import copied faithfully, Google checks whether anyone else
  // in the world puts the place in the same spot. Two volunteers agreeing is
  // worth more than one volunteer repeated.
  var gmaps = const <String, dynamic>{};
  if (gmapsFile.existsSync()) {
    final recheck =
        jsonDecode(gmapsFile.readAsStringSync()) as Map<String, dynamic>;
    gmaps = recheck['places'] as Map<String, dynamic>;
  }

  final decoded =
      jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;
  final checkpoints = decoded['checkpoints'] as List<dynamic>;

  final rows = <Map<String, dynamic>>[];
  for (final entry in checkpoints) {
    final cp = entry as Map<String, dynamic>;
    final coordinates = cp['coordinates'] as Map<String, dynamic>?;
    if (coordinates == null ||
        coordinates['lat'] == null ||
        coordinates['lon'] == null) {
      stderr.writeln(
        'build_verify_page: checkpoint "${cp['id']}" chưa có toạ độ — '
        'không có gì để xác nhận bằng mắt.',
      );
      exit(1);
    }
    rows.add({
      'id': cp['id'],
      'name': cp['name'],
      'category': cp['category'],
      'address': cp['address'],
      'radiusMeters': cp['radiusMeters'],
      'lat': coordinates['lat'],
      'lon': coordinates['lon'],
      'source': coordinates['source'] ?? '',
      'note': cp['note'],
      'flag': flags[cp['id']],
      'gmaps': gmaps[cp['id']],
    });
  }

  // Doubtful first: whoever opens this page has a limited number of tiles in
  // them, and the ones with a reason to doubt should get that attention.
  //
  // Google's verdict outranks OpenStreetMap's flag, because it is the stronger
  // statement. A conflict means two independent sources put the same name a
  // kilometre apart; an unknown means only one source has ever heard of the
  // place. An `agree` needs the least looking at of all, so it sinks.
  const verdictOrder = {'conflict': 0, 'unknown': 1, 'near': 2, 'agree': 3};
  const flagOrder = {'moved': 0, 'dot': 1, 'name': 2};

  int rank(Map<String, dynamic> row) {
    final gmaps = row['gmaps'] as Map<String, dynamic>?;
    final verdict = gmaps == null ? null : gmaps['verdict'] as String?;
    return (verdictOrder[verdict] ?? 1) * 10 + (flagOrder[row['flag']] ?? 3);
  }

  rows.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0
        ? byRank
        : (a['name'] as String).compareTo(b['name'] as String);
  });

  final today = DateTime.now().toIso8601String().split('T').first;

  var html = templateFile.readAsStringSync();
  html = inject(html, '/*__DATA__*/[]', jsonEncode(rows));
  html = inject(html, '/*__GENERATED_AT__*/""', jsonEncode(today));

  outputFile.writeAsStringSync(html, encoding: utf8, flush: true);

  stdout.writeln(
    'build_verify_page: đã sinh ${outputFile.path} — ${rows.length} checkpoint.\n'
    'Mở file đó bằng trình duyệt (không cần máy chủ).',
  );
}
