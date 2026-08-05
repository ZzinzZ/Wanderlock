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

  /// Vector tiles, in the OpenMapTiles schema the map style targets.
  ///
  /// Defaults to OpenFreeMap: free, no API key, no quota. Overridable so a
  /// self-hosted or paid provider can be swapped in without a code change —
  /// including the offline `.pmtiles` route that F3's tile-cache item will
  /// need.
  static const String mapTilesUrl = String.fromEnvironment(
    'MAP_TILES_URL',
    defaultValue: 'https://tiles.openfreemap.org/planet',
  );

  /// Label fonts. Must serve the font named in the style, or labels vanish
  /// silently rather than erroring.
  static const String mapGlyphsUrl = String.fromEnvironment(
    'MAP_GLYPHS_URL',
    defaultValue: 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
  );
}
