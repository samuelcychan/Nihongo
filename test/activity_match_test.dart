import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/audio/audio_service.dart';
import 'package:kids_lang/data/results_repository.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/activity_match/activity_match_page.dart';

class _FakeAudio implements AudioService {
  @override
  Future<void> speakWord(String text, {String language = 'es-ES', String? audioUrl}) async {}
  @override
  Future<void> speakFeedback(String text, {String language = 'en-US'}) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _FakeResults implements ResultsSink {
  int calls = 0;
  bool? lastCorrect;
  @override
  Future<void> recordResult({
    required String learnerId,
    required Item item,
    required bool correct,
    required int attempts,
    Duration? responseTime,
    double? pronunciationScore,
  }) async {
    calls++;
    lastCorrect = correct;
  }

  @override
  Future<int> syncPending(String learnerId) async => 0;
}

Lesson _lesson() => const Lesson(
      id: 'L',
      title: 'Test Lesson',
      activities: [
        Activity(
          id: 'A',
          lessonId: 'L',
          type: 'match',
          title: 'Match',
          items: [
            Item(id: 'i1', activityId: 'A', answer: 'gato', glyph: '🐱'),
            Item(id: 'i2', activityId: 'A', answer: 'perro', glyph: '🐶'),
          ],
        ),
      ],
    );

Future<_FakeResults> _pump(WidgetTester tester) async {
  final results = _FakeResults();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(_FakeAudio()),
        resultsRepositoryProvider.overrideWithValue(results),
        learnerIdProvider.overrideWithValue('test-learner'),
        // The page reads these DB-backed providers (M2 difficulty steering +
        // no-reading mode); override so tests never touch a real database.
        progressProvider.overrideWith((ref) => Stream.value(const [])),
        noReadingModeProvider.overrideWith((ref) => Stream.value(false)),
      ],
      child: MaterialApp(home: ActivityMatchPage(lesson: _lesson())),
    ),
  );
  await tester.pump(); // run post-frame speak callback
  return results;
}

void main() {
  testWidgets('tapping the correct picture shows success and records a result',
      (tester) async {
    final results = await _pump(tester);

    // First round's target is i1 (lowest input order / difficulty). Tap it.
    await tester.tap(find.byKey(const ValueKey('option_i1')));
    await tester.pump();

    expect(find.byKey(const Key('feedback_correct')), findsOneWidget);

    // Let the post-correct delay + advance complete.
    await tester.pump(const Duration(milliseconds: 1300));

    expect(results.calls, 1);
    expect(results.lastCorrect, isTrue);
  });

  testWidgets('tapping a wrong picture shows try-again and records nothing',
      (tester) async {
    final results = await _pump(tester);

    // i2 is a distractor for the first round (target is i1).
    await tester.tap(find.byKey(const ValueKey('option_i2')));
    await tester.pump();

    expect(find.byKey(const Key('feedback_wrong')), findsOneWidget);
    expect(results.calls, 0);

    // Reverts to playing so the child can retry.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const Key('feedback_wrong')), findsNothing);
  });
}
