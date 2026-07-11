import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/core/db/app_database.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/parent_dashboard/parent_metrics.dart';

LocalItemState _state({
  required String itemId,
  int correctCount = 0,
  int incorrectCount = 0,
  int attempts = 0,
  int repetitions = 0,
  required DateTime updatedAt,
}) =>
    LocalItemState(
      learnerId: 'L',
      itemId: itemId,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      attempts: attempts,
      lastResponseMs: null,
      pronunciationScore: null,
      ease: 2.5,
      intervalDays: 0,
      repetitions: repetitions,
      dueAt: updatedAt,
      updatedAt: updatedAt,
      synced: true,
    );

Lesson _lesson(List<Item> items) => Lesson(
      id: 'L1',
      title: 'Lesson',
      activities: [
        Activity(id: 'A1', lessonId: 'L1', type: 'match', title: 'A', items: items),
      ],
    );

void main() {
  final now = DateTime(2026, 3, 12, 10); // a Thursday

  test('empty state yields ParentMetrics.empty-equivalent zeros', () {
    final m = computeParentMetrics(states: const [], courseLessons: const [], now: now);
    expect(m.mastered, 0);
    expect(m.accuracyPercent, 0);
    expect(m.dayStreak, 0);
    expect(m.minutesToday, 0);
    expect(m.reviewItems, isEmpty);
  });

  test('mastered counts items with repetitions >= 2', () {
    final states = [
      _state(itemId: 'i1', repetitions: 2, updatedAt: now),
      _state(itemId: 'i2', repetitions: 1, updatedAt: now),
      _state(itemId: 'i3', repetitions: 0, updatedAt: now),
    ];
    final m = computeParentMetrics(states: states, courseLessons: const [], now: now);
    expect(m.mastered, 1);
  });

  test('accuracy is correct/(correct+incorrect) across all items', () {
    final states = [
      _state(itemId: 'i1', correctCount: 3, incorrectCount: 1, updatedAt: now),
      _state(itemId: 'i2', correctCount: 6, incorrectCount: 0, updatedAt: now),
    ];
    final m = computeParentMetrics(states: states, courseLessons: const [], now: now);
    // 9 correct / 10 total = 90%
    expect(m.accuracyPercent, 90);
  });

  test('day streak counts consecutive days ending today', () {
    final states = [
      _state(itemId: 'i1', updatedAt: now),
      _state(itemId: 'i2', updatedAt: now.subtract(const Duration(days: 1))),
      _state(itemId: 'i3', updatedAt: now.subtract(const Duration(days: 2))),
      // gap here breaks the streak
      _state(itemId: 'i4', updatedAt: now.subtract(const Duration(days: 5))),
    ];
    final m = computeParentMetrics(states: states, courseLessons: const [], now: now);
    expect(m.dayStreak, 3);
  });

  test('day streak still counts yesterday when nothing happened today yet', () {
    final states = [
      _state(itemId: 'i1', updatedAt: now.subtract(const Duration(days: 1))),
      _state(itemId: 'i2', updatedAt: now.subtract(const Duration(days: 2))),
    ];
    final m = computeParentMetrics(states: states, courseLessons: const [], now: now);
    expect(m.dayStreak, 2);
  });

  test('day streak is 0 when the most recent activity was 2+ days ago', () {
    final states = [
      _state(itemId: 'i1', updatedAt: now.subtract(const Duration(days: 3))),
    ];
    final m = computeParentMetrics(states: states, courseLessons: const [], now: now);
    expect(m.dayStreak, 0);
  });

  test('minutesToday sums one continuous session (gaps under the 5-min threshold)', () {
    final states = [
      // Answers 4 minutes apart stay one session; total span is 12 minutes.
      _state(itemId: 'i1', updatedAt: now),
      _state(itemId: 'i2', updatedAt: now.add(const Duration(minutes: 4))),
      _state(itemId: 'i3', updatedAt: now.add(const Duration(minutes: 8))),
      _state(itemId: 'i4', updatedAt: now.add(const Duration(minutes: 12))),
    ];
    final m = computeParentMetrics(
      states: states,
      courseLessons: const [],
      now: now.add(const Duration(minutes: 12)),
    );
    expect(m.minutesToday, 12);
  });

  test('a gap over the session threshold starts a new session', () {
    final states = [
      _state(itemId: 'i1', updatedAt: now),
      _state(itemId: 'i2', updatedAt: now.add(const Duration(minutes: 2))),
      // 10-minute gap here breaks the session.
      _state(itemId: 'i3', updatedAt: now.add(const Duration(minutes: 12))),
    ];
    final m = computeParentMetrics(
      states: states,
      courseLessons: const [],
      now: now.add(const Duration(minutes: 12)),
    );
    // Session 1: 0-2min (2min). Session 2: a single point at 12min, floored
    // to the 0.5min minimum. Total ~2.5min, rounds to 3.
    expect(m.minutesToday, 3);
  });

  test('reviewItems surfaces items with incorrect answers, worst first', () {
    final items = [
      const Item(id: 'i1', activityId: 'A1', answer: 'ねこ', glyph: '🐱'),
      const Item(id: 'i2', activityId: 'A1', answer: 'いぬ', glyph: '🐶'),
      const Item(id: 'i3', activityId: 'A1', answer: 'とり', glyph: '🐦'),
    ];
    final states = [
      // i1: 1/4 correct -- worst.
      _state(itemId: 'i1', attempts: 4, correctCount: 1, incorrectCount: 3, updatedAt: now),
      // i2: perfect, never wrong -- should not appear.
      _state(itemId: 'i2', attempts: 2, correctCount: 2, incorrectCount: 0, updatedAt: now),
      // i3: 1/2 correct.
      _state(itemId: 'i3', attempts: 2, correctCount: 1, incorrectCount: 1, updatedAt: now),
    ];
    final m = computeParentMetrics(
      states: states,
      courseLessons: [_lesson(items)],
      now: now,
    );
    expect(m.reviewItems.map((i) => i.id), ['i1', 'i3']);
  });

  test('totalItems counts distinct items across all course lessons', () {
    final items1 = [const Item(id: 'i1', activityId: 'A1', answer: 'a')];
    final items2 = [const Item(id: 'i2', activityId: 'A2', answer: 'b')];
    final m = computeParentMetrics(
      states: const [],
      courseLessons: [_lesson(items1), _lesson(items2)],
      now: now,
    );
    expect(m.totalItems, 2);
  });
}
