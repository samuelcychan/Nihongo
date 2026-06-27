import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/supabase/app_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    await initSupabase();
  } else {
    // Allows the app to boot for UI work without backend credentials.
    // Provide them via --dart-define for a full run (see app_supabase.dart).
    debugPrint('WARNING: SUPABASE_URL / SUPABASE_ANON_KEY not set — '
        'running without backend. Content load and sync will fail.');
  }

  runApp(const ProviderScope(child: KidsLangApp()));
}
