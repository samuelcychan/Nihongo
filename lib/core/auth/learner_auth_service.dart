/// Learner account registration/login (landing page). Narrow interface --
/// not the full [SupabaseClient] -- so widget tests can fake it without a
/// real backend, matching ConsentStore/ResultsSink's existing pattern.
library;

abstract class LearnerAuthService {
  /// Registers a new account, upgrading the current anonymous session in
  /// place so its `auth.uid()` -- and every row keyed to it, both local
  /// (drift) and already-synced (Supabase) -- carries over unchanged. Falls
  /// back to creating a brand-new account if the current session isn't
  /// upgradable (e.g. already a non-anonymous session).
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs into an existing account. This switches the session's `auth.uid()`
  /// away from the current device's anonymous id -- call
  /// [ResultsSink.pullRemoteProgress] afterward to restore that account's
  /// history onto this device.
  Future<void> logIn({required String email, required String password});
}
