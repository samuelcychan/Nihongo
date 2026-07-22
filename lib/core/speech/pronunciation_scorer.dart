/// Pure pronunciation scoring (PRD F2/F3) — no Flutter/plugin dependencies so
/// it is trivially unit-testable, mirroring SrsScheduler's design.
library;

import 'dart:math' as math;

/// Scores how closely a recognizer [transcript] matches the [target] word,
/// returning a value in [0, 1] that feeds `learner_item_states.pronunciation_score`.
///
/// The score is a normalized Levenshtein similarity over the cleaned strings,
/// with a containment shortcut: if the cleaned transcript contains the cleaned
/// target (recognizers often pad with extra words — "the cat" for "cat"),
/// it scores 1.0.
///
/// Known limitation (documented, accepted for M2): Japanese on-device
/// recognizers may return kanji (猫) where content stores kana (ねこ); those
/// score 0 without a kana converter. Mitigate in content by preferring words
/// whose common recognition form is kana, or revisit with a reading-aware
/// scorer in a later milestone.
double pronunciationScore(String target, String transcript) {
  final t = _clean(target);
  final h = _clean(transcript);
  if (t.isEmpty || h.isEmpty) return 0;
  if (h == t || h.contains(t)) return 1;

  final distance = _levenshtein(t, h);
  final maxLen = math.max(t.length, h.length);
  return (1 - distance / maxLen).clamp(0.0, 1.0);
}

/// Lowercases and strips whitespace/common punctuation so trivial formatting
/// differences never count against the child.
String _clean(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[\s、。,.!?！？・]+'), '');

int _levenshtein(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  var prev = List<int>.generate(n + 1, (j) => j);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = math.min(
        math.min(curr[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}
