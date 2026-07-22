import 'package:supabase_flutter/supabase_flutter.dart';

import 'learner_auth_service.dart';

class SupabaseLearnerAuthService implements LearnerAuthService {
  SupabaseLearnerAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final current = _client.auth.currentUser;
    final data = displayName == null || displayName.isEmpty
        ? null
        : {'display_name': displayName};

    if (current != null && current.isAnonymous) {
      // Upgrade the anonymous session in place -- same auth.uid(), so every
      // local (drift) and already-synced row this device has stays attached
      // to the account with zero migration.
      await _client.auth.updateUser(
        UserAttributes(email: email, password: password, data: data),
      );
    } else {
      // No anonymous session to upgrade (unexpected state, e.g. a teacher
      // account was active) -- fall back to a fresh account.
      await _client.auth.signUp(email: email, password: password, data: data);
    }

    await _upsertProfile(displayName: displayName);
  }

  @override
  Future<void> logIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> _upsertProfile({String? displayName}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').upsert({
      'id': user.id,
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
    });
  }
}
