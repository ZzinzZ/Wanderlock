import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/app/router.dart';
import 'package:wanderlock/app/theme.dart';
import 'package:wanderlock/app/theme_mode_controller.dart';
import 'package:wanderlock/l10n/generated/app_localizations.dart';

/// Bundled font licences, surfaced in the standard Flutter licence page.
/// The SIL Open Font License requires the licence to travel with the font.
const _fontLicenses = <String, String>{
  'Be Vietnam Pro': 'assets/fonts/OFL-BeVietnamPro.txt',
  'Baloo 2': 'assets/fonts/OFL-Baloo2.txt',
};

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  runApp(const ProviderScope(child: WanderlockApp()));
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in _fontLicenses.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}

class WanderlockApp extends ConsumerStatefulWidget {
  const WanderlockApp({super.key});

  @override
  ConsumerState<WanderlockApp> createState() => _WanderlockAppState();
}

class _WanderlockAppState extends ConsumerState<WanderlockApp> {
  // Built once: rebuilding a GoRouter on every theme change would reset the
  // navigation stack.
  late final _router = buildAppRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: _resolveLocale,
      routerConfig: _router,
    );
  }

  /// Honour the device language when we support it, otherwise fall back to
  /// Vietnamese rather than English: the pilot is District 1, Ho Chi Minh City.
  Locale? _resolveLocale(
    List<Locale>? deviceLocales,
    Iterable<Locale> supported,
  ) {
    for (final locale in deviceLocales ?? const <Locale>[]) {
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) return candidate;
      }
    }
    return const Locale('vi');
  }
}
