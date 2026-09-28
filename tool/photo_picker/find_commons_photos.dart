// Finds licensed photograph candidates on Wikimedia Commons for every place in
// content/checkpoints.json, and writes what a human still has to look at.
//
// Why it searches by coordinate and not by name: searching Commons by name is
// the trap this project has already fallen into twice. "Landmark 81" returns
// the Yokohama Landmark Tower; "Chùa Bửu Long" returns a different pagoda in
// District 10. A coordinate cannot be ambiguous. Commons records where a photo
// was taken, so asking "what has been photographed within N metres of here"
// answers the question the name cannot.
//
// It does NOT choose photographs. Being taken nearby does not make a picture a
// usable one — it may be a drain cover, a plaque, an interior, or somebody's
// lunch. Nor does it copy anything into the app: only titles, licences and URLs
// are recorded, and the licence ledger at content/image-licenses.md stays the
// thing that decides what may ship. This file feeds tool/photo_picker's page,
// which is where a person looks.
//
// Usage, from the repository root:
//   dart run tool/photo_picker/find_commons_photos.dart
//
// Writes tool/photo_picker/commons_candidates.json. Needs the network.

import 'dart:convert';
import 'dart:io';

import '../support/repo_root.dart';

/// Commons asks that automated clients identify themselves and stay polite.
/// See https://foundation.wikimedia.org/wiki/Policy:User-Agent_policy.
const _userAgent =
    'Wanderlock-photo-search/1.0 (https://github.com/ZzinzZ/wanderlock)';

const _endpoint = 'https://commons.wikimedia.org/w/api.php';

/// Pause between requests. Well under what Commons allows, because nothing
/// here is urgent and a blocked client helps nobody.
const _pause = Duration(milliseconds: 250);

/// How far from a checkpoint a photograph may have been taken and still be a
/// photograph *of* it.
///
/// Deliberately wider than the check-in radius: a photographer steps back to
/// fit a building in the frame, so the picture of a 60 m checkpoint is often
/// taken 100 m away across the street. Too wide and a market's candidates fill
/// up with the temple next door, which is what the human pass then has to
/// throw out.
int _searchRadius(int checkinRadius) =>
    (checkinRadius * 2).clamp(150, 400).toInt();

/// Licences that allow shipping the file inside the app, given attribution.
/// Anything else — non-commercial, no-derivatives, fair use — is dropped here
/// rather than shown to a person who might pick it.
bool _isUsable(String licence) {
  final short = licence.toLowerCase();
  if (short.contains('nc') || short.contains('nd')) return false;
  return short.startsWith('cc0') ||
      short.startsWith('cc-by') ||
      short.startsWith('cc by') ||
      short.startsWith('pd') ||
      short.contains('public domain');
}

/// Files that are not photographs of a place. Commons holds maps, coats of
/// arms, scanned documents and route diagrams at these coordinates too.
bool _looksLikeAPhotograph(String title, int width, int height) {
  final name = title.toLowerCase();
  const rejected = [
    '.svg',
    '.pdf',
    '.tif',
    '.ogv',
    '.webm',
    'map',
    'logo',
    'coat of arms',
    'diagram',
    'plan of',
    'seal of',
  ];
  for (final word in rejected) {
    if (name.contains(word)) return false;
  }
  // Below this a photograph is too small to fill an unlock screen.
  return width >= 1200 && height >= 800;
}

Future<Map<String, Object?>> _get(
  HttpClient client,
  Map<String, String> query,
) async {
  final uri = Uri.parse(_endpoint).replace(
    queryParameters: {...query, 'format': 'json', 'formatversion': '2'},
  );

  for (var attempt = 1; attempt <= 4; attempt++) {
    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', _userAgent);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return jsonDecode(body) as Map<String, Object?>;
    } on Exception catch (error) {
      stdout.writeln('  ... thử lại ($error)');
      await Future<void>.delayed(Duration(seconds: 5 * attempt));
    }
  }
  stderr.writeln('find_commons_photos: Commons không trả lời sau 4 lần.');
  exit(1);
}

/// File titles photographed within [radius] metres of a point.
Future<List<String>> _nearby(
  HttpClient client,
  double lat,
  double lon,
  int radius,
) async {
  final data = await _get(client, {
    'action': 'query',
    'list': 'geosearch',
    'gscoord': '$lat|$lon',
    'gsradius': '$radius',
    'gslimit': '40',
    // Namespace 6 is File:. Without it the search returns gallery pages.
    'gsnamespace': '6',
  });

  final query = data['query'] as Map<String, Object?>?;
  final results = query?['geosearch'] as List<Object?>? ?? const [];
  return [
    for (final result in results)
      (result! as Map<String, Object?>)['title']! as String,
  ];
}

