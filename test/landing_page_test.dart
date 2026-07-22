import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/db/app_database.dart';
import 'package:kids_lang/features/landing/landing_page.dart';

/// In-memory fake -- avoids a real drift/sqlite3 backend in widget tests
/// (see consent_gate_test.dart for the same rationale).
class _FakeLandingStore implements LandingStore {
  final Map<String, bool> seenByLearner = {};

  @override
  Future<void> setHasSeenLanding(String learnerId, bool seen) async {
    seenByLearner[learnerId] = seen;
  }
}

Future<_FakeLandingStore> _pump(WidgetTester tester, {bool consented = true}) async {
  final store = _FakeLandingStore();
  final router = GoRouter(
    initialLocation: '/landing',
    routes: [
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home!')),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(body: Text('Register!')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login!')),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const Scaffold(body: Text('Consent!')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        landingStoreProvider.overrideWithValue(store),
        learnerIdProvider.overrideWithValue('test-learner'),
        consentGivenProvider.overrideWith((ref) => Stream.value(consented)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  // Let consentGivenProvider's stream emit its first value before any
  // interaction -- otherwise ref.read sees the loading state (null -> false)
  // and every test would appear to route through the consent gate.
  await tester.pump();
  return store;
}

void main() {
  testWidgets('continue without an account marks landing seen and goes home',
      (tester) async {
    final store = await _pump(tester);

    await tester.tap(find.byKey(const Key('landing_guest_button')));
    await tester.pump();
    await tester.pump();

    expect(store.seenByLearner['test-learner'], isTrue);
    expect(find.text('Home!'), findsOneWidget);
  });

  testWidgets('sign up goes straight to /register when consent is already given',
      (tester) async {
    await _pump(tester, consented: true);

    await tester.tap(find.byKey(const Key('landing_sign_up_button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Register!'), findsOneWidget);
  });

  testWidgets(
      'sign up routes through the consent gate first when not yet consented '
      '(registration collects a real email from the learner)', (tester) async {
    await _pump(tester, consented: false);

    await tester.tap(find.byKey(const Key('landing_sign_up_button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Consent!'), findsOneWidget);
    expect(find.text('Register!'), findsNothing);
  });

  testWidgets('log in goes to /login', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('landing_log_in_button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Login!'), findsOneWidget);
  });
}
