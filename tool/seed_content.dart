// Seeds pilot content from content/*.json into Supabase.
//
// The JSON files are the source of truth, not the database. Running this twice
// must leave the database identical — content is re-seeded on every deploy and
// a duplicate would put the same place on the map twice.
//
// The pilot place list is NOT settled, and the script is built for that. A
// place can be added, edited, given a photograph, marked as needing the QR
// fallback, or dropped entirely by editing content/checkpoints.json — none of
// it is a code change.
//
// Dropping one needs care, which is why it is opt-in. An upsert alone cannot
// express a removal: a row deleted from the file simply stops being written
// and lingers in the database forever, so the map keeps a place the content
// no longer knows about. `--prune` closes that gap, but deleting a checkpoint
// CASCADES into visit_state and erases what users have unlocked there — the
// one thing the whole architecture exists to protect. So a prune refuses to
// touch any checkpoint that somebody has already visited unless --force says
// otherwise.
//
// Usage:
//   set SUPABASE_URL=... && set SUPABASE_SERVICE_ROLE_KEY=...
//   dart run tool/seed_content.dart [--allow-unverified] [--dry-run]
//                                   [--prune [--force]]
//
// --dry-run never writes. Without credentials it only checks the file; with
// them it also reports what a prune would remove.
//
// The service role key bypasses row level security, which is why this is a
// developer tool and never ships inside the app.

import 'dart:convert';
import 'dart:io';

