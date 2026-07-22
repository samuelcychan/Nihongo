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

  @override
  Future<void> pullRemoteProgress(String learnerId) async {}
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

// Nine items -- more than the old hardcoded 6-item cap -- to guard against
// the completability bug where AI-generated lessons (up to 10 items) could
// never be marked passed because some items were never shown/playable.
Lesson _bigLesson() => Lesson(
      id: 'L2',
      title: 'Big Lesson',
      activities: [
        Activity(
          id: 'A2',
          lessonId: 'L2',
          type: 'sequence',
          title: 'Sequence',
          items: [
            for (var i = 0; i < 9; i++)
              Item(id: 'b$i', activityId: 'A2', answer: 'w$i', glyph: '⭐', position: i),
          ],
        ),
      ],
    );

Future<_FakeResults> _pump(WidgetTester tester, {Lesson? lesson}) async {
  final results = _FakeResults();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(_FakeAudio()),
        resultsRepositoryProvider.overrideWithValue(results),
        learnerIdProvider.overrideWithValue('test-learner'),
      ],
      child: MaterialApp(home: SequenceActivityPage(lesson: lesson ?? _lesson())),
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

  testWidgets(
      'a lesson with more items than the old 6-item cap shows every item '
      '(regression: silently-dropped items made lessons unpassable)',
      (tester) async {
    await _pump(tester, lesson: _bigLesson());

    for (var i = 0; i < 9; i++) {
      expect(find.byKey(Key('slot_$i')), findsOneWidget);
    }
    for (var i = 0; i < 9; i++) {
      expect(find.byKey(Key('pool_b$i')), findsOneWidget);
    }
  });
}
