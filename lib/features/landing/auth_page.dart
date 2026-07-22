import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';

enum AuthMode { register, login }

/// Learner registration/login, reached from the landing page. Register goes
/// through [LearnerAuthService.register] (upgrades the current anonymous
/// session in place, so local + already-synced progress carries over
/// unchanged); log in switches to an existing account and then restores that
/// account's history onto this device via [ResultsSink.pullRemoteProgress].
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, required this.mode});

  final AuthMode mode;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool get _isRegister => widget.mode == AuthMode.register;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in both email and password.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = ref.read(learnerAuthServiceProvider);
      if (_isRegister) {
        await auth.register(
          email: email,
          password: password,
          displayName: _nameController.text.trim(),
        );
      } else {
        await auth.logIn(email: email, password: password);
        // Restore this account's history onto this device -- without this a
        // returning user on a fresh install would see zero progress.
        await ref
            .read(resultsRepositoryProvider)
            .pullRemoteProgress(ref.read(learnerIdProvider));
      }
      await ref
          .read(landingStoreProvider)
          .setHasSeenLanding(ref.read(learnerIdProvider), true);
      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: Text(_isRegister ? 'Sign Up' : 'Log In'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isRegister
                    ? 'Create an account so your progress is saved and can '
                        'follow you to a new device.'
                    : 'Log in to bring your progress back.',
                style: const TextStyle(color: AppTheme.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_isRegister) ...[
                TextField(
                  key: const Key('auth_name_field'),
                  controller: _nameController,
                  enabled: !_submitting,
                  decoration: _fieldDecoration('Name (optional)'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const Key('auth_email_field'),
                controller: _emailController,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('auth_password_field'),
                controller: _passwordController,
                enabled: !_submitting,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: _fieldDecoration('Password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: AppTheme.incorrect, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('auth_submit_button'),
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(AppTheme.minTapTarget * 0.6),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isRegister ? 'Sign Up' : 'Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.hairline),
        ),
      );
}
