import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// Reads the published checkpoint list from Supabase.
///
/// Deliberately narrow: it fetches and maps, and does not decide anything. If
/// the network is down it throws and the repository serves the cache — the
/// decision about what the user sees belongs there, not here.
abstract interface class CheckpointRemoteSource {
  Future<List<Checkpoint>> fetchAll();
}

class SupabaseCheckpointRemoteSource implements CheckpointRemoteSource {
  const SupabaseCheckpointRemoteSource(this._client);

  final SupabaseClient _client;

  /// `geom` is never selected. PostgREST takes column names, aliases and
  /// casts — not function calls — so `ST_Y(geom)` is read as a foreign key
  /// embed and fails. `latitude` and `longitude` are generated columns on the
  /// table, kept in step with `geom` by the database itself.
  static const _columns =
      'id, name, latitude, longitude, radius_m, category, '
      'requires_qr_fallback, address, photo_url';

  @override
  Future<List<Checkpoint>> fetchAll() async {
    final rows = await _client.from('checkpoints').select(_columns);
    return rows.map(_fromJson).toList();
  }

  static Checkpoint _fromJson(Map<String, dynamic> json) => Checkpoint(
    id: json['id'] as String,
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radiusMeters: json['radius_m'] as int,
    category: CheckpointCategory.parse(json['category'] as String),
    requiresQrFallback: json['requires_qr_fallback'] as bool? ?? false,
    address: json['address'] as String?,
    photoUrl: json['photo_url'] as String?,
  );
}
