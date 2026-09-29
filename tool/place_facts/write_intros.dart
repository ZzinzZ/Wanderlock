// Writes a short factual introduction for every place nobody has written
// about, from the facts gathered by fetch_place_facts.dart.
//
// **Every sentence here is assembled from a fact that is in the data.** There
// is no phrase in this file that describes a place: only the grammar that
// joins "market", "Nguyen Dinh Chieu street" and "open 05:00-18:00" into a
// Vietnamese sentence. Nothing is inferred, nothing is embellished, and a
// place with only a name and a type gets one short sentence rather than a
// paragraph of invention.
//
// That is why these are written as `kind: "intro"` and not as chapters. A
// chapter is written from a source about the place; this is a label.
//
//   dart run tool/place_facts/fetch_place_facts.dart
//   dart run tool/place_facts/write_intros.dart [--force] [--dry-run]
//
// Skips any chapter that already exists, so a hand-written one is never
// overwritten. `--force` overwrites intros it wrote before, never chapters.

import 'dart:convert';
import 'dart:io';

import '../support/repo_root.dart';

/// What to call the place, most specific tag first.
///
/// Falls through to the checkpoint's own category, which is always present.
String _kindPhrase(Map<String, String> tags, String category) {
  final historic = tags['historic'];
  final memorial = tags['memorial'];
  if (historic == 'memorial' || memorial != null) {
    return switch (memorial) {
      'stele' || 'stone' => 'một tấm bia tưởng niệm',
      'statue' => 'một bức tượng tưởng niệm',
      'plaque' => 'một tấm biển tưởng niệm',
      'war_memorial' => 'một đài tưởng niệm chiến tranh',
      _ => 'một công trình tưởng niệm',
    };
  }
  if (historic == 'monument') return 'một tượng đài';
  if (historic == 'memorial_cross') return 'một thánh giá tưởng niệm';

  final religion = tags['religion'];
  if (tags['amenity'] == 'place_of_worship' || religion != null) {
    return switch ((religion, tags['denomination'])) {
      ('buddhist', _) => 'một ngôi chùa',
      ('christian', 'roman_catholic') => 'một nhà thờ Công giáo',
      ('christian', _) => 'một nhà thờ',
      ('caodaism', _) => 'một thánh thất Cao Đài',
      ('muslim', _) => 'một thánh đường Hồi giáo',
      ('hindu', _) => 'một ngôi đền Hindu',
      ('taoist', _) => 'một ngôi miếu',
      _ => 'một cơ sở tín ngưỡng',
    };
  }

  if (tags['amenity'] == 'marketplace' || tags['shop'] == 'mall') {
    return tags['shop'] == 'mall' ? 'một trung tâm thương mại' : 'một khu chợ';
  }
  if (tags['leisure'] == 'park') return 'một công viên';
  if (tags['leisure'] == 'garden') return 'một khu vườn';
  if (tags['leisure'] == 'water_park') return 'một công viên nước';
  if (tags['tourism'] == 'museum' || tags['museum'] != null) {
    return 'một bảo tàng';
  }
  if (tags['tourism'] == 'theme_park') return 'một công viên giải trí';
  if (tags['tourism'] == 'gallery') return 'một phòng trưng bày';
  if (tags['tourism'] == 'artwork') return 'một tác phẩm nghệ thuật công cộng';
  if (tags['tourism'] == 'viewpoint') return 'một điểm ngắm cảnh';
  if (tags['amenity'] == 'theatre') return 'một nhà hát';
  if (tags['amenity'] == 'cinema') return 'một rạp chiếu phim';
  if (tags['amenity'] == 'restaurant') return 'một nhà hàng';
  if (tags['amenity'] == 'cafe') return 'một quán cà phê';
  if (tags['amenity'] == 'fast_food') return 'một quán ăn nhanh';
  if (tags['amenity'] == 'library') return 'một thư viện';
  if (tags['amenity'] == 'arts_centre') return 'một trung tâm nghệ thuật';
  if (tags['shop'] == 'department_store') return 'một cửa hàng bách hoá';
  if (tags['man_made'] == 'bridge') return 'một cây cầu';

  return switch (category) {
    'market' => 'một khu chợ',
    'park' => 'một công viên',
    'monument' => 'một di tích',
    'museum' => 'một bảo tàng',
    'shopping' => 'một trung tâm mua sắm',
    'food' => 'một quán ăn',
    'entertainment' => 'một điểm vui chơi',
    'sight' => 'một điểm tham quan',
    'religious' => 'một cơ sở tín ngưỡng',
    'architecture' => 'một công trình kiến trúc',
    _ => 'một địa điểm',
  };
}

/// Where it is.
///
/// Prefers the reverse-geocoded street and ward, which every place has,
/// over the address tags, which most of them lack. Without this the opening
/// sentence would be "a market in Ho Chi Minh City" for half the pilot, which
/// tells a reader nothing the map has not already shown them.
String? _wherePhrase(
  Map<String, String> tags,
  Map<String, String> place,
  String? address,
) {
  final road = place['road'] ?? tags['addr:street'];
  final number = place['house_number'] ?? tags['addr:housenumber'];
  final ward = place['suburb'] ?? place['quarter'];
  final district = place['city_district'] ?? place['county'];

  final parts = <String>[
    if (number != null && road != null)
      'số $number $road'
    else if (road != null)
      road
    else if (address != null && address.trim().isNotEmpty)
      address.trim(),
    if (ward != null) ward,
    if (district != null) district,
  ];
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

/// Opening hours, but only when the OSM syntax is simple enough to say
/// plainly. Anything with exceptions, holidays or split shifts is left out
/// rather than mistranslated into a promise the place will not keep.
String? _hoursPhrase(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  final simple = RegExp(r'^Mo-Su (\d{2}:\d{2})-(\d{2}:\d{2})$');
  final match = simple.firstMatch(value);
  if (match != null) {
    return 'Mở cửa hằng ngày từ ${match.group(1)} đến ${match.group(2)}';
  }
  if (value == '24/7') return 'Mở cửa suốt ngày đêm';
  return null;
}

/// A four-digit year out of an OSM date, which may be `1966`, `1966-10-31`
/// or something far messier.
String? _year(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'(1[6-9]\d{2}|20[0-2]\d)').firstMatch(raw);
  return match?.group(1);
}

