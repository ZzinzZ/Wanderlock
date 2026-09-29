// Gathers what the open data actually knows about each pilot place.
//
// Writing an introduction to 272 real places means having something true to
// say about each of them. This collects that material and nothing else:
// OpenStreetMap tags for the object each checkpoint was resolved from, the
// Wikidata item it points at, and the opening paragraphs of its Vietnamese
// Wikipedia article where one exists.
//
// It invents nothing and summarises nothing. Turning these facts into a
// chapter is a separate step — see the README next door.
//
//   dart run tool/place_facts/fetch_place_facts.dart [--limit N]
//
// Output: tool/place_facts/place-facts.json, gitignored. Re-run it rather
// than trusting a copy someone committed.

import 'dart:convert';
import 'dart:io';

import '../support/repo_root.dart';

const _overpass = 'https://overpass-api.de/api/interpreter';
const _wikidata = 'https://www.wikidata.org/w/api.php';
const _wikipediaVi = 'https://vi.wikipedia.org/w/api.php';
const _userAgent = 'Wanderlock-place-facts/1.0';

/// Tags worth keeping. An allow-list rather than the whole tag soup: most of
/// what OSM carries is bookkeeping, and a chapter written from `source:date`
/// would be a chapter about OpenStreetMap.
const _keepTags = <String>{
  'name',
  'name:en',
  'name:vi',
  'alt_name',
  'alt_name:vi',
  'old_name',
  'official_name',
  'description',
  'description:vi',
  'inscription',
  'historic',
  'memorial',
  'heritage',
  'ruins',
  'tourism',
  'amenity',
  'shop',
  'leisure',
  'building',
  'man_made',
  'religion',
  'denomination',
  'cuisine',
  'attraction',
  'museum',
  'start_date',
  'opening_date',
  'construction_date',
  'opening_hours',
  'operator',
  'brand',
  'architect',
  'building:levels',
  'website',
  'contact:website',
  'wikidata',
  'wikipedia',
  'wikimedia_commons',
  'addr:housenumber',
  'addr:street',
  'addr:district',
  'addr:ward',
};

/// Statuses worth waiting out. Overpass is free and shared, so a busy server
/// is the normal case rather than a failure: 429 is its rate limit and 504 is
/// it giving up under load. Both clear on their own.
const _retryable = {429, 502, 503, 504};

Future<String> _postOnce(String url, String body) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 60);
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers
      ..set('User-Agent', _userAgent)
      ..set('Content-Type', 'application/x-www-form-urlencoded');
    request.write(body);
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw _HttpStatus(url, response.statusCode);
    }
    return text;
  } finally {
    client.close();
  }
}

class _HttpStatus implements Exception {
  const _HttpStatus(this.url, this.code);

  final String url;
  final int code;

  @override
  String toString() => '$url answered $code';
}

Future<String> _post(String url, String body) async {
  const attempts = 5;
  for (var attempt = 1; ; attempt++) {
    try {
      return await _postOnce(url, body);
    } on Object catch (error) {
      final isLast = attempt == attempts;
      final isRetryable =
          error is! _HttpStatus || _retryable.contains(error.code);
      if (isLast || !isRetryable) rethrow;
      final wait = Duration(seconds: 15 * attempt);
      stdout.writeln('  ($error) cho ${wait.inSeconds}s roi thu lai...');
      await Future<void>.delayed(wait);
    }
  }
}

Future<String> _get(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('User-Agent', _userAgent);
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('$url answered ${response.statusCode}');
    }
    return text;
  } finally {
    client.close();
  }
}

/// `openstreetmap:way/39598493` becomes `('way', '39598493')`.
(String, String)? _parseSource(String? source) {
  if (source == null || !source.startsWith('openstreetmap:')) return null;
  final rest = source.substring('openstreetmap:'.length).split('/');
  if (rest.length != 2) return null;
  return (rest[0], rest[1]);
}

