// Downloads one photograph per place from Wikimedia Commons and writes it
// into the repository, with its licence row.
//
// The step after `find_commons_photos.dart`, which only listed candidates.
// This picks one and fetches it, so the app has something real to show on the
// unlock screen and at the head of a story chapter.
//
// **How it picks, and why that is not the same as choosing.** Candidates are
// ranked by whether the file name says it is of this place, against words that
// say it is of something else — an interior, a detail, a plaque, a sign. That
// ranking is good enough to be worth shipping and nowhere near good enough to
// be trusted: the top candidate for Bến Thành Market was a photograph of the
// aisles inside it. Every file this writes is meant to be looked at, and
// swapped through tool/photo_picker's page where it is wrong.
//
// Usage, from the repository root:
//   dart run tool/photo_picker/fetch_photos.dart [--only <id>,<id>] [--width N]
//
// Reads tool/photo_picker/commons_candidates.json, writes
// content/images/places/<id>.jpg and a licence row per file into
// content/image-licenses.md. Needs the network.

import 'dart:convert';
import 'dart:io';

import '../support/repo_root.dart';

const _userAgent =
    'Wanderlock-photo-fetch/1.0 (https://github.com/ZzinzZ/wanderlock)';

/// Served width. A phone card is at most ~430 logical pixels across, so 900
/// covers a 2x screen with room to crop, and keeps a photograph near 150 KB
/// instead of the several megabytes Commons holds the original at.
const _defaultWidth = 900;

/// Words in a file name that say the picture is of something other than the
/// building seen from outside. Weighted, because "night" is a mild objection
/// and "interior" is a strong one.
const _penalties = <String, int>{
  'interior': -8,
  'inside': -8,
  'indoor': -8,
  'ben trong': -8,
  'noi that': -8,
  'detail': -5,
  'closeup': -5,
  'close up': -5,
  'plaque': -6,
  'sign': -4,
  'bang hieu': -4,
  'statue of': -3,
  'night': -2,
  'dem': -2,
  'construction': -4,
  'ruin': -4,
  'stamp': -6,
  'banknote': -6,
};

String _fold(String value) {
  const marks = {
    'àáạảãâầấậẩẫăằắặẳẵ': 'a',
    'èéẹẻẽêềếệểễ': 'e',
    'ìíịỉĩ': 'i',
    'òóọỏõôồốộổỗơờớợởỡ': 'o',
    'ùúụủũưừứựửữ': 'u',
    'ỳýỵỷỹ': 'y',
    'đ': 'd',
  };
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    var mapped = char;
    for (final entry in marks.entries) {
      if (entry.key.contains(char)) {
        mapped = entry.value;
        break;
      }
    }
    buffer.write(RegExp(r'[a-z0-9 ]').hasMatch(mapped) ? mapped : ' ');
  }
  return buffer
      .toString()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .join(' ');
}

int _score(String placeName, Map<String, Object?> candidate) {
  final title = _fold(candidate['title']! as String);
  final width = (candidate['width'] as num?)?.toInt() ?? 0;
  final height = (candidate['height'] as num?)?.toInt() ?? 0;

  var score = 0;

  // Does the file name claim to be this place?
  const noise = {
    'cho', 'cong', 'vien', 'chua', 'nha', 'trung', 'tam', 'thanh', 'pho',
    'ho', 'chi', 'minh', 'quan', 'duong', 'khu', 'viet', 'nam', 'saigon',
    'sai', 'gon', 'city', 'vietnam', 'the', 'of', 'in',
  };
  final words = _fold(placeName).split(' ').toSet().difference(noise);
  for (final word in words) {
    if (title.contains(word)) score += 4;
  }

  for (final entry in _penalties.entries) {
    if (title.contains(entry.key)) score += entry.value;
  }

  // Landscape suits a 16:9 cover; a tall photograph has to be cropped hard.
  if (width > height) score += 3;

  // Big enough to survive the resize, without letting sheer pixel count
  // outvote being a picture of the right thing.
  if (width >= 2000) score += 1;

  return score;
}