List<String> _paragraphs(Map<String, Object?> json) {
  final tags = (json['tags'] as Map<String, Object?>? ?? {}).map(
    (key, value) => MapEntry(key, '$value'),
  );
  final name = '${json['name']}';
  final category = '${json['category']}';
  final address = json['address'] as String?;

  final place = (json['place'] as Map<String, Object?>? ?? {}).map(
    (key, value) => MapEntry(key, '$value'),
  );
  final kind = _kindPhrase(tags, category);
  final where = _wherePhrase(tags, place, address);
  final opening = where == null
      ? '$name là $kind ở Thành phố Hồ Chí Minh.'
      : '$name là $kind ở $where, Thành phố Hồ Chí Minh.';

  final extras = <String>[];

  final alt = tags['alt_name'] ?? tags['alt_name:vi'];
  if (alt != null && alt != name) extras.add('Nơi này còn được gọi là $alt.');

  final old = tags['old_name'];
  if (old != null && old != name) extras.add('Tên cũ là $old.');

  final english = tags['name:en'];
  if (english != null && english != name) {
    extras.add('Tên tiếng Anh ghi nhận là $english.');
  }

  final year = _year(tags['start_date'] ?? tags['opening_date']);
  if (year != null) extras.add('Dữ liệu ghi nhận năm $year.');

  if (tags['heritage'] != null) {
    extras.add('Được ghi nhận là di tích được xếp hạng.');
  }

  final levels = tags['building:levels'];
  if (levels != null) extras.add('Công trình cao $levels tầng.');

  final operator = tags['operator'];
  if (operator != null && operator != name) {
    extras.add('Đơn vị quản lý: $operator.');
  }

  final cuisine = tags['cuisine'];
  if (cuisine != null) {
    extras.add('Món ghi nhận: ${cuisine.replaceAll(';', ', ')}.');
  }

  final hours = _hoursPhrase(tags['opening_hours']);
  if (hours != null) extras.add('$hours.');

  final described = tags['description:vi'] ?? tags['description'];
  if (described != null) extras.add(described.trim());

  final wikidata = json['wikidataDescription'] as String?;
  if (wikidata != null)
    extras.add('Wikidata mô tả nơi này là ${wikidata.trim()}.');

  // No closing disclaimer. The button says "Xem giới thiệu" rather than "Đọc
  // chương", and the source line under the text names the open data it came
  // from; repeating that in prose on 226 cards would be noise.
  return [opening, if (extras.isNotEmpty) extras.join(' ')];
}

String _sourceLine(Map<String, Object?> place) {
  final hasWikidata = place['wikidataDescription'] != null;
  return hasWikidata ? 'OpenStreetMap và Wikidata' : 'OpenStreetMap';
}

Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final dryRun = args.contains('--dry-run');
  final root = repoRootPath();

  final factsFile = File('$root/tool/place_facts/place-facts.json');
  if (!factsFile.existsSync()) {
    stderr.writeln(
      'write_intros: thiếu place-facts.json — chạy fetch_place_facts.dart '
      'trước.',
    );
    exitCode = 1;
    return;
  }
  final facts =
      (jsonDecode(factsFile.readAsStringSync())
              as Map<String, Object?>)['places']!
          as Map<String, Object?>;

  final storiesDir = Directory('$root/content/stories');
  final existing = <String, String>{};
  for (final file in storiesDir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.endsWith('.json') || name.startsWith('_')) continue;
    final parsed = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    existing['${parsed['checkpointId']}'] = '${parsed['kind'] ?? 'chapter'}';
  }

  var written = 0;
  var skippedChapter = 0;
  var skippedIntro = 0;

  for (final entry in facts.entries) {
    final id = entry.key;
    final place = entry.value! as Map<String, Object?>;

    final kind = existing[id];
    if (kind == 'chapter') {
      skippedChapter++;
      continue;
    }
    if (kind == 'intro' && !force) {
      skippedIntro++;
      continue;
    }

    final paragraphs = _paragraphs(place);
    final chapter = <String, Object?>{
      'id': id,
      'checkpointId': id,
      'kind': 'intro',
      'title': '${place['name']}',
      'estimatedMinutes': 1,
      'source': _sourceLine(place),
      'nodes': [
        for (final text in paragraphs) {'type': 'narration', 'text': text},
      ],
    };

    if (!dryRun) {
      File('$root/content/stories/$id.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(chapter)}\n',
      );
    }
    written++;
  }

  stdout
    ..writeln('write_intros:${dryRun ? ' (--dry-run, không ghi)' : ''}')
    ..writeln('  viết giới thiệu     : $written')
    ..writeln('  bỏ qua, có chương   : $skippedChapter')
    ..writeln('  bỏ qua, đã có intro : $skippedIntro');
  if (!dryRun) {
    stdout.writeln(
      '\nNhớ đồng bộ bản đóng gói: chép content/stories sang '
      'app/assets/content/stories',
    );
  }
}
