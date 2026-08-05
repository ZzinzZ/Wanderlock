// Seeds pilot content from content/*.json into Supabase.
//
// The JSON files are the source of truth, not the database. Running this twice
// must leave the database identical — content is re-seeded on every deploy and
// a duplicate would put the same place on the map twice.
//
// Usage:
//   set SUPABASE_URL=... && set SUPABASE_SERVICE_ROLE_KEY=...
//   dart run tool/seed_content.dart [--allow-unverified] [--dry-run]
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
    );
  }
}

Future<void> main(List<String> args) async {
  final allowUnverified = args.contains('--allow-unverified');
  final isDryRun = args.contains('--dry-run');

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
    exit(0);
  }

  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$url/rest/v1/checkpoints'));
    request.headers
      ..set('apikey', key!)
      ..set('Authorization', 'Bearer $key')
      ..set('Content-Type', 'application/json; charset=utf-8')
      // Upsert. This is what makes a second run a no-op rather than a
      // duplicate-key error.
      ..set('Prefer', 'resolution=merge-duplicates');
    request.add(utf8.encode(jsonEncode(ready.map((c) => c.toRow()).toList())));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      stderr.writeln('\nseed: máy chủ từ chối (HTTP ${response.statusCode})');
      stderr.writeln(body);
      exit(1);
    }
    stdout.writeln('\nseed: đã nạp ${ready.length} checkpoint.');
  } finally {
    client.close();
  }
}
