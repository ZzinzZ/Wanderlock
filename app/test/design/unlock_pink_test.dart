import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/design/tokens/tokens.dart';

/// Section 10 of the art direction bans `#FF48A0` outside the three-second
/// unlock moment, and F5's Definition of Done asks for it to be checked rather
/// than trusted.
///
/// A colour restricted by convention lasts until the first screen that wants a
/// highlight. This makes the convention fail a build instead.
void main() {
  /// Files permitted to read [AppColors.unlockMoment].
  ///
  /// The token's own definition, and the widget that owns the moment. Adding
  /// to this list is a decision about the art direction, not a fix for a
  /// failing test.
  const allowed = <String>{
    'lib/design/tokens/app_colors.dart',
    'lib/features/unlock/presentation/unlock_moment.dart',
  };

  /// Reads of the colour, and not of `AppMotion.unlockMoment`.
  ///
  /// The two tokens share a name — one is the pink, the other is the three
  /// seconds — and the duration is meant to be referenced freely. Matching the
  /// bare word flagged `app_motion.dart` and would have flagged every future
  /// screen that merely animates for the right length of time.
  final colourRead = RegExp(r'(\w+)\.unlockMoment');

  test('pink appears only in the unlock moment', () {
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final path = file.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;

      final reads = colourRead
          .allMatches(file.readAsStringSync())
          .map((match) => match.group(1))
          .where((receiver) => receiver != 'AppMotion');
      if (reads.isNotEmpty) offenders.add(path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the unlock pink is reserved for the three-second moment; '
          'these files reach for it: ${offenders.join(', ')}',
    );
  });

  test('the token is the pink the art direction names', () {
    // Guards the other direction: the list above is worthless if the token it
    // protects has quietly become a different colour.
    expect(AppColors.light.unlockMoment.toARGB32(), 0xFFFF48A0);
    expect(AppColors.dark.unlockMoment.toARGB32(), 0xFFFF48A0);
  });
}
