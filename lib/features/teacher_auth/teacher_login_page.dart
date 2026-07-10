import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';

/// M0.5 teacher sign-in: swaps the app's default anonymous session for a
/// real teacher account so approve/reject on generated lessons is authorized
/// (see the teacher-role check in supabase/functions/generate-lesson).
/// Email/password against a pre-seeded teacher account — not a general
/// sign-up flow.
class TeacherLoginPage extends ConsumerStatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  ConsumerState<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends ConsumerState<TeacherLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(supabaseClientProvider).auth.signInWithPassword(
            email: email,
            password: password,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not sign in: $e');
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
        title: const Text('Teacher sign-in'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign in with a teacher account to approve or reject '
                'AI-generated lessons.',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('teacher_email_field'),
                controller: _emailController,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('teacher_password_field'),
                controller: _passwordController,
                enabled: !_submitting,
                obscureText: true,
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.hairline),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: AppTheme.incorrect, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('teacher_signin_button'),
                onPressed: _submitting ? null : _signIn,
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
                    : const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
