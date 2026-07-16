import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/audio/audio_service.dart';
import 'package:kids_lang/data/results_repository.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/activity_sequence/sequence_activity_page.dart';

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

// Three items so filling one slot doesn't finish the whole sequence -- same
// no-GoRouter-in-tests rationale as activity_match_test.dart.
Lesson _lesson() => const Lesson(
      id: 'L',
      title: 'Test Lesson',
      activities: [
        Activity(
          id: 'A',
          lessonId: 'L',
          type: 'sequence',
          title: 'Sequence',
          items: [
            Item(id: 'i1', activityId: 'A', answer: 'one', glyph: '1️⃣', position: 0),
            Item(id: 'i2', activityId: 'A', answer: 'two', glyph: '2️⃣', position: 1),
            Item(id: 'i3', activityId: 'A', answer: 'three', glyph: '3️⃣', position: 2),
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
      ],
      child: MaterialApp(home: SequenceActivityPage(lesson: _lesson())),
    ),
  );
  await tester.pump();
  return results;
}

void main() {
  testWidgets('tapping the next item in order fills the slot and records success',
      (tester) async {
    final results = await _pump(tester);

    await tester.tap(find.byKey(const Key('pool_tile_i1')));
    await tester.pump();

    expect(results.calls, 1);
    expect(results.lastCorrect, isTrue);
    // i1 moves from the pool into slot 0.
    expect(find.byKey(const Key('pool_tile_i1')), findsNothing);
  });

  testWidgets('tapping out of order shakes and records nothing', (tester) async {
    final results = await _pump(tester);

    // i2 is position 1; the expected next tap is i1 (position 0).
    await tester.tap(find.byKey(const Key('pool_tile_i2')));
    await tester.pump();

    expect(results.calls, 0);
    expect(find.byKey(const Key('pool_tile_i2')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
  });
}
