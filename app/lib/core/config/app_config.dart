/// Build-time configuration.
///
/// Supplied with `--dart-define`, never read from a file at runtime and never
/// committed. See `.env.example` for the full list.
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// ```
///
/// The publishable key is not a secret. It ships inside the app, so anyone can
/// read it out of the binary; what protects the data is row level security,
/// not the key. Treating it as a secret would give a false sense of safety and
/// tempt someone to "fix" it by moving policy decisions into the client.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase renamed this from "anon key"; the old name is deprecated and due
  /// for removal. Local Supabase prints both — this is the `sb_publishable_…`
  /// one, not the legacy JWT.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// True when both values were provided at build time.
  ///
  /// Checked rather than assumed so a misconfigured build runs from cache with
  /// a clear log line instead of failing with an opaque network error on the
  /// first query.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
