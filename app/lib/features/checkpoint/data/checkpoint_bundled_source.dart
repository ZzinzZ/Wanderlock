import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:wanderlock/features/checkpoint/domain/checkpoint.dart';

/// The pilot content that ships inside the binary.
///
/// It exists so the map is never empty. A fresh install with no network, no
/// Supabase configured, and an empty cache still draws twelve places — which
/// is what makes the lenses buildable and reviewable before the backend is
/// wired to a real project.
///
/// **This is not a mock in the usual sense.** It reads the same
/// `content/checkpoints.json` the seed script uploads, through the same
/// [Checkpoint] entity, into the same Drift cache. When a server appears, its
/// answer replaces these rows and nothing above the data layer notices — the
/// UI has never known where a checkpoint came from.
///
/// The copy under `app/assets/content/` is kept identical to the root file by
/// `test/content/bundled_content_test.dart`; Flutter cannot bundle an asset
/// from outside the package directory, so a copy is the only option and a
/// test is what stops it drifting.
class CheckpointBundledSource {
  const CheckpointBundledSource({this.assetPath = defaultAssetPath, this.load});

  static const String defaultAssetPath = 'assets/content/checkpoints.json';

  final String assetPath;

  /// Overridable so the parser can be tested without a Flutter asset bundle.
  final Future<String> Function(String assetPath)? load;

  Future<List<Checkpoint>> readAll() async {
    final raw = await (load ?? rootBundle.loadString)(assetPath);
    return parse(raw);
  }

  /// Turns the authored JSON into entities.
  ///
  /// Places without coordinates are dropped rather than defaulted to zero:
  /// (0, 0) is in the Gulf of Guinea, and a marker there would look like a bug
  /// in the map rather than missing content.
  ///
  /// Unverified coordinates are kept. The seed script refuses to upload them
  /// because a wrong coordinate on the server is a wrong unlock radius for
  /// everyone; drawing one locally is only ever a drawing.
  static List<Checkpoint> parse(String raw) {
    final root = jsonDecode(raw) as Map<String, Object?>;
    final entries = (root['checkpoints'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();

    final checkpoints = <Checkpoint>[];
    for (final entry in entries) {
      final coordinates = entry['coordinates'] as Map<String, Object?>?;
      final lat = (coordinates?['lat'] as num?)?.toDouble();
      final lon = (coordinates?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      checkpoints.add(
        Checkpoint(
          id: entry['id']! as String,
          name: entry['name']! as String,
          latitude: lat,
          longitude: lon,
          radiusMeters: (entry['radiusMeters']! as num).toInt(),
          category: CheckpointCategory.parse(entry['category']! as String),
          requiresQrFallback: entry['requiresQrFallback'] as bool? ?? false,
          address: entry['address'] as String?,
          photoUrl: entry['photoUrl'] as String?,
        ),
      );
    }
    return checkpoints;
  }
}
