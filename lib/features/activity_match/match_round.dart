import 'dart:math';

import '../../core/srs/srs_scheduler.dart';
import '../../domain/models/content.dart';

/// One round of the tap-to-match game: a [target] item to identify among
/// [options] (which always include the target).
class MatchRound {
  const MatchRound({required this.target, required this.options});

  final Item target;
  final List<Item> options;
}

/// Builds the ordered sequence of rounds for a match activity.
///
/// Pure and deterministic when given a seeded [Random], so it is unit-testable.
/// Encodes the PRD F3 adaptivity: items that are due or weak are presented
/// first, otherwise easier (lower-difficulty) items lead.
class MatchRoundBuilder {
  const MatchRoundBuilder({this.optionCount = 4});

  final int optionCount;

  /// [recentAccuracy] (rolling fraction correct in [0, 1], from the learner's
  /// aggregate stats) activates M2's difficulty steering: the order targets
  /// the band [SrsScheduler.nextDifficulty] picks, so a learner on a streak
  /// is nudged into harder items and a struggling one eased down. When null
  /// (no meaningful history yet) ordering falls back to lower-difficulty-first.
  List<MatchRound> build(
    List<Item> items, {
    Map<String, SrsState> states = const {},
    double? recentAccuracy,
    Random? random,
  }) {
    final rng = random ?? Random();
    final ordered = _adaptiveOrder(items, states, recentAccuracy);

    return [
      for (final target in ordered)
        MatchRound(
          target: target,
          options: _optionsFor(target, items, rng),
        ),
    ];
  }

  /// Due/never-seen items first; within that, items closest to the adaptive
  /// target difficulty first (or plain lower-difficulty-first without history).
  List<Item> _adaptiveOrder(
    List<Item> items,
    Map<String, SrsState> states,
    double? recentAccuracy,
  ) {
    int? target;
    if (recentAccuracy != null && items.isNotEmpty) {
      // The learner's current band: mean difficulty of items they have seen,
      // or the easiest item on a fresh lesson.
      final seen = [for (final i in items) if (states.containsKey(i.id)) i];
      final current = seen.isEmpty
          ? items.map((i) => i.difficulty).reduce(min)
          : (seen.map((i) => i.difficulty).reduce((a, b) => a + b) /
                  seen.length)
              .round();
      target = const SrsScheduler().nextDifficulty(
        currentDifficulty: current,
        recentAccuracy: recentAccuracy,
      );
    }

    final list = [...items];
    list.sort((a, b) {
      final da = states[a.id]?.isDue() ?? true;
      final db = states[b.id]?.isDue() ?? true;
      if (da != db) return da ? -1 : 1; // due ones first
      if (target != null) {
        final ta = (a.difficulty - target).abs();
        final tb = (b.difficulty - target).abs();
        if (ta != tb) return ta.compareTo(tb); // closest to target band first
      }
      return a.difficulty.compareTo(b.difficulty);
    });
    return list;
  }

  List<Item> _optionsFor(Item target, List<Item> pool, Random rng) {
    final distractors = [
      for (final i in pool)
        if (i.id != target.id) i,
    ]..shuffle(rng);
    final options = <Item>[
      target,
      ...distractors.take(max(0, optionCount - 1)),
    ]..shuffle(rng);
    return options;
  }
}
