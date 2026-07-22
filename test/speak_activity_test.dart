import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/audio/audio_service.dart';
import 'package:kids_lang/core/speech/speech_service.dart';
import 'package:kids_lang/data/results_repository.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/activity_speak/speak_activity_page.dart';

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
  double? lastScore;
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
    lastScore = pronunciationScore;
  }

  @override
  Future<int> syncPending(String learnerId) async => 0;
}

/// Scripted speech recognizer: returns queued scores in order.
class _FakeSpeech implements SpeechService {
  _FakeSpeech({this.available = true, Iterable<double> scores = const []})
      : _scores = Queue.of(scores);

  final bool available;
  final Queue<double> _scores;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<PronunciationResult> evaluate({
    required String target,
    String language = 'es-ES',
  }) async {
    final score = _scores.isEmpty ? 0.0 : _scores.removeFirst();
    return PronunciationResult(transcript: 'heard', score: score);
  }

  @override
  Future<void> cancel() async {}
}

// Two items so passing the first doesn't finish the round (finishing needs a
// GoRouter for /complete -- same rationale as the other activity tests).
Lesson _lesson() => const Lesson(
      id: 'L',
      title: 'Test Lesson',
      targetLanguage: 'ja-JP',
      activities: [
        Activity(
          id: 'A',
          lessonId: 'L',
          type: 'speak',
          title: 'Say the Word',
          items: [
            Item(id: 'i1', activityId: 'A', answer: 'ねこ', promptText: 'ねこ', glyph: '🐱'),
            Item(id: 'i2', activityId: 'A', answer: 'いぬ', promptText: 'いぬ', glyph: '🐶'),
          ],
        ),
      ],
    );

// Nine items -- more than the old hardcoded 8-item cap -- to guard against
// the completability bug where AI-generated lessons (up to 10 items) could
// never be marked passed because some items were never shown/playable.
Lesson _bigLesson() => const Lesson(
      id: 'L2',
      title: 'Big Lesson',
      targetLanguage: 'ja-JP',
      activities: [
        Activity(
          id: 'A2',
          lessonId: 'L2',
          type: 'speak',
          title: 'Say the Word',
          items: [
            Item(id: 'b0', activityId: 'A2', answer: 'w0', promptText: 'w0', glyph: '⭐'),
            Item(id: 'b1', activityId: 'A2', answer: 'w1', promptText: 'w1', glyph: '⭐'),
            Item(id: 'b2', activityId: 'A2', answer: 'w2', promptText: 'w2', glyph: '⭐'),
            Item(id: 'b3', activityId: 'A2', answer: 'w3', promptText: 'w3', glyph: '⭐'),
            Item(id: 'b4', activityId: 'A2', answer: 'w4', promptText: 'w4', glyph: '⭐'),
            Item(id: 'b5', activityId: 'A2', answer: 'w5', promptText: 'w5', glyph: '⭐'),
            Item(id: 'b6', activityId: 'A2', answer: 'w6', promptText: 'w6', glyph: '⭐'),
            Item(id: 'b7', activityId: 'A2', answer: 'w7', promptText: 'w7', glyph: '⭐'),
            Item(id: 'b8', activityId: 'A2', answer: 'w8', promptText: 'w8', glyph: '⭐'),
          ],
        ),
      ],
    );

Future<_FakeResults> _pump(
  WidgetTester tester, {
  required SpeechService speech,
  bool noReading = false,
  Lesson? lesson,
}) async {
  final results = _FakeResults();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(_FakeAudio()),
        resultsRepositoryProvider.overrideWithValue(results),
        learnerIdProvider.overrideWithValue('test-learner'),
        speechServiceProvider.overrideWithValue(speech),
        noReadingModeProvider.overrideWith((ref) => Stream.value(noReading)),
      ],
      child: MaterialApp(home: SpeakActivityPage(lesson: lesson ?? _lesson())),
    ),
  );
  await tester.pump(); // availability probe resolves
  await tester.pump();
  return results;
}

void main() {
  testWidgets('a good attempt records the pronunciation score as correct',
      (tester) async {
    final results =
        await _pump(tester, speech: _FakeSpeech(scores: const [0.9]));

    await tester.tap(find.byKey(const Key('speak_mic_button')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('speak_feedback_good')), findsOneWidget);
    expect(results.calls, 1);
    expect(results.lastCorrect, isTrue);
    expect(results.lastScore, 0.9);

    await tester.pump(const Duration(milliseconds: 1300)); // advance timer
  });

  testWidgets('a poor first attempt allows a retry without recording',
      (tester) async {
    final results =
        await _pump(tester, speech: _FakeSpeech(scores: const [0.2, 0.1]));

    await tester.tap(find.byKey(const Key('speak_mic_button')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('speak_feedback_try')), findsOneWidget);
    expect(results.calls, 0); // first miss = free retry, nothing recorded

    // Second miss records an incorrect result with the score.
    await tester.tap(find.byKey(const Key('speak_mic_button')));
    await tester.pump();
    await tester.pump();

    expect(results.calls, 1);
    expect(results.lastCorrect, isFalse);
    expect(results.lastScore, 0.1);

    await tester.pump(const Duration(milliseconds: 1300));
  });

  testWidgets('unavailable speech shows the friendly fallback, no dead end',
      (tester) async {
    await _pump(tester, speech: _FakeSpeech(available: false));

    expect(find.byKey(const Key('speech_unavailable')), findsOneWidget);
    expect(find.byKey(const Key('speak_mic_button')), findsNothing);
  });

  testWidgets('no-reading mode hides the prompt text (M2 NFR-a11y)',
      (tester) async {
    await _pump(tester,
        speech: _FakeSpeech(scores: const [0.9]), noReading: true);

    expect(find.byKey(const Key('speak_prompt_text')), findsNothing);
    // The game is still fully playable -- mic and replay affordances remain.
    expect(find.byKey(const Key('speak_mic_button')), findsOneWidget);
    expect(find.byKey(const Key('speak_replay_button')), findsOneWidget);
  });

  testWidgets(
      'a lesson with more items than the old 8-item cap plays every item '
      '(regression: silently-dropped items made lessons unpassable)',
      (tester) async {
    final results = await _pump(
      tester,
      speech: _FakeSpeech(scores: List.filled(9, 0.9)),
      lesson: _bigLesson(),
    );

    // Stop one short of the last item -- finishing triggers a '/complete'
    // navigation, and these tests run without a GoRouter (same rationale as
    // the other activity tests' "never trigger the final round" fixtures).
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const Key('speak_mic_button')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
    }

    expect(results.calls, 8);
    // Reaching item 9 (the old cap was 8) proves nothing was silently dropped.
    expect(find.text('9/9'), findsOneWidget);
  });
}