/// Licence, author and size for up to 50 files in one request.
Future<Map<String, Map<String, Object?>>> _details(
  HttpClient client,
  List<String> titles,
) async {
  if (titles.isEmpty) return {};

  final data = await _get(client, {
    'action': 'query',
    'prop': 'imageinfo',
    'iiprop': 'url|size|extmetadata',
    'iiextmetadatafilter': 'LicenseShortName|Artist|ImageDescription',
    'titles': titles.join('|'),
  });

  final query = data['query'] as Map<String, Object?>?;
  final pages = query?['pages'] as List<Object?>? ?? const [];

  final out = <String, Map<String, Object?>>{};
  for (final page in pages) {
    final row = page! as Map<String, Object?>;
    final info = (row['imageinfo'] as List<Object?>?)?.firstOrNull;
    if (info == null) continue;
    final image = info as Map<String, Object?>;
    final meta = image['extmetadata'] as Map<String, Object?>? ?? const {};

    String field(String key) {
      final entry = meta[key] as Map<String, Object?>?;
      final value = entry?['value'] as String? ?? '';
      // Commons returns HTML in these fields — an author is often a link.
      return value
          .replaceAll(RegExp('<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .trim();
    }

    out[row['title']! as String] = {
      'licence': field('LicenseShortName'),
      'author': field('Artist'),
      'description': field('ImageDescription'),
      'width': image['width'],
      'height': image['height'],
      'thumb': image['url'],
      'page': image['descriptionurl'],
    };
  }
  return out;
}

Future<void> main() async {
  final root = repoRootPath();
  final sourceFile = File('$root/content/checkpoints.json');
  final outputFile = File('$root/tool/photo_picker/commons_candidates.json');

  if (!sourceFile.existsSync()) {
    stderr.writeln('find_commons_photos: thiếu ${sourceFile.path}');
    exit(1);
  }

  final decoded =
      jsonDecode(sourceFile.readAsStringSync()) as Map<String, Object?>;
  final checkpoints = decoded['checkpoints']! as List<Object?>;

  final client = HttpClient()..userAgent = _userAgent;
  final results = <String, Object?>{};
  var withPhotos = 0;
  var index = 0;

  for (final entry in checkpoints) {
    final cp = entry! as Map<String, Object?>;
    final id = cp['id']! as String;
    final name = cp['name']! as String;
    final coordinates = cp['coordinates']! as Map<String, Object?>;
    final lat = (coordinates['lat']! as num).toDouble();
    final lon = (coordinates['lon']! as num).toDouble();
    final radius = _searchRadius((cp['radiusMeters']! as num).toInt());

    index++;
    stdout.write('[$index/${checkpoints.length}] $name ... ');

    final titles = await _nearby(client, lat, lon, radius);
    await Future<void>.delayed(_pause);

    final details = await _details(client, titles.take(50).toList());
    await Future<void>.delayed(_pause);

    final candidates = <Map<String, Object?>>[];
    for (final title in titles) {
      final detail = details[title];
      if (detail == null) continue;
      final licence = detail['licence'] as String? ?? '';
      final width = (detail['width'] as num?)?.toInt() ?? 0;
      final height = (detail['height'] as num?)?.toInt() ?? 0;
      if (!_isUsable(licence)) continue;
      if (!_looksLikeAPhotograph(title, width, height)) continue;
      candidates.add({'title': title, ...detail});
    }

    // Biggest first: a photograph that survives the app's processing preset is
    // more likely to be one that started large.
    candidates.sort(
      (a, b) => ((b['width']! as num) * (b['height']! as num)).compareTo(
        (a['width']! as num) * (a['height']! as num),
      ),
    );

    if (candidates.isNotEmpty) withPhotos++;
    results[id] = {
      'name': name,
      'searchRadiusMetres': radius,
      'candidates': candidates.take(8).toList(),
    };
    stdout.writeln('${candidates.length} ứng viên');
  }

  client.close();

  final doc = <String, Object?>{
    '_readme':
        'Ứng viên ảnh tìm trên Wikimedia Commons theo TOẠ ĐỘ, không theo tên. '
        'Đây là kết quả tra siêu dữ liệu — chưa ai nhìn ảnh. Ở gần không có '
        'nghĩa là chụp đúng chỗ đó. Chọn ảnh bằng tool/photo_picker, rồi chép '
        'sang content/image-licenses.md; không ảnh nào vào app mà không có '
        'dòng trong sổ đó.',
    'checkedAt': DateTime.now().toIso8601String().split('T').first,
    'placesSearched': checkpoints.length,
    'placesWithCandidates': withPhotos,
    'places': results,
  };

  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(doc),
    encoding: utf8,
    flush: true,
  );

  stdout.writeln(
    '\nfind_commons_photos: ${outputFile.path}\n'
    '$withPhotos/${checkpoints.length} địa điểm có ít nhất một ứng viên.',
  );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
