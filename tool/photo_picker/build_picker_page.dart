// Builds the marker photo picker from content/image-licenses.md.
//
// The candidate list in that file is the result of a metadata search: licences
// were read per image, but nobody has looked at a single photograph. Several
// entries name themselves as interior or detail shots while a marker needs the
// front of the building, so the choice cannot be made from the table alone —
// it needs eyes on the images at a usable size.
//
// Both content files stay the source of truth. This script only reads them;
// the page it produces exports table rows for a human to paste back, so every
// licence line still passes through review instead of being written by a web
// page.
//
// Usage, from the repository root:
//   dart run tool/photo_picker/build_picker_page.dart

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

const candidateHeading = '## Ứng viên tìm được trên Wikimedia Commons';

/// Heading prefix for a per-place legal note, as used for Landmark 81. Any
/// place gaining such a section shows up as a warning on its card without this
/// script needing to learn the place.
const noteHeadingPrefix = '## Lưu ý riêng cho ';

/// Matches the single markdown link that fills a table cell.
///
/// Anchored and greedy on purpose. Commons file names routinely end in a
/// bracketed upload id — `War_Remnants_Museum_(46038433641).jpg` — so a lazy
/// `\((.+?)\)` stops at the first closing bracket and hands back a truncated
/// URL. That failure is silent in the parser and only shows up as a broken
/// image in the browser, which is where it was first found.
final linkPattern = RegExp(r'^\[(.+)\]\((.+)\)$');

/// Extensions Commons serves for the photographs this ledger tracks.
const imageExtensions = <String>{'.jpg', '.jpeg', '.png', '.tif', '.tiff'};

/// Splits a markdown table row into its trimmed cells.
List<String> cells(String row) {
  final parts = row.trim().split('|');
  if (parts.isNotEmpty && parts.first.trim().isEmpty) parts.removeAt(0);
  if (parts.isNotEmpty && parts.last.trim().isEmpty) parts.removeLast();
  return parts.map((c) => c.trim()).toList();
}

bool isSeparatorRow(String row) =>
    RegExp(r'^\|[\s:|-]+\|$').hasMatch(row.trim());

/// Reads the candidate table, keyed by the place name in its first column.
///
/// A row whose first cell is the continuation arrow belongs to the place named
/// by the row above it — that is how the file lists a second candidate.
Map<String, List<Map<String, String>>> parseCandidates(List<String> lines) {
  final byPlace = <String, List<Map<String, String>>>{};
  final start = lines.indexWhere((l) => l.trim().startsWith(candidateHeading));
  if (start < 0) {
    stderr.writeln(
      'build_picker_page: không thấy mục "$candidateHeading" trong '
      'content/image-licenses.md. File đã đổi cấu trúc.',
    );
    exit(1);
  }

  var current = '';
  var sawHeaderRow = false;

  for (final line in lines.skip(start + 1)) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#')) break; // next section ends the table
    if (!trimmed.startsWith('|')) continue;
    if (isSeparatorRow(trimmed)) continue;

    final row = cells(trimmed);
    if (row.length < 5) continue;
    if (!sawHeaderRow) {
      // The column header row, whatever it is called, is the first one.
      sawHeaderRow = true;
      continue;
    }

    if (row[0] != '↳' && row[0].isNotEmpty) current = row[0];
    if (current.isEmpty) continue;

    final link = linkPattern.firstMatch(row[1]);
    if (link == null) {
      stderr.writeln(
        'build_picker_page: dòng ứng viên của "$current" không có liên kết '
        'dạng [nhãn](url):\n  $trimmed',
      );
      exit(1);
    }
    final page = link.group(2)!;
    final marker = '/wiki/File:';
    final at = page.indexOf(marker);
    if (at < 0) {
      stderr.writeln(
        'build_picker_page: "$page" không phải trang File: của Commons.',
      );
      exit(1);
    }

    // A file name that does not end in an image extension means the URL was
    // cut short — the parser found a closing bracket that belonged to the name
    // rather than to the markdown link. Fail here rather than ship a page of
    // broken images.
    final file = page.substring(at + marker.length);
    final dot = file.lastIndexOf('.');
    if (dot < 0 ||
        !imageExtensions.contains(file.substring(dot).toLowerCase())) {
      stderr.writeln(
        'build_picker_page: tên tệp "$file" (địa điểm "$current") không kết '
        'thúc bằng đuôi ảnh. URL nhiều khả năng bị cắt cụt khi phân tích.',
      );
      exit(1);
    }

    byPlace.putIfAbsent(current, () => []).add({
      'label': link.group(1)!,
      'page': page,
      'file': file,
      'license': row[2],
      'author': row[3],
      'size': row[4],
    });
  }

  return byPlace;
}

