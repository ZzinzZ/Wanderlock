// Architecture gate.
//
// Enforces the dependency rules in docs/12-engineering-guide.md section 2.
// Those rules are the product thesis written as code: every lens reads
// `visit_state` from `unlock`, no lens knows another lens exists, and only
// `unlock` writes unlock state. Left to review alone, that erodes in a month.
//
// Run from the repository root or from app/:
//   dart run tool/check_architecture.dart
//
// There is deliberately **no ignore marker**. The design-token gate has one
// because a stubborn literal is a local nuisance; a cross-feature import is a
// hole in the architecture. If a rule here is in the way, the design needs
// changing, not silencing.

import 'dart:io';

/// The only feature every other feature may depend on. It owns `visit_state`
/// and must never depend on a lens in return.
const sharedFoundationFeature = 'unlock';

/// Layers a `domain/` file may never reach into.
const layersForbiddenInDomain = <String>['data', 'application', 'presentation'];

const generatedSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.config.dart',
];

/// Generated localisations are not hand-written architecture.
const skippedPathPrefixes = <String>['app/lib/l10n/generated/'];

final _importPattern = RegExp('''^\\s*import\\s+['"]([^'"]+)['"]''');

class Violation {
  Violation(this.path, this.lineNumber, this.rule, this.import, this.hint);

  final String path;
  final int lineNumber;
  final String rule;
  final String import;
  final String hint;
}

/// Where a file or an import sits in the architecture.
class Location {
  Location({this.feature, this.layer, this.isDesign = false});

  final String? feature;
  final String? layer;
  final bool isDesign;
}

Directory repoRoot() {
  final scriptPath = Platform.script.toFilePath().replaceAll(r'\', '/');
  final toolDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
  return Directory(toolDir.substring(0, toolDir.lastIndexOf('/')));
}

/// Classifies a repo-relative source path such as
/// `app/lib/features/fog/data/fog_repository.dart`.
Location locate(String path) {
  const featuresRoot = 'app/lib/features/';
  if (path.startsWith(featuresRoot)) {
    final rest = path.substring(featuresRoot.length).split('/');
    return Location(
      feature: rest.isNotEmpty ? rest[0] : null,
      layer: rest.length > 1 ? rest[1] : null,
    );
  }
  if (path.startsWith('app/lib/design/')) return Location(isDesign: true);
  return Location();
}

/// Classifies an import URI such as
/// `package:wanderlock/features/story/domain/story.dart`.
Location locateImport(String uri) {
  const featuresRoot = 'package:wanderlock/features/';
  if (uri.startsWith(featuresRoot)) {
    final rest = uri.substring(featuresRoot.length).split('/');
    return Location(
      feature: rest.isNotEmpty ? rest[0] : null,
      layer: rest.length > 1 ? rest[1] : null,
    );
  }
  return Location();
}

bool isPureDart(String uri) => uri.startsWith('dart:');

bool isOwnPackage(String uri) => uri.startsWith('package:wanderlock/');

void checkImport(String path, int line, String uri, List<Violation> out) {
  final self = locate(path);
  final target = locateImport(uri);

  // Rule 1 — domain stays pure.
  if (self.feature != null && self.layer == 'domain') {
    if (!isPureDart(uri) && !isOwnPackage(uri)) {
      out.add(
        Violation(
          path,
          line,
          'domain-imports-external',
          uri,
          'domain must depend on plain Dart only',
        ),
      );
    } else if (target.layer != null &&
        layersForbiddenInDomain.contains(target.layer)) {
      out.add(
        Violation(
          path,
          line,
          'domain-imports-outer-layer',
          uri,
          'domain must not know about ${target.layer}',
        ),
      );
    }
  }

  // Rule 2 — presentation goes through application.
  if (self.layer == 'presentation' && target.layer == 'data') {
    out.add(
      Violation(
        path,
        line,
        'presentation-imports-data',
        uri,
        'call it through application/, never the repository directly',
      ),
    );
  }

  // Rule 3 and 4 — features do not know each other; unlock knows no one.
  if (self.feature != null &&
      target.feature != null &&
      target.feature != self.feature) {
    final isAllowed =
        target.feature == sharedFoundationFeature &&
        self.feature != sharedFoundationFeature;
    if (!isAllowed) {
      final rule = self.feature == sharedFoundationFeature
          ? 'unlock-depends-on-feature'
          : 'cross-feature-import';
      out.add(
        Violation(
          path,
          line,
          rule,
          uri,
          self.feature == sharedFoundationFeature
              ? 'unlock is the foundation and must depend on no lens'
              : 'lenses share state through unlock, never through each other',
        ),
      );
    }
  }

  // Rule 5 — the design system knows nothing about features.
  if (self.isDesign && target.feature != null) {
    out.add(
      Violation(
        path,
        line,
        'design-imports-feature',
        uri,
        'design/ is shared UI and must not depend on a feature',
      ),
    );
  }
}

void main(List<String> args) {
  final root = repoRoot().path.replaceAll(r'\', '/');
  final libDir = Directory('$root/app/lib');
  if (!libDir.existsSync()) {
    stdout.writeln('check_architecture: bỏ qua — chưa có app/lib.');
    exit(0);
  }

  final violations = <Violation>[];
  var scanned = 0;

  final files =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/').replaceFirst('$root/', '');
    if (generatedSuffixes.any(path.endsWith)) continue;
    if (skippedPathPrefixes.any(path.startsWith)) continue;

    scanned++;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = _importPattern.firstMatch(lines[i]);
      if (match == null) continue;
      checkImport(path, i + 1, match.group(1)!, violations);
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'check_architecture: sạch — $scanned file, 0 vi phạm phụ thuộc.',
    );
    exit(0);
  }

  stderr.writeln('check_architecture: ${violations.length} vi phạm\n');
  for (final v in violations) {
    stderr.writeln('${v.path}:${v.lineNumber}  [${v.rule}]');
    stderr.writeln('    import ${v.import}');
    stderr.writeln('    → ${v.hint}\n');
  }
  stderr.writeln(
    'Luật phụ thuộc ở docs/12-engineering-guide.md §2.\n'
    'Cổng này không có lối thoát: nếu vướng thì sửa thiết kế, không tắt luật.',
  );
  exit(1);
}
