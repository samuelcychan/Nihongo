import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/core/srs/srs_scheduler.dart';

void main() {
  const scheduler = SrsScheduler();
  final now = DateTime(2026, 1, 1, 9);

  group('qualityFromOutcome', () {
    test('correct on first try, fast => top quality', () {
      expect(
        scheduler.qualityFromOutcome(
            correct: true, attempts: 1, responseTime: const Duration(seconds: 2)),
        5,
      );
    });

    test('more attempts lower the quality but stay in success band', () {
      final q = scheduler.qualityFromOutcome(correct: true, attempts: 3);
      expect(q, inInclusiveRange(3, 4));
    });

    test('incorrect maps to the failure band (<3)', () {
      expect(
        scheduler.qualityFromOutcome(correct: false, attempts: 1),
        lessThan(3),
      );
    });
  });

  group('review', () {
    test('first success schedules ~1 day out and counts a repetition', () {
      final next = scheduler.review(SrsState.initial(now: now), 5, now: now);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.dueAt.isAfter(now), isTrue);
    });

    test('second success grows the interval to 6 days', () {
      var s = scheduler.review(SrsState.initial(now: now), 5, now: now);
      s = scheduler.review(s, 5, now: now);
      expect(s.repetitions, 2);
      expect(s.intervalDays, 6);
    });

    test('failure resets repetitions and resurfaces the item soon', () {
      var s = scheduler.review(SrsState.initial(now: now), 5, now: now);
      s = scheduler.review(s, 1, now: now); // got it wrong
      expect(s.repetitions, 0);
      expect(s.intervalDays, 0);
      expect(s.dueAt.difference(now).inMinutes, lessThanOrEqualTo(15));
      expect(s.ease, greaterThanOrEqualTo(SrsState.minEase));
    });
  });

  group('nextDifficulty', () {
    test('strong accuracy nudges difficulty up', () {
      expect(
        scheduler.nextDifficulty(currentDifficulty: 2, recentAccuracy: 0.9),
        3,
      );
    });

    test('struggling nudges difficulty down', () {
      expect(
        scheduler.nextDifficulty(currentDifficulty: 2, recentAccuracy: 0.3),
        1,
      );
    });

    test('clamps within bounds', () {
      expect(
        scheduler.nextDifficulty(currentDifficulty: 5, recentAccuracy: 0.95),
        5,
      );
      expect(
        scheduler.nextDifficulty(currentDifficulty: 1, recentAccuracy: 0.1),
        1,
      );
    });
  });
}
