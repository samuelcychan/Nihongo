import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_lang/core/srs/srs_scheduler.dart';
import 'package:kids_lang/domain/models/content.dart';
import 'package:kids_lang/features/activity_match/match_round.dart';

Item _item(String id, int difficulty) => Item(
      id: id,
      activityId: 'A',
      answer: id,
      promptText: id,
      glyph: '⭐',
      difficulty: difficulty,
    );

SrsState _seen({bool due = false}) {
  final now = DateTime.now();
  return SrsState(
    ease: 2.5,
    intervalDays: 6,
    repetitions: 2,
    dueAt: due ? now.subtract(const Duration(days: 1)) : now.add(const Duration(days: 5)),
  );
}

void main() {
  final items = [
    _item('d1', 1),
    _item('d2', 2),
    _item('d3', 3),
    _item('d4', 4),
    _item('d5', 5),
  ];

  test('without history, easier items lead (M0 behavior preserved)', () {
    final rounds =
        const MatchRoundBuilder().build(items, random: Random(1));
    expect(rounds.first.target.id, 'd1');
    expect([for (final r in rounds) r.target.difficulty], [1, 2, 3, 4, 5]);
  });

  test('high accuracy steers the order toward harder items (M2 F3)', () {
    // Learner has seen all five (none due) and is answering ~everything
    // right: current band = mean(1..5) = 3, accuracy >= .85 nudges the
    // target up to 4 -- so d4 leads instead of the easiest item.
    final states = {
      'd1': _seen(),
      'd2': _seen(),
      'd3': _seen(),
      'd4': _seen(),
      'd5': _seen(),
    };
    final rounds = const MatchRoundBuilder()
        .build(items, states: states, recentAccuracy: 0.9, random: Random(1));
    expect(rounds.first.target.id, 'd4');
  });

  test('low accuracy steers the order toward easier items', () {
    final states = {
      'd1': _seen(),
      'd2': _seen(),
      'd3': _seen(),
      'd4': _seen(),
      'd5': _seen(),
    };
    // current band = 3, accuracy < .5 nudges target down to 2.
    final rounds = const MatchRoundBuilder()
        .build(items, states: states, recentAccuracy: 0.3, random: Random(1));
    expect(rounds.first.target.difficulty, 2);
  });

  test('due items still outrank difficulty steering', () {
    final states = {
      'd1': _seen(),
      'd2': _seen(),
      'd3': _seen(),
      'd4': _seen(),
      'd5': _seen(due: true), // overdue -- must come first regardless of band
    };
    final rounds = const MatchRoundBuilder()
        .build(items, states: states, recentAccuracy: 0.9, random: Random(1));
    expect(rounds.first.target.id, 'd5');
  });
}
