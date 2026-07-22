import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/app/providers.dart';
import 'package:kids_lang/core/audio/audio_service.dart';
import 'package:kids_lang/data/results_repository.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/activity_dragdrop/dragdrop_activity_page.dart';

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

// Three pairs so completing one match doesn't finish the whole board --
// mirrors activity_match_test.dart's approach of never triggering the
// post-completion navigation (no GoRouter is set up in these widget tests).
Lesson _lesson() => const Lesson(
      id: 'L',
      title: 'Test Lesson',
      activities: [
        Activity(
          id: 'A',
          lessonId: 'L',
          type: 'drag_drop',
          title: 'Drag',
          items: [
            Item(id: 'i1', activityId: 'A', answer: 'gato', promptText: 'gato', glyph: '🐱'),
            Item(id: 'i2', activityId: 'A', answer: 'perro', promptText: 'perro', glyph: '🐶'),
            Item(id: 'i3', activityId: 'A', answer: 'pato', promptText: 'pato', glyph: '🦆'),
          ],
        ),
      ],
    );

// Nine items -- more than the old hardcoded 5-pair cap -- to guard against
// the completability bug where AI-generated lessons (up to 10 items) could
// never be marked passed because some items were never shown/playable.
Lesson _bigLesson() => Lesson(
      id: 'L2',
      title: 'Big Lesson',
      activities: [
        Activity(
          id: 'A2',
          lessonId: 'L2',
          type: 'drag_drop',
          title: 'Drag',
          items: [
            for (var i = 1; i <= 9; i++)
              Item(id: 'b$i', activityId: 'A2', answer: 'w$i', promptText: 'w$i', glyph: '⭐'),
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
      child: MaterialApp(home: DragDropActivityPage(lesson: lesson ?? _lesson())),
    ),
  );
  await tester.pump();
  return results;
}

Future<void> _drag(WidgetTester tester, String itemId) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(Key('draggable_$itemId'))),
  );
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.byKey(Key('drop_target_$itemId'))));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('dropping a picture on its matching label records success',
      (tester) async {
    final results = await _pump(tester);

    await _drag(tester, 'i1');

    expect(results.calls, 1);
    expect(results.lastCorrect, isTrue);
    // The matched draggable is removed from the pool.
    expect(find.byKey(const Key('draggable_i1')), findsNothing);
  });

  testWidgets('dropping a picture on the wrong label records nothing',
      (tester) async {
    final results = await _pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('draggable_i1'))),
    );
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(const Key('drop_target_i2'))));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(results.calls, 0);
    // The dragged tile stays in the pool for another attempt.
    expect(find.byKey(const Key('draggable_i1')), findsOneWidget);

    // Wrong-flash clears itself after the delay.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets(
      'a lesson with more items than the old 5-pair cap shows every item '
      '(regression: silently-dropped items made lessons unpassable)',
      (tester) async {
    await _pump(tester, lesson: _bigLesson());

    for (var i = 1; i <= 9; i++) {
      expect(find.byKey(Key('drop_target_b$i')), findsOneWidget);
      expect(find.byKey(Key('draggable_b$i')), findsOneWidget);
    }
  });
}
