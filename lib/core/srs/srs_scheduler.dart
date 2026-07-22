/// Spaced-repetition scheduling (SM-2-lite) and adaptive difficulty helpers.
///
/// Pure Dart, no Flutter or package dependencies, so it is trivially unit
/// testable and reusable across every activity type (PRD F3). Given the
/// outcome of answering an item, it produces the next review schedule and a
/// difficulty signal used to keep the next item in the learner's "right zone".
library;

import 'dart:math' as math;

/// Immutable snapshot of a learner's memory state for a single item.
class SrsState {
  const SrsState({
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
  });

  /// Ease factor (SM-2). Higher = easier; clamped to [[minEase], ∞).
  final double ease;

  /// Current review interval in days.
  final double intervalDays;

  /// Number of consecutive successful reviews.
  final int repetitions;

  /// When the item next becomes due for review.
  final DateTime dueAt;

  /// Fresh state for an item the learner has never seen.
  factory SrsState.initial({DateTime? now}) {
    final t = now ?? DateTime.now();
    return SrsState(
      ease: defaultEase,
      intervalDays: 0,
      repetitions: 0,
      dueAt: t,
    );
  }

  static const double defaultEase = 2.5;
  static const double minEase = 1.3;

  bool isDue({DateTime? now}) =>
      !(now ?? DateTime.now()).isBefore(dueAt) || repetitions == 0;

  SrsState copyWith({
    double? ease,
    double? intervalDays,
    int? repetitions,
    DateTime? dueAt,
  }) =>
      SrsState(
        ease: ease ?? this.ease,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        dueAt: dueAt ?? this.dueAt,
      );
}

/// Computes review schedules and difficulty adjustments.
class SrsScheduler {
  const SrsScheduler();

  /// Updates [state] after an answer.
  ///
  /// [quality] is the recall quality on the SM-2 0–5 scale. For binary
  /// activities use [qualityFromOutcome] to derive it from correctness,
  /// attempts and response time.
  SrsState review(SrsState state, int quality, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final q = quality.clamp(0, 5);

    // Failure (q < 3): reset repetitions, review again soon, drop ease a little.
    if (q < 3) {
      final ease = math.max(SrsState.minEase, state.ease - 0.2);
      return state.copyWith(
        ease: ease,
        intervalDays: 0,
        repetitions: 0,
        // Re-show within the same session (~10 minutes) so weak items resurface.
        dueAt: t.add(const Duration(minutes: 10)),
      );
    }

    // Success: grow the interval and nudge ease per the SM-2 formula.
    final reps = state.repetitions + 1;
    final double interval;
    if (reps == 1) {
      interval = 1;
    } else if (reps == 2) {
      interval = 6;
    } else {
      interval = (state.intervalDays * state.ease).ceilToDouble();
    }

    final ease = math.max(
      SrsState.minEase,
      state.ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)),
    );

    return state.copyWith(
      ease: ease,
      intervalDays: interval,
      repetitions: reps,
      dueAt: t.add(Duration(milliseconds: (interval * Duration.millisecondsPerDay).round())),
    );
  }

  /// Derives an SM-2 quality (0–5) from a binary activity outcome.
  ///
  /// Correct on the first try with a quick response scores highest; each extra
  /// attempt and slow responses reduce the score. Incorrect answers map to the
  /// failure band (< 3).
  int qualityFromOutcome({
    required bool correct,
    required int attempts,
    Duration? responseTime,
  }) {
    if (!correct) {
      // More attempts before giving up → slightly lower (0..2).
      return attempts >= 3 ? 0 : 2;
    }
    var q = 5;
    if (attempts >= 2) q -= 1;
    if (attempts >= 3) q -= 1;
    if (responseTime != null && responseTime.inSeconds > 8) q -= 1;
    return q.clamp(3, 5);
  }

  /// Derives an SM-2 quality (0–5) from a pronunciation score in [0, 1]
  /// (PRD F3 — the speak activity's scores feed scheduling exactly like
  /// binary outcomes do). Thresholds mirror [qualityFromOutcome]'s bands:
  /// >= 0.5 counts as a successful recall (>= 3), below that as a failure.
  int qualityFromPronunciation(double score) {
    final s = score.clamp(0.0, 1.0);
    if (s >= 0.85) return 5;
    if (s >= 0.7) return 4;
    if (s >= 0.5) return 3;
    if (s >= 0.3) return 2;
    return s > 0 ? 1 : 0;
  }

  /// Adaptive difficulty target for the next item, on the same 1..5 scale the
  /// content is tagged with (PRD F3). Strong recent performance nudges the
  /// learner up; struggling nudges them down, keeping challenge in the zone.
  ///
  /// [currentDifficulty] is the difficulty just answered; [recentAccuracy] is
  /// the rolling fraction correct in [0, 1].
  int nextDifficulty({
    required int currentDifficulty,
    required double recentAccuracy,
    int minDifficulty = 1,
    int maxDifficulty = 5,
  }) {
    var next = currentDifficulty;
    if (recentAccuracy >= 0.85) {
      next += 1;
    } else if (recentAccuracy < 0.5) {
      next -= 1;
    }
    return next.clamp(minDifficulty, maxDifficulty);
  }
}
