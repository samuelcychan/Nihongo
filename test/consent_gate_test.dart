import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/db/app_database.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/consent_gate/consent_gate_page.dart';

/// In-memory fake -- avoids spinning up a real drift/sqlite3 backend in
/// widget tests (native-assets sqlite3 FFI doesn't reliably work under
/// `flutter test` on this platform; ConsentStore exists specifically so
/// this fake, not a real AppDatabase, is what tests exercise).
class _FakeConsentStore implements ConsentStore {
  final Map<String, bool> givenByLearner = {};

  @override
  Future<void> setConsentGiven(String learnerId, bool given) async {
    givenByLearner[learnerId] = given;
  }
}

/// Fake that fails on the first call, then succeeds on subsequent calls.
class _FailOnceThenSucceedConsentStore implements ConsentStore {
  int callCount = 0;
  final Map<String, bool> givenByLearner = {};

  @override
  Future<void> setConsentGiven(String learnerId, bool given) async {
    callCount++;
    if (callCount == 1) throw Exception('simulated write failure');
    givenByLearner[learnerId] = given;
  }
}

Future<void> _pump(WidgetTester tester, _FakeConsentStore store) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        consentStoreProvider.overrideWithValue(store),
        learnerIdProvider.overrideWithValue('test-learner'),
      ],
      child: MaterialApp(home: const ConsentGatePage()),
    ),
  );
  await tester.pump();
}

/// Reads the two numbers out of the rendered "what is A + B?" prompt so
/// tests don't need to fix the randomized values.
(int, int) _readQuestion(WidgetTester tester) {
  final textWidget = tester.widget<Text>(find.textContaining('Quick check'));
  final match = RegExp(r'(\d+) \+ (\d+)').firstMatch(textWidget.data!);
  return (int.parse(match!.group(1)!), int.parse(match.group(2)!));
}

void main() {
  testWidgets('wrong answer blocks continuing and records nothing',
      (tester) async {
    final store = _FakeConsentStore();
    await _pump(tester, store);

    await tester.enterText(find.byKey(const Key('consent_answer_field')), '999999');
    await tester.tap(find.byKey(const Key('consent_checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('consent_continue_button')));
    await tester.pump();

    expect(find.textContaining("doesn't look right"), findsOneWidget);
    expect(store.givenByLearner['test-learner'], isNull);
  });

  testWidgets('correct answer without the guardian checkbox blocks continuing',
      (tester) async {
    final store = _FakeConsentStore();
    await _pump(tester, store);

    final (a, b) = _readQuestion(tester);
    await tester.enterText(
        find.byKey(const Key('consent_answer_field')), '${a + b}');
    await tester.tap(find.byKey(const Key('consent_continue_button')));
    await tester.pump();

    expect(find.textContaining('confirm you are the parent'), findsOneWidget);
    expect(store.givenByLearner['test-learner'], isNull);
  });

  testWidgets(
      'correct answer + checkbox records consent and forwards to the pending lesson',
      (tester) async {
    final store = _FakeConsentStore();

    const lesson = Lesson(id: 'L', title: 'Test', activities: []);
    final router = GoRouter(
      initialLocation: '/consent',
      routes: [
        GoRoute(
          path: '/consent',
          builder: (context, state) => const ConsentGatePage(pendingLesson: lesson),
        ),
        GoRoute(
          path: '/play',
          builder: (context, state) => const Scaffold(body: Text('Playing!')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentStoreProvider.overrideWithValue(store),
          learnerIdProvider.overrideWithValue('test-learner'),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    final (a, b) = _readQuestion(tester);
    await tester.enterText(
        find.byKey(const Key('consent_answer_field')), '${a + b}');
    await tester.tap(find.byKey(const Key('consent_checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('consent_continue_button')));
    await tester.pump();
    await tester.pump();

    expect(store.givenByLearner['test-learner'], isTrue);
    expect(find.text('Playing!'), findsOneWidget);
  });

  testWidgets(
      'write failure shows error and re-enables button; retry succeeds',
      (tester) async {
    final store = _FailOnceThenSucceedConsentStore();

    const lesson = Lesson(id: 'L', title: 'Test', activities: []);
    final router = GoRouter(
      initialLocation: '/consent',
      routes: [
        GoRoute(
          path: '/consent',
          builder: (context, state) =>
              const ConsentGatePage(pendingLesson: lesson),
        ),
        GoRoute(
          path: '/play',
          builder: (context, state) => const Scaffold(body: Text('Playing!')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentStoreProvider.overrideWithValue(store),
          learnerIdProvider.overrideWithValue('test-learner'),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    final (a, b) = _readQuestion(tester);
    await tester.enterText(
        find.byKey(const Key('consent_answer_field')), '${a + b}');
    await tester.tap(find.byKey(const Key('consent_checkbox')));
    await tester.pump();

    // First attempt: the store throws.
    await tester.tap(find.byKey(const Key('consent_continue_button')));
    await tester.pump();
    await tester.pump();

    // (1) Error message is shown.
    expect(find.textContaining('Something went wrong saving that'), findsOneWidget);
    // (2) Continue button is re-enabled (no spinner, onPressed is not null).
    expect(find.text('Continue'), findsOneWidget);
    final button = tester.widget<FilledButton>(
        find.byKey(const Key('consent_continue_button')));
    expect(button.onPressed, isNotNull);

    // (3) Tapping Continue again retries and succeeds.
    await tester.tap(find.byKey(const Key('consent_continue_button')));
    await tester.pump();
    await tester.pump();

    expect(store.givenByLearner['test-learner'], isTrue);
    expect(find.text('Playing!'), findsOneWidget);
  });
}
