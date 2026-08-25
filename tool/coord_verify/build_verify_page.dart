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

/// This script sits one directory deeper than the other tools, so it climbs
/// two levels rather than one.
Directory repoRoot() {
  final scriptPath = Platform.script.toFilePath().replaceAll(r'\', '/');
  final scriptDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
  final toolDir = scriptDir.substring(0, scriptDir.lastIndexOf('/'));
  return Directory(toolDir.substring(0, toolDir.lastIndexOf('/')));
}

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
  final root = repoRoot().path.replaceAll(r'\', '/');
  final sourceFile = File('$root/content/checkpoints.json');
  final templateFile = File('$root/tool/coord_verify/template.html');
  final outputFile = File('$root/tool/coord_verify/verify.html');

  for (final file in [sourceFile, templateFile]) {
    if (!file.existsSync()) {
      stderr.writeln('build_verify_page: thiếu file ${file.path}');
      exit(1);
    }
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
    });
  }

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
