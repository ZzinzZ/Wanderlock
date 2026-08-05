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
  const SupabaseCheckpointRemoteSource(this._clientOf);

  /// Resolved per call, not held. The connection is established in the
  /// background after launch, so a source built at startup would otherwise
  /// capture a null client forever.
  final SupabaseClient? Function() _clientOf;

  /// A query that hangs is indistinguishable from being offline to someone
  /// walking, so it is capped and then treated as such.
  // design-token-ignore: a network timeout is not a design value
  static const _timeout = Duration(seconds: 10);

  /// `geom` is never selected. PostgREST takes column names, aliases and
  /// casts — not function calls — so `ST_Y(geom)` is read as a foreign key
  /// embed and fails. `latitude` and `longitude` are generated columns on the
  /// table, kept in step with `geom` by the database itself.
  static const _columns =
      'id, name, latitude, longitude, radius_m, category, '
      'requires_qr_fallback, address, photo_url';

  @override
  Future<List<Checkpoint>> fetchAll() async {
    final client = _clientOf();
    // Thrown, not returned: the repository already turns every failure into
    // "keep serving the cache", and not-connected-yet is that same case.
    if (client == null) {
      throw StateError('Supabase is not connected yet');
    }

    final rows = await client
        .from('checkpoints')
        .select(_columns)
        .timeout(_timeout);
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