/// Pulls the first two paragraphs of any `## Lưu ý riêng cho <place>` section.
///
/// Two rather than one: in the Landmark 81 section the first paragraph raises
/// the doubt and the second is the finding that settles it. Showing only the
/// first would understate the problem on the card.
Map<String, String> parseWarnings(List<String> lines) {
  final warnings = <String, String>{};
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith(noteHeadingPrefix)) continue;
    final place = lines[i].substring(noteHeadingPrefix.length).trim();

    final paragraphs = <String>[];
    final buffer = StringBuffer();
    for (var j = i + 1; j < lines.length; j++) {
      final line = lines[j];
      if (line.startsWith('#')) break;
      if (line.trim().isEmpty) {
        if (buffer.isNotEmpty) paragraphs.add(buffer.toString().trim());
        buffer.clear();
        if (paragraphs.length >= 2) break;
        continue;
      }
      buffer.write('${line.trim()} ');
    }
    if (buffer.isNotEmpty && paragraphs.length < 2) {
      paragraphs.add(buffer.toString().trim());
    }

    warnings[place] = paragraphs
        .join(' ')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  return warnings;
}

void main() {
  final root = repoRoot().path.replaceAll(r'\', '/');
  final licenceFile = File('$root/content/image-licenses.md');
  final checkpointFile = File('$root/content/checkpoints.json');
  final templateFile = File('$root/tool/photo_picker/template.html');
  final outputFile = File('$root/tool/photo_picker/picker.html');

  for (final file in [licenceFile, checkpointFile, templateFile]) {
    if (!file.existsSync()) {
      stderr.writeln('build_picker_page: thiếu file ${file.path}');
      exit(1);
    }
  }

  final lines = const LineSplitter().convert(licenceFile.readAsStringSync());
  final candidates = parseCandidates(lines);
  final warnings = parseWarnings(lines);

  final decoded =
      jsonDecode(checkpointFile.readAsStringSync()) as Map<String, dynamic>;
  final checkpoints = (decoded['checkpoints'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final names = {for (final cp in checkpoints) cp['name'] as String};

  // Drift gate. A place named in the licence ledger that no checkpoint claims
  // means one of the two files was renamed without the other, and the page
  // would quietly drop that place rather than show an empty slot.
  final unknown = candidates.keys.where((p) => !names.contains(p)).toList();
  if (unknown.isNotEmpty) {
    stderr.writeln(
      'build_picker_page: image-licenses.md có địa điểm không khớp tên nào '
      'trong checkpoints.json:\n  ${unknown.join('\n  ')}\n'
      'Hai file đã lệch nhau — sửa tên cho khớp rồi chạy lại.',
    );
    exit(1);
  }

  final places = <Map<String, dynamic>>[];
  for (final cp in checkpoints) {
    final name = cp['name'] as String;
    places.add({
      'id': cp['id'],
      'name': name,
      'warning': warnings[name],
      'candidates': candidates[name] ?? const [],
    });
  }

  final today = DateTime.now().toIso8601String().split('T').first;

  var html = templateFile.readAsStringSync();
  for (final entry in {
    '/*__DATA__*/[]': jsonEncode(places),
    '/*__GENERATED_AT__*/""': jsonEncode(today),
  }.entries) {
    if (!html.contains(entry.key)) {
      stderr.writeln(
        'build_picker_page: không tìm thấy chỗ chèn "${entry.key}" trong '
        'template.html. Template đã bị sửa mà script chưa cập nhật theo.',
      );
      exit(1);
    }
    html = html.replaceFirst(entry.key, entry.value);
  }

  outputFile.writeAsStringSync(html, encoding: utf8, flush: true);

  final total = places.fold<int>(
    0,
    (sum, p) => sum + (p['candidates'] as List).length,
  );
  final empty = places.where((p) => (p['candidates'] as List).isEmpty).length;
  stdout.writeln(
    'build_picker_page: đã sinh ${outputFile.path} — '
    '${places.length} địa điểm, $total ứng viên'
    '${empty > 0 ? ', $empty điểm chưa có ứng viên nào' : ''}.\n'
    'Mở file đó bằng trình duyệt (không cần máy chủ).',
  );
}
