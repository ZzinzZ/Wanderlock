// Works out which places deserve a story chapter, by asking whether anyone
// has written an encyclopaedia article about them.
//
// The owner's rule is that big places get a chapter — landmarks, attractions,
// large malls — and ordinary ones do not: a pho shop needs no history lesson.
// Turning that into a decision for 272 places needs a signal, and taste is a
// bad one because it does not survive the person who had it.
//
// Wikipedia is the signal. Someone unconnected to this project already decided
// each of these places was worth an article, or decided it was not. That is
// exactly the judgement being borrowed, it is checkable by anyone, and the
// article is also where the chapter gets written from.
//
// Searched by COORDINATE, not by name — the same trap as everywhere else in
// this repository: "Landmark 81" returns a tower in Yokohama.
//
// It does NOT decide anything. It writes a proposal the owner reviews; the
// `needsStory` flag in content/checkpoints.json is what the app reads, and a
// person sets that.
//
// Usage, from the repository root:
//   dart run tool/story_candidates/find_wikipedia_articles.dart
//
// Writes tool/story_candidates/wikipedia_articles.json. Needs the network.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../support/repo_root.dart';

const _userAgent =
    'Wanderlock-story-scout/1.0 (https://github.com/ZzinzZ/wanderlock)';

const _endpoint = 'https://vi.wikipedia.org/w/api.php';

const _pause = Duration(milliseconds: 200);

/// How far an article's own coordinate may sit from ours and still be about
/// the same place. Wider than the check-in radius, because an article about a
/// park is pinned somewhere in the middle of it.
const _radiusMetres = 500;

/// Categories that never get a chapter, whatever Wikipedia says.
///
/// A famous banh xeo place can have an article and still not want three
/// paragraphs of history in front of somebody who came to eat. The owner's
/// words: quán ăn và các địa điểm bình thường thì không cần.
const _never = <String>{'food'};

/// Ground distance in metres, equirectangular — plenty at city scale.
double _metresBetween(double aLat, double aLon, double bLat, double bLon) {
  const metresPerDegree = 111320.0;
  final meanLat = (aLat + bLat) / 2 * math.pi / 180;
  final dy = (bLat - aLat) * metresPerDegree;
  final dx = (bLon - aLon) * metresPerDegree * math.cos(meanLat);
  return math.sqrt(dx * dx + dy * dy);
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
  stderr.writeln('find_wikipedia_articles: Wikipedia không trả lời.');
  exit(1);
}

Future<void> main() async {
  final root = repoRootPath();
  final sourceFile = File('$root/content/checkpoints.json');
  final outputFile = File(
    '$root/tool/story_candidates/wikipedia_articles.json',
  );

  if (!sourceFile.existsSync()) {
    stderr.writeln('find_wikipedia_articles: thiếu ${sourceFile.path}');
    exit(1);
  }

  final decoded =
      jsonDecode(sourceFile.readAsStringSync()) as Map<String, Object?>;
  final checkpoints = decoded['checkpoints']! as List<Object?>;

  final client = HttpClient()..userAgent = _userAgent;
  final places = <String, Object?>{};
  var withArticle = 0;
  var index = 0;

  for (final entry in checkpoints) {
    final cp = entry! as Map<String, Object?>;
    final id = cp['id']! as String;
    final name = cp['name']! as String;
    final category = cp['category']! as String;
    final coordinates = cp['coordinates']! as Map<String, Object?>;
    final lat = (coordinates['lat']! as num).toDouble();
    final lon = (coordinates['lon']! as num).toDouble();

    index++;
    stdout.write('[$index/${checkpoints.length}] $name ... ');

    if (_never.contains(category)) {
      places[id] = {
        'name': name,
        'category': category,
        'proposal': 'no',
        'why': 'loại "$category" — chủ dự án chốt không cần chương',
      };
      stdout.writeln('bỏ qua (quán ăn)');
      continue;
    }

    // Two ways round, and both have to agree.
    //
    // Searching by coordinate alone finds the article about whatever else is
    // nearby: Bến Nhà Rồng came back as "Rạch Bến Nghé", the canal it stands
    // on. Searching by name alone is the older trap — Landmark 81 is a tower
    // in Yokohama. So: ask Wikipedia for articles with this name, then throw
    // away any whose own coordinates are somewhere else.
    final search = await _get(client, {
      'action': 'query',
      'list': 'search',
      'srsearch': name,
      'srlimit': '4',
    });
    await Future<void>.delayed(_pause);

    final hits =
        ((search['query'] as Map<String, Object?>?)?['search']
                as List<Object?>? ??
            const [])
            .map((h) => (h! as Map<String, Object?>)['title']! as String)
            .toList();

    Map<String, Object?>? best;
    if (hits.isNotEmpty) {
      final coords = await _get(client, {
        'action': 'query',
        'prop': 'coordinates',
        'redirects': '1',
        'titles': hits.join('|'),
      });
      await Future<void>.delayed(_pause);

      final pages =
          (coords['query'] as Map<String, Object?>?)?['pages']
              as List<Object?>? ??
          const [];

      for (final page in pages) {
        final row = page! as Map<String, Object?>;
        final title = row['title']! as String;
        final where = (row['coordinates'] as List<Object?>?)?.firstOrNull;
        if (where == null) continue;
        final at = where as Map<String, Object?>;
        final metres = _metresBetween(
          lat,
          lon,
          (at['lat']! as num).toDouble(),
          (at['lon']! as num).toDouble(),
        );
        if (metres > _radiusMetres) continue;
        if (best == null || metres < (best['metres']! as double)) {
          best = {'title': title, 'metres': metres};
        }
      }
    }

    if (best == null) {
      places[id] = {
        'name': name,
        'category': category,
        'proposal': 'no',
        'why':
            'không có bài Wikipedia nào mang tên này, có toạ độ, và ở gần đây',
      };
      stdout.writeln('không có bài');
    } else {
      withArticle++;
      places[id] = {
        'name': name,
        'category': category,
        'proposal': 'yes',
        'article': best['title'],
        'metres': (best['metres']! as double).round(),
      };
      stdout.writeln('"${best['title']}"');
    }
  }

  client.close();

  final doc = <String, Object?>{
    '_readme':
        'Đề xuất nơi nào nên có chương truyện, dựa trên việc Wikipedia tiếng '
        'Việt có bài về nơi đó hay không. ĐÂY LÀ ĐỀ XUẤT, KHÔNG PHẢI QUYẾT '
        'ĐỊNH: trường "needsStory" trong content/checkpoints.json mới là thứ '
        'app đọc, và người đặt nó. Tra theo toạ độ, không theo tên.',
    'checkedAt': DateTime.now().toIso8601String().split('T').first,
    'radiusMetres': _radiusMetres,
    'proposedYes': withArticle,
    'proposedNo': checkpoints.length - withArticle,
    'places': places,
  };

  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(doc),
    encoding: utf8,
    flush: true,
  );

  stdout.writeln(
    '\nfind_wikipedia_articles: ${outputFile.path}\n'
    'Đề xuất CÓ chương: $withArticle · KHÔNG: '
    '${checkpoints.length - withArticle}',
  );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
