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

  List<MatchRound> build(
    List<Item> items, {
    Map<String, SrsState> states = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final ordered = _adaptiveOrder(items, states);

    return [
      for (final target in ordered)
        MatchRound(
          target: target,
          options: _optionsFor(target, items, rng),
        ),
    ];
  }

  /// Due/never-seen items first; within that, lower difficulty first.
  List<Item> _adaptiveOrder(List<Item> items, Map<String, SrsState> states) {
    final list = [...items];
    list.sort((a, b) {
      final da = states[a.id]?.isDue() ?? true;
      final db = states[b.id]?.isDue() ?? true;
      if (da != db) return da ? -1 : 1; // due ones first
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
