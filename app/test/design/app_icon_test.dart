import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/design/widgets/app_icon.dart';

/// Guards the icon layer.
///
/// Section 10 of the art direction bans icons taken from a generic line set,
/// which is what Flutter's bundled Material icons are. This does not forbid
/// them outright — three controls have no equivalent in the 3dicons set at
/// all — but it pins the number, so the exception cannot quietly become the
/// rule.
void main() {
  final assets = Directory('assets/icons');
  final lib = Directory('lib');

  List<File> dartFiles() => lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  group('bundled assets', () {
    test('every icon the code names exists as a file', () {
      final missing = [
        for (final name in AppIcons.all)
          if (!File('${assets.path}/$name.png').existsSync()) name,
      ];

      expect(
        missing,
        isEmpty,
        reason:
            'named in ClayIcons but not bundled: ${missing.join(', ')} — '
            'copy them from content/icons/3dicons-color/',
      );
    });

    test('nothing is bundled that no code names', () {
      // Everything under assets/ ships inside the binary whether it is drawn
      // or not. An icon that stopped being used is dead weight in the download.
      final named = AppIcons.all.toSet();
      final orphans = assets
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
          .where((name) => !named.contains(name))
          .toList();

      expect(
        orphans,
        isEmpty,
        reason: 'bundled but unused: ${orphans.join(', ')}',
      );
    });

    test('each bundled file really is a PNG', () {
      for (final name in AppIcons.all) {
        final bytes = File(
          '${assets.path}/$name.png',
        ).readAsBytesSync().take(4).toList();
        // A truncated or HTML-error-page download is the failure this catches:
        // it would still have the right filename and still not draw.
        expect(bytes, [
          0x89,
          0x50,
          0x4E,
          0x47,
        ], reason: '$name.png does not start with the PNG signature');
      }
    });

    test('every named constant resolves to a bundled file', () {
      // Walks the constants rather than the deduplicated set, so a constant
      // that was added and never bundled is caught even when a sibling alias
      // already put its file there.
      final missing = [
        for (final name in AppIcons.named)
          if (!File('${assets.path}/$name.png').existsSync()) name,
      ];

      expect(missing, isEmpty, reason: 'not bundled: ${missing.join(', ')}');
    });
  });

  group('Material icon budget', () {
    /// Every remaining `Icons.` use, with the reason it survives.
    ///
    /// Raising this number is a decision about the art direction. The three
    /// here are controls the 120-icon set simply does not contain — close,
    /// refresh, and download — and each is marked at its line with a
    /// `clay-icon-gap` comment. See content/icon-licenses.md.
    const budget = 3;

    test('no more Material icons than the ones we could not replace', () {
      final uses = <String>[];
      for (final file in dartFiles()) {
        if (file.path.contains('generated')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'\bIcons\.[a-z_]').hasMatch(lines[i])) {
            uses.add('${file.path}:${i + 1}');
          }
        }
      }

      expect(
        uses,
        hasLength(budget),
        reason:
            'the art direction bans generic line icons; if a 3D icon now '
            'exists for one of these, use it — if a new gap is genuinely '
            'unavoidable, raise the budget deliberately: ${uses.join(', ')}',
      );
    });

    test('every surviving Material icon is marked as a known gap', () {
      final unmarked = <String>[];
      for (final file in dartFiles()) {
        if (file.path.contains('generated')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!RegExp(r'\bIcons\.[a-z_]').hasMatch(lines[i])) continue;
          // The marker may sit on the line itself or anywhere in the comment
          // block directly above it. Checking only one line up rejected a
          // two-line explanation, which is a silly reason to fail a build and
          // a good reason to write shorter reasons — but the reason is worth
          // more than the brevity.
          var marked = lines[i].contains('clay-icon-gap');
          for (var j = i - 1; j >= 0 && !marked; j--) {
            final above = lines[j].trimLeft();
            if (!above.startsWith('//')) break;
            marked = above.contains('clay-icon-gap');
          }
          if (!marked) unmarked.add('${file.path}:${i + 1}');
        }
      }

      expect(
        unmarked,
        isEmpty,
        reason:
            'add a `clay-icon-gap: <why>` comment, or use an AppIcon: '
            '${unmarked.join(', ')}',
      );
    });
  });
}
