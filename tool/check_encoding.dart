// Encoding gate.
//
// Text in this repository is Vietnamese and the development machine is
// Windows, which is the exact combination that produces silent corruption:
// a tool writes UTF-8 with a BOM, or reads UTF-8 as CP1252 and writes it back,
// turning one Vietnamese letter into three Latin ones. Neither breaks a build.
// Both reach a user. (No worked example here on purpose — this gate would
// flag its own comment.)
//
// Checks every text source for:
//   1. a UTF-8 byte order mark
//   2. bytes that are not valid UTF-8 at all
//   3. mojibake — UTF-8 that was decoded as Latin-1/CP1252 and re-encoded
//
// Run from the repository root or from app/:
//   dart run tool/check_encoding.dart
//
// No ignore marker: there is no legitimate reason for any of the three.

import 'dart:convert';
import 'dart:io';

const checkedExtensions = <String>{
  '.dart',
  '.arb',
  '.json',
  '.yaml',
  '.yml',
  '.md',
  '.txt',
  '.sql',
  '.kt',
  '.kts',
  '.swift',
  '.xml',
  '.properties',
};

/// Third-party files that must stay byte-identical to upstream so anyone can
/// diff them against the original. Google ships the Baloo 2 OFL with a BOM;
/// stripping it would not change a character of the licence, but a vendored
/// licence you have edited is a licence you can no longer prove is unmodified.
const vendoredPaths = <String>{
  'app/assets/fonts/OFL-Baloo2.txt',
  'app/assets/fonts/OFL-BeVietnamPro.txt',
};

/// Directory names that hold generated output, dependencies or tool state.
const skippedSegments = <String>{
  '.git',
  '.dart_tool',
  '.fvm',
  '.gradle',
  '.idea',
  'build',
  'generated',
  'node_modules',
  'Pods',
};

class Violation {
  Violation(this.path, this.rule, this.detail, {this.lineNumber});

  final String path;
  final String rule;
  final String detail;
  final int? lineNumber;
}

Directory repoRoot() {
  final scriptPath = Platform.script.toFilePath().replaceAll(r'\', '/');
  final toolDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
  return Directory(toolDir.substring(0, toolDir.lastIndexOf('/')));
}

/// True when [text] contains a sequence that only arises from decoding UTF-8
/// bytes as a single-byte codepage and re-encoding them.
///
/// The signatures below are deliberately narrow. `Ã`, `Â` and `â` do occur in
/// real text, so a bare match on those would fire on ordinary Vietnamese and
/// the gate would be turned off within a week. What never occurs in real text
/// is one of them immediately followed by a C1 control or a Latin-1 supplement
/// character — that pairing is the fingerprint of double encoding.
int? mojibakeLine(List<String> lines) {
  bool isTrailingByteGlyph(int rune) =>
      // U+0080-U+00BF: what the low half of a UTF-8 continuation byte turns
      // into once it has been mangled.
      (rune >= 0x80 && rune <= 0xBF) ||
      // The CP1252 glyphs that occupy the same byte range.
      rune == 0x20AC || // €
      rune == 0x201A || // ‚
      rune == 0x0192 || // ƒ
      rune == 0x201E || // „
      rune == 0x2026 || // …
      rune == 0x2020 || // †
      rune == 0x2021 || // ‡
      rune == 0x02C6 || // ˆ
      rune == 0x2030 || // ‰
      rune == 0x0160 || // Š
      rune == 0x2039 || // ‹
      rune == 0x0152 || // Œ
      rune == 0x017D || // Ž
      rune == 0x2018 || // ‘
      rune == 0x2019 || // ’
      rune == 0x201C || // “
      rune == 0x201D || // ”
      rune == 0x2022 || // •
      rune == 0x2013 || // –
      rune == 0x2014 || // —
      rune == 0x02DC || // ˜
      rune == 0x2122 || // ™
      rune == 0x0161 || // š
      rune == 0x203A || // ›
      rune == 0x0153 || // œ
      rune == 0x017E || // ž
      rune == 0x0178; // Ÿ

  // Lead glyphs a mangled UTF-8 first byte turns into.
  const leadGlyphs = <int>{
    0xC2, // Â
    0xC3, // Ã
    0xE1, // á
    0xE2, // â
    0xE3, // ã
    0xC6, // Æ
    0xC4, // Ä
    0xC5, // Å
  };

  for (var i = 0; i < lines.length; i++) {
    final runes = lines[i].runes.toList();
    for (var r = 0; r < runes.length - 1; r++) {
      if (leadGlyphs.contains(runes[r]) && isTrailingByteGlyph(runes[r + 1])) {
        return i + 1;
      }
    }
  }
  return null;
}

void main(List<String> args) {
  final root = repoRoot().path.replaceAll(r'\', '/');
  final violations = <Violation>[];
  var scanned = 0;

  final entries = Directory(root).listSync(recursive: true).whereType<File>();

  for (final file in entries) {
    final path = file.path.replaceAll(r'\', '/').replaceFirst('$root/', '');
    if (vendoredPaths.contains(path)) continue;
    final segments = path.split('/');
    if (segments.any(skippedSegments.contains)) continue;

    final dot = path.lastIndexOf('.');
    if (dot < 0) continue;
    if (!checkedExtensions.contains(path.substring(dot))) continue;

    scanned++;
    final bytes = file.readAsBytesSync();

    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      violations.add(
        Violation(path, 'utf8-bom', 'file starts with a UTF-8 byte order mark'),
      );
      continue;
    }

    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException catch (e) {
      violations.add(
        Violation(path, 'invalid-utf8', 'not valid UTF-8: ${e.message}'),
      );
      continue;
    }

    final line = mojibakeLine(const LineSplitter().convert(text));
    if (line != null) {
      violations.add(
        Violation(
          path,
          'mojibake',
          'looks like UTF-8 decoded as CP1252 and written back',
          lineNumber: line,
        ),
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('check_encoding: sạch — $scanned file, UTF-8 không BOM.');
    exit(0);
  }

  stderr.writeln('check_encoding: ${violations.length} file hỏng mã hoá\n');
  for (final v in violations) {
    final where = v.lineNumber == null ? v.path : '${v.path}:${v.lineNumber}';
    stderr.writeln('$where  [${v.rule}]');
    stderr.writeln('    ${v.detail}\n');
  }
  stderr.writeln(
    'Ghi file bằng UTF-8 không BOM. Trên Windows, tránh Set-Content và\n'
    "Out-File cho file mã nguồn — chúng thêm BOM và làm hỏng dấu tiếng Việt.",
  );
  exit(1);
}
