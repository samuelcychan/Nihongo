import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Build-time configuration, injected via `--dart-define` so secrets never live
/// in source control. Run with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Initializes Supabase and ensures an (anonymous) session exists.
///
/// Anonymous auth is the slice's stand-in for the eventual parental-consent /
/// role-based sign-in; it gives each device a stable `auth.uid()` so RLS on
/// learner_item_states works without collecting any child data.
Future<SupabaseClient> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // The slice is provisioned with a legacy anon key; publishableKey is the
    // newer name for the same client-safe key and can replace this later.
    // ignore: deprecated_member_use
    anonKey: Env.supabaseAnonKey,
  );
  final client = Supabase.instance.client;
  if (client.auth.currentSession == null) {
    // M3 NFR-perf: first-run cold start must not hold the splash hostage on a
    // slow network -- bound the sign-in wait and boot anyway on timeout.
    // learnerIdProvider is auth-reactive, so if the sign-in lands later (or on
    // the next launch) the app picks the real uid up without a restart.
    try {
      await client.auth
          .signInAnonymously()
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Anonymous sign-in deferred (will retry next launch): $e');
    }
  }
  return client;
}