/// Licence and author for one file, read from Commons.
Future<Map<String, Object?>?> _describe(HttpClient client, String title) async {
  final uri = Uri.parse('https://commons.wikimedia.org/w/api.php').replace(
    queryParameters: {
      'action': 'query',
      'prop': 'imageinfo',
      'iiprop': 'size|extmetadata',
      'iiextmetadatafilter': 'LicenseShortName|Artist',
      'titles': 'File:$title',
      'format': 'json',
      'formatversion': '2',
    },
  );

  try {
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', _userAgent);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, Object?>;
    final pages =
        (data['query'] as Map<String, Object?>?)?['pages'] as List<Object?>? ??
        const [];
    if (pages.isEmpty) return null;
    final page = pages.first! as Map<String, Object?>;
    final info = (page['imageinfo'] as List<Object?>?)?.firstOrNull;
    if (info == null) return null;
    final image = info as Map<String, Object?>;
    final meta = image['extmetadata'] as Map<String, Object?>? ?? const {};

    String field(String key) {
      final entry = meta[key] as Map<String, Object?>?;
      return (entry?['value'] as String? ?? '')
          .replaceAll(RegExp('<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .trim();
    }

    return {
      'title': 'File:$title',
      'licence': field('LicenseShortName'),
      'author': field('Artist'),
      'width': image['width'],
      'height': image['height'],
      'page':
          'https://commons.wikimedia.org/wiki/'
          '${Uri.encodeComponent('File:$title')}',
    };
  } on Exception {
    return null;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Future<List<int>?> _download(HttpClient client, Uri uri) async {
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', _userAgent);
      request.followRedirects = true;
      final response = await request.close();
      if (response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } on Exception catch (error) {
      stdout.writeln('  ... thử lại ($error)');
      await Future<void>.delayed(Duration(seconds: 3 * attempt));
    }
  }
  return null;
}

Future<void> main(List<String> args) async {
  final root = repoRootPath();
  final candidatesFile = File(
    '$root/tool/photo_picker/commons_candidates.json',
  );
  final chosenFile = File('$root/tool/photo_picker/chosen.json');
  final outputDir = Directory('$root/content/images/places');
  final reportFile = File('$root/tool/photo_picker/fetched_photos.json');

  if (!candidatesFile.existsSync()) {
    stderr.writeln(
      'fetch_photos: chưa có ${candidatesFile.path}. Chạy '
      'find_commons_photos.dart trước.',
    );
    exit(1);
  }

  var width = _defaultWidth;
  Set<String>? only;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--width' && i + 1 < args.length) {
      width = int.parse(args[i + 1]);
    }
    if (args[i] == '--only' && i + 1 < args.length) {
      only = args[i + 1].split(',').map((s) => s.trim()).toSet();
    }
  }

  final found =
      jsonDecode(candidatesFile.readAsStringSync()) as Map<String, Object?>;
  final byId = found['places']! as Map<String, Object?>;

  // A person's answer beats the ranking. Where `chosen.json` names a file for
  // a place, that file is fetched and the scoring below never runs — it exists
  // to narrow the pile for whoever is going to look, not to decide.
  var chosen = const <String, Object?>{};
  if (chosenFile.existsSync()) {
    chosen =
        (jsonDecode(chosenFile.readAsStringSync())
                as Map<String, Object?>)['files']!
            as Map<String, Object?>;
  }

  outputDir.createSync(recursive: true);
  final client = HttpClient()..userAgent = _userAgent;

  final fetched = <String, Object?>{};
  var bytesTotal = 0;
  var skipped = 0;

  for (final entry in byId.entries) {
    final id = entry.key;
    if (only != null && !only.contains(id)) continue;

    final place = entry.value! as Map<String, Object?>;
    final name = place['name']! as String;
    final candidates = (place['candidates']! as List<Object?>)
        .cast<Map<String, Object?>>();

    if (candidates.isEmpty) {
      skipped++;
      continue;
    }

    final pick = chosen[id] as String?;
    Map<String, Object?> best;
    String title;
    if (pick != null) {
      title = pick;
      best =
          candidates.firstWhere(
            (c) => (c['title']! as String).replaceFirst('File:', '') == pick,
            orElse: () => <String, Object?>{},
          );
      if (best.isEmpty) {
        // Chosen from a search rather than from the nearby candidates, so its
        // licence has to be read now — never assumed, never copied from a
        // neighbouring file.
        best = await _describe(client, title) ?? <String, Object?>{};
        if (best.isEmpty) {
          stdout.writeln('$id ... không đọc được giấy phép của "$title"');
          skipped++;
          continue;
        }
      }
    } else {
      final ranked = [...candidates]
        ..sort((a, b) => _score(name, b).compareTo(_score(name, a)));
      best = ranked.first;
      title = (best['title']! as String).replaceFirst('File:', '');
    }

    stdout.write('$id ... ');

    final uri = Uri.parse(
      'https://commons.wikimedia.org/wiki/Special:FilePath/'
      '${Uri.encodeComponent(title)}?width=$width',
    );
    final bytes = await _download(client, uri);
    if (bytes == null) {
      stdout.writeln('tải hỏng');
      skipped++;
      continue;
    }

    final file = File('${outputDir.path}/$id.jpg');
    file.writeAsBytesSync(bytes, flush: true);
    bytesTotal += bytes.length;

    fetched[id] = {
      'name': name,
      'file': 'images/places/$id.jpg',
      'commonsTitle': title,
      'licence': best['licence'],
      'author': best['author'],
      'page': best['page'],
      'bytes': bytes.length,
      'chosenByHand': chosen.containsKey(id),
    };
    stdout.writeln('${(bytes.length / 1024).round()} KB · $title');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  client.close();

  reportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      '_readme':
          'Ảnh đã tải về từ Wikimedia Commons. Ảnh được MÁY chọn theo tên tệp '
          '— chưa ai nhìn. Mỗi dòng ở đây phải có một dòng tương ứng trong '
          'content/image-licenses.md trước khi ảnh được dùng trong app.',
      'fetchedAt': DateTime.now().toIso8601String().split('T').first,
      'servedWidth': width,
      'files': fetched,
    }),
    encoding: utf8,
    flush: true,
  );

  stdout.writeln(
    '\nfetch_photos: ${fetched.length} ảnh · '
    '${(bytesTotal / 1024 / 1024).toStringAsFixed(1)} MB · '
    'bỏ qua $skipped nơi không có ứng viên.\n'
    'Ghi vào ${outputDir.path}, báo cáo ở ${reportFile.path}.',
  );
}
