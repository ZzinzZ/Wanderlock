import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:wanderlock/features/quest/domain/quest_route_definition.dart';

/// Reads the authored routes that ship inside the binary.
///
/// Bundled rather than fetched for the same reason the checkpoints are: the
/// quest lens has to draw something on a fresh install with no network. A
/// route is a handful of ids, so there is nothing here worth a round trip.
///
/// The copy under `app/assets/content/` is kept identical to the root
/// `content/quest-routes.json` by `test/content/bundled_content_test.dart` —
/// Flutter cannot bundle an asset from outside the package directory, so a
/// copy is the only option and a test is what stops it drifting.
class QuestRouteBundledSource {
  const QuestRouteBundledSource({this.assetPath = defaultAssetPath, this.load});

  static const String defaultAssetPath = 'assets/content/quest-routes.json';

  final String assetPath;

  /// Overridable so the parser can be tested without a Flutter asset bundle.
  final Future<String> Function(String assetPath)? load;

  Future<List<QuestRouteDefinition>> readAll() async {
    final raw = await (load ?? rootBundle.loadString)(assetPath);
    return parse(raw);
  }

  /// Turns the authored JSON into definitions.
  ///
  /// A route with no steps is dropped: an empty route would render as a card
  /// claiming 0/0 progress, which reads as a bug rather than as missing
  /// content. A step whose `checkpointId` is missing or blank is skipped for
  /// the same reason — it could only ever be a stop that can never be reached.
  static List<QuestRouteDefinition> parse(String raw) {
    final root = jsonDecode(raw) as Map<String, Object?>;
    final entries = (root['routes'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();

    final routes = <QuestRouteDefinition>[];
    for (final entry in entries) {
      final steps = (entry['steps'] as List<Object?>? ?? const [])
          .cast<Map<String, Object?>>();

      final ids = <String>[];
      for (final step in steps) {
        final id = step['checkpointId'] as String?;
        if (id == null || id.isEmpty) continue;
        ids.add(id);
      }
      final categories = (entry['categories'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList();
      if (ids.isEmpty && categories.isEmpty) continue;

      routes.add(
        QuestRouteDefinition(
          id: entry['id']! as String,
          name: entry['name']! as String,
          summary: entry['summary'] as String? ?? '',
          checkpointIds: ids,
          kind: QuestKind.parse(entry['kind'] as String?),
          categories: categories,
        ),
      );
    }
    return routes;
  }
}
