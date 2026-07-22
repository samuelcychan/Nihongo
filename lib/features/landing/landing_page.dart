import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';

/// First-run entry screen: sign up, log in, or continue without an account.
/// Shown once per device (gated on [hasSeenLandingProvider], see
/// app_router.dart's '/' route) -- picking any of the three paths marks it
/// seen and moves on to the learner home.
class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  Future<void> _continueAsGuest(BuildContext context, WidgetRef ref) async {
    await ref
        .read(landingStoreProvider)
        .setHasSeenLanding(ref.read(learnerIdProvider), true);
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warms up consentGivenProvider (StreamProvider) so its first real value
    // has landed by the time Sign Up is tapped -- consentGivenProvider is
    // otherwise only ever ref.read imperatively (see requireConsent/
    // playLesson in app_router.dart), so without a watch somewhere in the
    // tree first, an immediate tap on a cold launch can race the stream's
    // first emission and see the not-yet-loaded (null -> false) value.
    ref.watch(consentGivenProvider);
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7C2),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppTheme.chunky(const Color(0xFFF2D49E), y: 6),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🦊', style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'おはよう！',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn Japanese words the fun way — tap, drag, listen, and speak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: AppTheme.inkSoft, height: 1.4),
              ),
              const Spacer(flex: 2),
              _ChunkyButton(
                key: const Key('landing_sign_up_button'),
                label: 'Sign Up',
                color: AppTheme.grass,
                shadow: AppTheme.grassDeep,
                // Registering collects a real email from the learner, so it
                // sits behind the same parental-consent gate as first play.
                onTap: () =>
                    requireConsent(context, ref, forwardRoute: '/register'),
              ),
              const SizedBox(height: 12),
              _ChunkyButton(
                key: const Key('landing_log_in_button'),
                label: 'Log In',
                color: Colors.white,
                textColor: AppTheme.ink,
                shadow: AppTheme.hairline,
                onTap: () => context.push('/login'),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  key: const Key('landing_guest_button'),
                  onPressed: () => _continueAsGuest(context, ref),
                  child: const Text(
                    'Continue without an account',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppTheme.inkFaint),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChunkyButton extends StatelessWidget {
  const _ChunkyButton({
    super.key,
    required this.label,
    required this.color,
    required this.shadow,
    required this.onTap,
    this.textColor = Colors.white,
  });

  final String label;
  final Color color;
  final Color shadow;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          onTap: onTap,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              border: color == Colors.white
                  ? Border.all(color: AppTheme.hairline, width: 2)
                  : null,
              boxShadow: AppTheme.chunky(shadow),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: textColor, fontSize: 20)),
          ),
        ),
      ),
    );
  }
}