Future<Map<String, Map<String, String>>> _fetchOsmTags(
  List<(String, String)> refs,
) async {
  final out = <String, Map<String, String>>{};
  // Small enough that a busy Overpass still answers, and that a retry after a
  // timeout is cheap rather than another ninety seconds of the same work.
  const batchSize = 40;

  for (var start = 0; start < refs.length; start += batchSize) {
    final batch = refs.skip(start).take(batchSize).toList();
    final byType = <String, List<String>>{};
    for (final (type, id) in batch) {
      byType.putIfAbsent(type, () => []).add(id);
    }
    final clauses = byType.entries
        .map((entry) => '${entry.key}(id:${entry.value.join(",")});')
        .join();
    final query = '[out:json][timeout:90];($clauses);out tags;';

    stdout.writeln('osm: ${start + batch.length}/${refs.length}...');
    final text = await _post(_overpass, 'data=${Uri.encodeComponent(query)}');
    final elements = (jsonDecode(text) as Map)['elements'] as List<Object?>;
    for (final element in elements.cast<Map<String, Object?>>()) {
      final tags = element['tags'] as Map<String, Object?>? ?? {};
      out['${element['type']}/${element['id']}'] = {
        for (final entry in tags.entries)
          if (_keepTags.contains(entry.key)) entry.key: '${entry.value}',
      };
    }
    // Overpass is a shared free service and asks callers to leave a gap.
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  return out;
}

Future<Map<String, String>> _fetchWikidataDescriptions(
  List<String> qids,
) async {
  final out = <String, String>{};
  const batchSize = 45;

  for (var start = 0; start < qids.length; start += batchSize) {
    final batch = qids.skip(start).take(batchSize).toList();
    final url =
        '$_wikidata?action=wbgetentities&ids=${batch.join("|")}'
        '&props=descriptions&languages=vi|en&format=json';
    stdout.writeln('wikidata: ${start + batch.length}/${qids.length}...');
    final data = jsonDecode(await _get(url)) as Map<String, Object?>;
    final entities = data['entities'] as Map<String, Object?>? ?? {};
    for (final entry in entities.entries) {
      final descriptions =
          (entry.value as Map<String, Object?>)['descriptions']
              as Map<String, Object?>? ??
          {};
      final vi = descriptions['vi'] as Map<String, Object?>?;
      final en = descriptions['en'] as Map<String, Object?>?;
      final value = (vi ?? en)?['value'] as String?;
      if (value != null) out[entry.key] = value;
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
  return out;
}

/// Street and ward for each place, in Vietnamese, from its own coordinates.
///
/// Worth a request each because it is the one fact every place has: most of
/// them carry no address tag at all, and "a market in Ho Chi Minh City" tells
/// a reader nothing they could not see from the map.
///
/// Nominatim is free and asks for one request per second and a real user
/// agent. Both are honoured; do not lower the delay.
Future<Map<String, Map<String, String>>> _fetchAddresses(
  List<(String, double, double)> places,
) async {
  final out = <String, Map<String, String>>{};
  var done = 0;

  for (final (id, latitude, longitude) in places) {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude'
        '&lon=$longitude&format=jsonv2&accept-language=vi&zoom=18';
    try {
      final data = jsonDecode(await _get(url)) as Map<String, Object?>;
      final address = data['address'] as Map<String, Object?>? ?? {};
      out[id] = {
        for (final key in const [
          'road',
          'house_number',
          'quarter',
          'suburb',
          'city_district',
          'county',
          'city',
        ])
          if (address[key] != null) key: '${address[key]}',
      };
    } on Object catch (error) {
      stdout.writeln('  ($id: $error) bo qua');
    }
    done++;
    if (done % 25 == 0) {
      stdout.writeln('nominatim: $done/${places.length}...');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1100));
  }
  return out;
}

/// The lead section of each article, as plain text.
Future<Map<String, String>> _fetchWikipediaLeads(List<String> titles) async {
  final out = <String, String>{};
  const batchSize = 18;

  for (var start = 0; start < titles.length; start += batchSize) {
    final batch = titles.skip(start).take(batchSize).toList();
    final joined = batch.map(Uri.encodeComponent).join('|');
    final url =
        '$_wikipediaVi?action=query&prop=extracts&exintro=1&explaintext=1'
        '&redirects=1&titles=$joined&format=json&formatversion=2';
    stdout.writeln('wikipedia: ${start + batch.length}/${titles.length}...');
    final data = jsonDecode(await _get(url)) as Map<String, Object?>;
    final pages =
        (data['query'] as Map<String, Object?>?)?['pages'] as List<Object?>? ??
        [];
    for (final page in pages.cast<Map<String, Object?>>()) {
      final extract = page['extract'] as String?;
      final title = page['title'] as String?;
      if (extract != null && title != null && extract.trim().isNotEmpty) {
        out[title] = extract.trim();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
  return out;
}

Future<void> main(List<String> args) async {
  final limitIndex = args.indexOf('--limit');
  final limit = limitIndex >= 0 && limitIndex + 1 < args.length
      ? int.tryParse(args[limitIndex + 1])
      : null;

  final root = repoRootPath();
  final file = File('$root/content/checkpoints.json');
  final parsed = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  var checkpoints = (parsed['checkpoints']! as List<Object?>)
      .cast<Map<String, Object?>>();
  if (limit != null) checkpoints = checkpoints.take(limit).toList();

  final refByCheckpoint = <String, String>{};
  final refs = <(String, String)>[];
  final coordsById = <(String, double, double)>[];
  for (final checkpoint in checkpoints) {
    final coordinates = checkpoint['coordinates'] as Map<String, Object?>?;
    final latitude = (coordinates?['lat'] as num?)?.toDouble();
    final longitude = (coordinates?['lon'] as num?)?.toDouble();
    if (latitude != null && longitude != null) {
      coordsById.add(('${checkpoint['id']}', latitude, longitude));
    }
    final ref = _parseSource(coordinates?['source'] as String?);
    if (ref == null) continue;
    refByCheckpoint['${checkpoint['id']}'] = '${ref.$1}/${ref.$2}';
    refs.add(ref);
  }
  stdout.writeln(
    'place-facts: ${checkpoints.length} noi, ${refs.length} co ma OSM.\n',
  );

  final tagsByRef = await _fetchOsmTags(refs);

  final qids = <String>{};
  final titles = <String>{};
  for (final tags in tagsByRef.values) {
    final qid = tags['wikidata'];
    if (qid != null && qid.startsWith('Q')) qids.add(qid);
    final article = tags['wikipedia'];
    if (article != null && article.startsWith('vi:')) {
      titles.add(article.substring(3));
    }
  }
  stdout.writeln();
  final descriptions = qids.isEmpty
      ? <String, String>{}
      : await _fetchWikidataDescriptions(qids.toList());
  final leads = titles.isEmpty
      ? <String, String>{}
      : await _fetchWikipediaLeads(titles.toList());
  stdout.writeln();
  final addresses = await _fetchAddresses(coordsById);

  final places = <String, Object?>{};
  for (final checkpoint in checkpoints) {
    final id = '${checkpoint['id']}';
    final ref = refByCheckpoint[id];
    final tags = ref == null ? <String, String>{} : (tagsByRef[ref] ?? {});
    final qid = tags['wikidata'];
    final article = tags['wikipedia'];
    final title = article != null && article.startsWith('vi:')
        ? article.substring(3)
        : null;
    places[id] = {
      'name': checkpoint['name'],
      'category': checkpoint['category'],
      'address': checkpoint['address'],
      'osm': ref,
      'tags': tags,
      if (addresses[id] != null && addresses[id]!.isNotEmpty)
        'place': addresses[id],
      if (qid != null && descriptions[qid] != null)
        'wikidataDescription': descriptions[qid],
      if (title != null && leads[title] != null) 'wikipediaTitle': title,
      if (title != null && leads[title] != null) 'wikipediaLead': leads[title],
    };
  }

  File('$root/tool/place_facts/place-facts.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      '_readme':
          'Du lieu tho tu OpenStreetMap, Wikidata va Wikipedia tieng Viet. '
          'Sinh boi fetch_place_facts.dart, bi gitignore - chay lai thay vi '
          'tin mot ban da commit. Khong cau nao o day do cong cu nghi ra.',
      'fetchedAt': DateTime.now().toUtc().toIso8601String().substring(0, 10),
      'places': places,
    }),
  );

  final values = places.values.cast<Map<String, Object?>>();
  stdout
    ..writeln()
    ..writeln('place-facts: ghi ${places.length} noi.')
    ..writeln(
      '  co doan mo dau Wikipedia : '
      '${values.where((p) => p['wikipediaLead'] != null).length}',
    )
    ..writeln(
      '  co mo ta Wikidata        : '
      '${values.where((p) => p['wikidataDescription'] != null).length}',
    )
    ..writeln('  -> tool/place_facts/place-facts.json');
}
