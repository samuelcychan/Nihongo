import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/core/speech/pronunciation_scorer.dart';
import 'package:kids_lang/core/srs/srs_scheduler.dart';

void main() {
  group('pronunciationScore', () {
    test('exact match scores 1', () {
      expect(pronunciationScore('ねこ', 'ねこ'), 1);
    });

    test('transcript containing the target scores 1 (recognizer padding)', () {
      expect(pronunciationScore('cat', 'the cat'), 1);
      expect(pronunciationScore('ねこ', 'ねこ です'), 1);
    });

    test('case and punctuation are ignored', () {
      expect(pronunciationScore('Cat', 'cat!'), 1);
      expect(pronunciationScore('ねこ', 'ねこ。'), 1);
    });

    test('close-but-imperfect scores between 0 and 1', () {
      final s = pronunciationScore('さかな', 'さかん');
      expect(s, greaterThan(0.5));
      expect(s, lessThan(1));
    });

    test('unrelated word scores low', () {
      expect(pronunciationScore('ねこ', 'ひこうき'), lessThan(0.5));
    });

    test('empty transcript (timeout / heard nothing) scores 0', () {
      expect(pronunciationScore('ねこ', ''), 0);
      expect(pronunciationScore('ねこ', '   '), 0);
    });
  });

  group('SrsScheduler.qualityFromPronunciation', () {
    const scheduler = SrsScheduler();

    test('great pronunciation maps to top quality', () {
      expect(scheduler.qualityFromPronunciation(1.0), 5);
      expect(scheduler.qualityFromPronunciation(0.9), 5);
    });

    test('passable pronunciation stays in the success band (>= 3)', () {
      expect(scheduler.qualityFromPronunciation(0.7), 4);
      expect(scheduler.qualityFromPronunciation(0.5), 3);
    });

    test('poor pronunciation maps to the failure band (< 3)', () {
      expect(scheduler.qualityFromPronunciation(0.4), lessThan(3));
      expect(scheduler.qualityFromPronunciation(0.0), 0);
    });

    test('failure band resets the schedule like a wrong answer', () {
      final now = DateTime(2026, 1, 1);
      final prior = SrsState(
        ease: 2.5,
        intervalDays: 6,
        repetitions: 2,
        dueAt: now,
      );
      final q = scheduler.qualityFromPronunciation(0.2);
      final next = scheduler.review(prior, q, now: now);
      expect(next.repetitions, 0);
      expect(next.intervalDays, 0);
    });
  });
}