Directory repoRoot() {
  final scriptPath = Platform.script.toFilePath().replaceAll(r'\', '/');
  final toolDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
  return Directory(toolDir.substring(0, toolDir.lastIndexOf('/')));
}

class SeedCheckpoint {
  SeedCheckpoint({
    required this.id,
    required this.name,
    required this.category,
    required this.radiusMeters,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isVerified,
    required this.note,
    required this.requiresQrFallback,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String category;
  final int radiusMeters;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final String? note;

  /// Set per place by the S3 field survey, for the spots where GPS is too
  /// unreliable to be the only proof. Authored here rather than in code so a
  /// survey result is a content edit.
  final bool requiresQrFallback;

  /// Marker photograph. Null until a picture clears content/image-licenses.md;
  /// the column exists so attaching one later is a content edit too.
  final String? photoUrl;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// PostgREST casts this text to `geography` on insert. Longitude first —
  /// WKT is x then y, which is the opposite of how coordinates are spoken.
  String get geom => 'SRID=4326;POINT($longitude $latitude)';

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'geom': geom,
    'radius_m': radiusMeters,
    'category': category,
    'address': address,
    'requires_qr_fallback': requiresQrFallback,
    'photo_url': photoUrl,
  };

  static SeedCheckpoint fromJson(Map<String, Object?> json) {
    final coordinates = json['coordinates'] as Map<String, Object?>?;
    return SeedCheckpoint(
      id: json['id']! as String,
      name: json['name']! as String,
      category: json['category']! as String,
      radiusMeters: json['radiusMeters']! as int,
      address: json['address'] as String?,
      latitude: (coordinates?['lat'] as num?)?.toDouble(),
      longitude: (coordinates?['lon'] as num?)?.toDouble(),
      isVerified: coordinates?['verified'] as bool? ?? false,
      note: json['note'] as String?,
      requiresQrFallback: json['requiresQrFallback'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// What a run would change, worked out before anything is written.
class SyncPlan {
  const SyncPlan({required this.upsert, required this.orphans});

  /// Ids present in the content file.
  final List<String> upsert;

  /// Ids the server still holds that the content file no longer names. These
  /// are what `--prune` deletes.
  final List<String> orphans;

  bool get isClean => orphans.isEmpty;
}

/// Pure diff between the authored place list and what the server holds.
///
/// Kept separate from the HTTP calls so the rule that decides a deletion can
/// be tested without a database.
SyncPlan planSync(Iterable<String> fileIds, Iterable<String> serverIds) {
  final authored = fileIds.toSet();
  final orphans = serverIds.where((id) => !authored.contains(id)).toList()
    ..sort();
  return SyncPlan(upsert: fileIds.toList(), orphans: orphans);
}

/// The orphans a prune must not touch: those somebody has already visited.
///
/// Deleting one cascades into visit_state, and unlock history is the single
/// thing the architecture treats as irreplaceable. Losing it silently to a
/// content edit would be the worst kind of failure this project has — the
/// user finds out by seeing a place they walked to go dark again.
List<String> orphansWithVisits(Map<String, int> visitCounts) =>
    (visitCounts.entries.where((e) => e.value > 0).map((e) => e.key).toList()
      ..sort());

Future<void> main(List<String> args) async {
  final allowUnverified = args.contains('--allow-unverified');
  final isDryRun = args.contains('--dry-run');
  final shouldPrune = args.contains('--prune');
  final force = args.contains('--force');

  if (force && !shouldPrune) {
    stderr.writeln('seed: --force chỉ có nghĩa khi đi cùng --prune.');
    exit(1);
  }

  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (!isDryRun && (url == null || key == null)) {
    stderr.writeln(
      'seed: thiếu SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY.\n'
      'Xem .env.example. Dùng --dry-run để kiểm tra file mà không cần server.',
    );
    exit(1);
  }

  final file = File('${repoRoot().path}/content/checkpoints.json');
  if (!file.existsSync()) {
    stderr.writeln('seed: không tìm thấy ${file.path}');
    exit(1);
  }

  final parsed = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final checkpoints = (parsed['checkpoints']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(SeedCheckpoint.fromJson)
      .toList();

  final missing = checkpoints.where((c) => !c.hasCoordinates).toList();
  final unverified = checkpoints
      .where((c) => c.hasCoordinates && !c.isVerified)
      .toList();

  stdout.writeln('seed: ${checkpoints.length} checkpoint trong file');
  if (missing.isNotEmpty) {
    stdout.writeln('  ${missing.length} thiếu toạ độ, sẽ bỏ qua:');
    for (final c in missing) {
      stdout.writeln('    ${c.id} — ${c.note ?? "chưa có ghi chú"}');
    }
  }

  // The gate that stops half-checked coordinates reaching a real project.
  // Wrong coordinates do not fail loudly: they send a user to the wrong
  // building and look like a working app.
  if (unverified.isNotEmpty && !allowUnverified) {
    stderr.writeln(
      '\nseed: DỪNG — ${unverified.length} toạ độ chưa kiểm chứng.\n'
      'Toạ độ sai không báo lỗi, nó chỉ dẫn người dùng tới nhầm chỗ.\n'
      'Kiểm chứng trên bản đồ vệ tinh rồi đổi verified thành true, hoặc\n'
      'truyền --allow-unverified nếu chỉ đang thử pipeline trên máy local.',
    );
    exit(1);
  }

  final ready = checkpoints.where((c) => c.hasCoordinates).toList();
  if (unverified.isNotEmpty) {
    stdout.writeln(
      '  ⚠ ${unverified.length} toạ độ CHƯA KIỂM CHỨNG, vẫn nạp vì --allow-unverified',
    );
  }

  if (isDryRun) {
    stdout.writeln('\nseed: --dry-run, không gửi gì. Sẽ nạp ${ready.length}:');
    for (final c in ready) {
      stdout.writeln('    ${c.id.padRight(22)} ${c.geom}');
    }
    // Without credentials the file check is everything a dry run can do.
    // Whether the server holds a place the file dropped is not knowable here.
    if (url == null || key == null) {
      stdout.writeln(
        '\nseed: chưa có thông tin đăng nhập — bỏ qua bước đối chiếu máy chủ.\n'
        'Đặt SUPABASE_URL và SUPABASE_SERVICE_ROLE_KEY để xem cả phần thừa.',
      );
      exit(0);
    }
  }

  // Non-null past both guards above: a real run demands credentials, and a
  // dry run without them has already exited.
  final apiUrl = url!;
  final apiKey = key!;

  final client = HttpClient();
  var status = 0;
  try {
    if (!isDryRun) {
      await request(
        client,
        'POST',
        Uri.parse('$apiUrl/rest/v1/checkpoints'),
        apiKey,
        body: jsonEncode(ready.map((c) => c.toRow()).toList()),
        // Upsert. This is what makes a second run a no-op rather than a
        // duplicate-key error.
        extraHeaders: {'Prefer': 'resolution=merge-duplicates'},
      );
      stdout.writeln('\nseed: đã nạp ${ready.length} checkpoint.');
    }

    final plan = planSync(
      ready.map((c) => c.id),
      await serverCheckpointIds(client, apiUrl, apiKey),
    );

    if (plan.isClean) {
      stdout.writeln('seed: máy chủ không giữ checkpoint nào ngoài file.');
    } else {
      status = await reconcileOrphans(
        client,
        apiUrl,
        apiKey,
        plan.orphans,
        shouldPrune: shouldPrune,
        force: force,
        isDryRun: isDryRun,
      );
    }
  } finally {
    client.close();
  }
  exit(status);
}

/// Reports what the server holds that the content file no longer names, and
/// removes it when asked.
///
/// Returns the process exit code: refusing a prune the caller explicitly asked
/// for is a failure, while merely reporting drift is not.
Future<int> reconcileOrphans(
  HttpClient client,
  String url,
  String key,
  List<String> orphans, {
  required bool shouldPrune,
  required bool force,
  required bool isDryRun,
}) async {
  stdout.writeln(
    '\nseed: ${orphans.length} checkpoint còn trên máy chủ nhưng KHÔNG còn '
    'trong file:',
  );
  for (final id in orphans) {
    stdout.writeln('    $id');
  }

  if (!shouldPrune) {
    stdout.writeln(
      '\nChúng vẫn hiện trên bản đồ. Chạy lại với --prune để xoá,\n'
      'hoặc thêm lại vào content/checkpoints.json nếu xoá là nhầm.',
    );
    return 0;
  }

  final counts = await visitCounts(client, url, key, orphans);
  final blocked = orphansWithVisits(counts);

  if (blocked.isNotEmpty && !force) {
    stderr.writeln(
      '\nseed: DỪNG — ${blocked.length} checkpoint đã có người ghé:',
    );
    for (final id in blocked) {
      stderr.writeln('    $id — ${counts[id]} lượt trong visit_state');
    }
    stderr.writeln(
      '\nXoá checkpoint sẽ CASCADE và xoá luôn những lượt mở khoá đó. Lịch sử\n'
      'mở khoá là thứ duy nhất không dựng lại được. Nếu thật sự muốn mất,\n'
      'truyền thêm --force.',
    );
    return 1;
  }

  if (isDryRun) {
    stdout.writeln('\nseed: --dry-run, sẽ xoá ${orphans.length} mục ở trên.');
    return 0;
  }

  await request(
    client,
    'DELETE',
    Uri.parse(
      '$url/rest/v1/checkpoints',
    ).replace(queryParameters: {'id': 'in.(${orphans.join(',')})'}),
    key,
  );
  stdout.writeln('\nseed: đã xoá ${orphans.length} checkpoint thừa.');
  if (blocked.isNotEmpty) {
    stdout.writeln(
      '  ⚠ --force: đã xoá kèm lượt mở khoá của ${blocked.length} điểm.',
    );
  }
  return 0;
}

/// Every checkpoint id the server currently holds.
Future<List<String>> serverCheckpointIds(
  HttpClient client,
  String url,
  String key,
) async {
  final body = await request(
    client,
    'GET',
    Uri.parse(
      '$url/rest/v1/checkpoints',
    ).replace(queryParameters: {'select': 'id'}),
    key,
  );
  return (jsonDecode(body) as List<Object?>)
      .cast<Map<String, Object?>>()
      .map((row) => row['id']! as String)
      .toList();
}

/// How many visit_state rows each of [ids] carries.
///
/// Counted from the returned rows rather than a server-side aggregate: the
/// list is at most the pilot's dozen places, and a plain select needs no
/// agreement with PostgREST about count syntax.
Future<Map<String, int>> visitCounts(
  HttpClient client,
  String url,
  String key,
  List<String> ids,
) async {
  if (ids.isEmpty) return const {};
  final body = await request(
    client,
    'GET',
    Uri.parse('$url/rest/v1/visit_state').replace(
      queryParameters: {
        'select': 'checkpoint_id',
        'checkpoint_id': 'in.(${ids.join(',')})',
      },
    ),
    key,
  );
  final counts = {for (final id in ids) id: 0};
  for (final row in (jsonDecode(body) as List<Object?>)) {
    final id = (row! as Map<String, Object?>)['checkpoint_id']! as String;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
}

/// One PostgREST call. Any non-2xx answer ends the run — a seed that carried
/// on after a rejected write would report success over a half-applied change.
Future<String> request(
  HttpClient client,
  String method,
  Uri uri,
  String key, {
  String? body,
  Map<String, String> extraHeaders = const {},
}) async {
  final req = await client.openUrl(method, uri);
  req.headers
    ..set('apikey', key)
    ..set('Authorization', 'Bearer $key');
  for (final header in extraHeaders.entries) {
    req.headers.set(header.key, header.value);
  }
  if (body != null) {
    req.headers.set('Content-Type', 'application/json; charset=utf-8');
    req.add(utf8.encode(body));
  }

  final response = await req.close();
  final text = await response.transform(utf8.decoder).join();
  if (response.statusCode >= 300) {
    stderr.writeln(
      '\nseed: máy chủ từ chối (HTTP ${response.statusCode}) '
      '— $method ${uri.path}',
    );
    stderr.writeln(text);
    exit(1);
  }
  return text;
}
