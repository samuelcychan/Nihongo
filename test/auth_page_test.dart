import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/auth/learner_auth_service.dart';
import 'package:kids_lang/core/db/app_database.dart';
import 'package:kids_lang/data/results_repository.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/landing/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeLandingStore implements LandingStore {
  final Map<String, bool> seenByLearner = {};

  @override
  Future<void> setHasSeenLanding(String learnerId, bool seen) async {
    seenByLearner[learnerId] = seen;
  }
}

class _FakeResults implements ResultsSink {
  int pullCalls = 0;

  @override
  Future<void> recordResult({
    required String learnerId,
    required Item item,
    required bool correct,
    required int attempts,
    Duration? responseTime,
    double? pronunciationScore,
  }) async {}

  @override
  Future<int> syncPending(String learnerId) async => 0;

  @override
  Future<void> pullRemoteProgress(String learnerId) async {
    pullCalls++;
  }
}

/// Scripted fake -- registerSucceeds/logInSucceeds control whether each call
/// throws an [AuthException] (the real error type both flows catch).
class _FakeLearnerAuthService implements LearnerAuthService {
  _FakeLearnerAuthService({
    this.registerSucceeds = true,
    this.logInSucceeds = true,
  });

  final bool registerSucceeds;
  final bool logInSucceeds;
  String? lastRegisterEmail;
  String? lastRegisterName;
  String? lastLoginEmail;

  @override
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!registerSucceeds) {
      throw const AuthException('That email is already registered.');
    }
    lastRegisterEmail = email;
    lastRegisterName = displayName;
  }

  @override
  Future<void> logIn({required String email, required String password}) async {
    if (!logInSucceeds) {
      throw const AuthException('Invalid login credentials.');
    }
    lastLoginEmail = email;
  }
}

class _Harness {
  _Harness({
    required this.landingStore,
    required this.results,
    required this.auth,
  });
  final _FakeLandingStore landingStore;
  final _FakeResults results;
  final _FakeLearnerAuthService auth;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required AuthMode mode,
  bool registerSucceeds = true,
  bool logInSucceeds = true,
}) async {
  final landingStore = _FakeLandingStore();
  final results = _FakeResults();
  final auth = _FakeLearnerAuthService(
    registerSucceeds: registerSucceeds,
    logInSucceeds: logInSucceeds,
  );

  final router = GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthPage(mode: mode),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home!')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        landingStoreProvider.overrideWithValue(landingStore),
        resultsRepositoryProvider.overrideWithValue(results),
        learnerAuthServiceProvider.overrideWithValue(auth),
        learnerIdProvider.overrideWithValue('test-learner'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return _Harness(landingStore: landingStore, results: results, auth: auth);
}

void main() {
  group('register', () {
    testWidgets(
        'success registers, marks landing seen, and lands on home '
        '(no remote-progress pull -- the anonymous session upgrades in '
        'place, so nothing needs restoring)', (tester) async {
      final h = await _pump(tester, mode: AuthMode.register);

      await tester.enterText(
          find.byKey(const Key('auth_name_field')), 'Mia');
      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'mia@example.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), 'hunter22');
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();
      await tester.pump();

      expect(h.auth.lastRegisterEmail, 'mia@example.com');
      expect(h.auth.lastRegisterName, 'Mia');
      expect(h.landingStore.seenByLearner['test-learner'], isTrue);
      expect(h.results.pullCalls, 0);
      expect(find.text('Home!'), findsOneWidget);
    });

    testWidgets('failure shows the auth error and does not navigate',
        (tester) async {
      final h = await _pump(tester, mode: AuthMode.register, registerSucceeds: false);

      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'mia@example.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), 'hunter22');
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('already registered'), findsOneWidget);
      expect(h.landingStore.seenByLearner['test-learner'], isNull);
      expect(find.text('Home!'), findsNothing);
    });

    testWidgets('empty fields block submission with an inline error',
        (tester) async {
      await _pump(tester, mode: AuthMode.register);

      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();

      expect(find.textContaining('Please fill in'), findsOneWidget);
      expect(find.text('Home!'), findsNothing);
    });
  });

  group('log in', () {
    testWidgets(
        'success logs in, pulls remote progress onto this device, marks '
        'landing seen, and lands on home', (tester) async {
      final h = await _pump(tester, mode: AuthMode.login);

      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'mia@example.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), 'hunter22');
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();
      await tester.pump();

      expect(h.auth.lastLoginEmail, 'mia@example.com');
      expect(h.results.pullCalls, 1);
      expect(h.landingStore.seenByLearner['test-learner'], isTrue);
      expect(find.text('Home!'), findsOneWidget);
    });

    testWidgets('failure shows the auth error and does not navigate',
        (tester) async {
      final h = await _pump(tester, mode: AuthMode.login, logInSucceeds: false);

      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'mia@example.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), 'wrongpass');
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Invalid login credentials'), findsOneWidget);
      expect(h.results.pullCalls, 0);
      expect(find.text('Home!'), findsNothing);
    });
  });
}
