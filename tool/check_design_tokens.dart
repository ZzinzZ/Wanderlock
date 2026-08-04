// Design-token gate.
//
// Enforces rule 3 of CLAUDE.md and section 6 of docs/12-engineering-guide.md:
// colors, corner radii, font sizes and animation durations must come from
// `design/tokens/`, never from a literal written at the point of use.
//
// A lint rule cannot express "except inside the token files themselves", so
// this is a plain source scan instead of a custom_lint plugin: no extra
// dependency, no plugin lifecycle, and the allow-list stays readable.
//
// Run from the repository root:
//   dart run tool/check_design_tokens.dart
//
// Escape hatch — put this on the offending line or the line above it:
//   // design-token-ignore: <why this literal is unavoidable>
// A bare marker with no reason does not count.

import 'dart:io';

/// Paths (relative to repo root, POSIX separators) allowed to hold raw
/// design values. These files ARE the source of truth.
const allowedPathPrefixes = <String>['app/lib/design/tokens/'];

/// Generated sources are not hand-written, so they are not our problem.
const generatedSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.config.dart',
];

class Rule {
  const Rule(this.id, this.pattern, this.hint);

  final String id;
  final RegExp pattern;
  final String hint;
}

final rules = <Rule>[
  Rule(
    'hardcoded-color',
    RegExp(r'Color\(\s*0x|Color\.fromARGB\(|Color\.fromRGBO\(|\bColors\.'),
    'dùng AppColors trong design/tokens/',
  ),
  Rule(
    'hardcoded-radius',
    RegExp(r'(BorderRadius|Radius)\.(circular|all)\(\s*(const\s+)?[0-9]'),
    'dùng AppRadius trong design/tokens/',
  ),
  Rule(
    'hardcoded-font-size',
    RegExp(r'fontSize\s*:\s*[0-9]'),
    'dùng AppTypography trong design/tokens/',
  ),
  Rule(
    'hardcoded-duration',
    RegExp(r'Duration\(\s*(milliseconds|seconds)\s*:\s*[0-9]'),
    'dùng AppMotion trong design/tokens/',
  ),
];

final ignoreMarker = RegExp(r'//\s*design-token-ignore:\s*\S');

class Violation {
  Violation(this.path, this.lineNumber, this.rule, this.source);

  final String path;
  final int lineNumber;
  final Rule rule;
  final String source;
}

/// Repo root derived from this script's own location (`<root>/tool/…`), so the
/// gate behaves the same whether it is run from the root or from `app/`.
Directory repoRoot() {
  final scriptPath = Platform.script.toFilePath().replaceAll(r'\', '/');
  final toolDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
  return Directory(toolDir.substring(0, toolDir.lastIndexOf('/')));
}

void main(List<String> args) {
  final root = Directory('${repoRoot().path}/app/lib');
  if (!root.existsSync()) {
    stdout.writeln(
      'check_design_tokens: bỏ qua — chưa có app/lib (app chưa được tạo).',
    );
    exit(0);
  }

  final violations = <Violation>[];
  var scannedFiles = 0;

  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final rootPrefix = '${repoRoot().path.replaceAll(r'\', '/')}/';

  for (final file in files) {
    // Report repo-relative paths so the output is clickable in an editor.
    final path = file.path.replaceAll(r'\', '/').replaceFirst(rootPrefix, '');
    if (generatedSuffixes.any(path.endsWith)) continue;
    if (allowedPathPrefixes.any(path.startsWith)) continue;

    scannedFiles++;
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      // Comments and doc comments describe, they do not render.
      if (trimmed.startsWith('//')) continue;

      final previous = i > 0 ? lines[i - 1] : '';
      if (ignoreMarker.hasMatch(line) || ignoreMarker.hasMatch(previous)) {
        continue;
      }

      for (final rule in rules) {
        if (rule.pattern.hasMatch(line)) {
          violations.add(Violation(path, i + 1, rule, trimmed));
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'check_design_tokens: sạch — $scannedFiles file, 0 giá trị viết cứng.',
    );
    exit(0);
  }

  stderr.writeln(
    'check_design_tokens: ${violations.length} giá trị thiết kế viết cứng\n',
  );
  for (final v in violations) {
    stderr.writeln('${v.path}:${v.lineNumber}  [${v.rule.id}]');
    stderr.writeln('    ${v.source}');
    stderr.writeln('    → ${v.rule.hint}\n');
  }
  stderr.writeln(
    'Giá trị thiết kế phải lấy từ design/tokens/ (CLAUDE.md, quy tắc 3).\n'
    'Nếu thật sự không tránh được, thêm: // design-token-ignore: <lý do>',
  );
  exit(1);
}
