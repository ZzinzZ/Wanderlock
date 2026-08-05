import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wanderlock/core/config/app_config.dart';

/// Connects to Supabase without ever blocking app startup.
///
/// The app is offline-first, so nothing on the launch path may wait on a
/// server. An earlier version awaited this before `runApp` and the app hung on
/// a blank screen whenever the server was slow to answer — the exact failure
/// the architecture exists to prevent, introduced on the one code path that
/// bypasses it.
///
/// Until [connect] finishes, [clientOrNull] is null and callers behave exactly
/// as they do offline. "Not connected yet" and "no network" are deliberately
/// the same case: both mean serve the cache.
class SupabaseConnection {
  const SupabaseConnection._();

  static SupabaseClient? _client;

  /// Null before the connection succeeds, and after it fails.
  static SupabaseClient? get clientOrNull => _client;

  @visibleForTesting
  static void overrideClientForTesting(SupabaseClient? client) {
    _client = client;
  }

  /// Starts the connection. Safe to leave unawaited.
  static Future<void> connect() async {
    if (!AppConfig.hasSupabase) {
      debugPrint('Supabase not configured; running from cache only.');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      final client = Supabase.instance.client;

      // Row level security grants read access to `authenticated` and nothing
      // else, so without a session the app sees no content at all. Anonymous
      // is enough: a walker should not have to make an account before the map
      // will draw. Upgrading to a real account later keeps the same user id,
      // so visit_state survives it.
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }
      _client = client;
      debugPrint('Supabase connected.');
    } on Object catch (error) {
      // Survivable by design. The cache is already serving.
      debugPrint('Supabase unavailable, running from cache: $error');
    }
  }
}
