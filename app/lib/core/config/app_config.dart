/// Build-time configuration.
///
/// Supplied with `--dart-define`, never read from a file at runtime and never
/// committed. See `.env.example` for the full list.
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// ```
///
/// The anon key is not a secret. It ships inside the app, so anyone can read
/// it out of the binary; what protects the data is row level security, not the
/// key. Treating it as a secret would give a false sense of safety and tempt
/// someone to "fix" it by moving policy decisions into the client.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// True when both values were provided at build time.
  ///
  /// Checked rather than assumed so a misconfigured build fails with a clear
  /// message instead of an opaque network error on the first query.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
