import '../../core/db/app_database.dart';
import '../../domain/models/content.dart';

/// Real parent-dashboard aggregates (M1 NFR-parent), derived entirely from
/// [LocalItemState] rows already tracked by the SRS system -- no new
/// tracking fields needed. Kept as a pure function (not a widget) so the
/// derivation logic is unit-testable without pumping a widget tree.
class ParentMetrics {
  const ParentMetrics({
    required this.mastered,
    required this.totalItems,
    required this.accuracyPercent,
    required this.dayStreak,
    required this.minutesToday,
    required this.weekFractions,
    required this.reviewItems,
  });

  final int mastered;
  final int totalItems;

  /// 0-100, rounded. 0 when nothing has been attempted yet.
  final int accuracyPercent;

  /// Consecutive days with at least one answer, counting today if it has
  /// activity, otherwise counting back from yesterday (so the streak
  /// doesn't visually reset to 0 just because today hasn't started yet).
  final int dayStreak;

  final int minutesToday;

  /// 7 entries, Monday..Sunday, each in [0, 1] -- the fraction of this
  /// week's busiest day, for the existing bar-chart widget.
  final List<double> weekFractions;

  /// Up to 2 items with the worst recent accuracy, for the "could use
  /// review" chips. Empty until the learner has gotten something wrong.
  final List<Item> reviewItems;

  static const empty = ParentMetrics(
    mastered: 0,
    totalItems: 0,
    accuracyPercent: 0,
    dayStreak: 0,
    minutesToday: 0,
    weekFractions: [0, 0, 0, 0, 0, 0, 0],
    reviewItems: [],
  );
}

/// A burst of answers within [_sessionGapMinutes] of each other counts as one
/// continuous play session; the session's duration is its last-minus-first
/// timestamp, floored to [_minSessionMinutes] so a single quick answer still
/// registers a little time rather than zero.
const _sessionGapMinutes = 5;
const _minSessionMinutes = 0.5;

ParentMetrics computeParentMetrics({
  required List<LocalItemState> states,
  required List<Lesson> courseLessons,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final allItems = <String, Item>{
    for (final lesson in courseLessons)
      for (final item in lesson.allItems) item.id: item,
  };

  final mastered = states.where((s) => s.repetitions >= 2).length;

  var correctSum = 0, incorrectSum = 0;
  for (final s in states) {
    correctSum += s.correctCount;
    incorrectSum += s.incorrectCount;
  }
  final attempted = correctSum + incorrectSum;
  final accuracyPercent = attempted == 0 ? 0 : ((correctSum / attempted) * 100).round();

  final timestamps = states.map((s) => s.updatedAt).toList()..sort();
  final dayStreak = _computeStreak(timestamps, n);
  final minutesPerDay = _sessionMinutesByDay(timestamps);

  final today = DateTime(n.year, n.month, n.day);
  final minutesToday = (minutesPerDay[today] ?? 0).round();

  final monday = today.subtract(Duration(days: today.weekday - 1));
  final weekMinutes = [
    for (var i = 0; i < 7; i++) minutesPerDay[monday.add(Duration(days: i))] ?? 0.0,
  ];
  final weekMax = weekMinutes.fold(0.0, (a, b) => a > b ? a : b);
  final weekFractions = weekMax <= 0
      ? List.filled(7, 0.0)
      : [for (final m in weekMinutes) (m / weekMax).clamp(0.0, 1.0)];

  final attemptedStates = states.where((s) => s.attempts > 0).toList()
    ..sort((a, b) {
      double rate(LocalItemState s) => s.incorrectCount / (s.attempts == 0 ? 1 : s.attempts);
      return rate(b).compareTo(rate(a));
    });
  final reviewItems = [
    for (final s in attemptedStates)
      if (s.incorrectCount > 0 && allItems.containsKey(s.itemId)) allItems[s.itemId]!,
  ].take(2).toList();

  return ParentMetrics(
    mastered: mastered,
    totalItems: allItems.length,
    accuracyPercent: accuracyPercent,
    dayStreak: dayStreak,
    minutesToday: minutesToday,
    weekFractions: weekFractions,
    reviewItems: reviewItems,
  );
}

int _computeStreak(List<DateTime> sortedTimestamps, DateTime now) {
  if (sortedTimestamps.isEmpty) return 0;
  final activeDays = sortedTimestamps
      .map((t) => DateTime(t.year, t.month, t.day))
      .toSet();

  var cursor = DateTime(now.year, now.month, now.day);
  if (!activeDays.contains(cursor)) {
    final yesterday = cursor.subtract(const Duration(days: 1));
    if (!activeDays.contains(yesterday)) return 0;
    cursor = yesterday;
  }

  var streak = 0;
  while (activeDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

Map<DateTime, double> _sessionMinutesByDay(List<DateTime> sortedTimestamps) {
  final result = <DateTime, double>{};
  if (sortedTimestamps.isEmpty) return result;

  DateTime sessionStart = sortedTimestamps.first;
  DateTime sessionEnd = sortedTimestamps.first;

  void flush() {
    final day = DateTime(sessionStart.year, sessionStart.month, sessionStart.day);
    final minutes = sessionEnd.difference(sessionStart).inSeconds / 60;
    result[day] = (result[day] ?? 0) + (minutes < _minSessionMinutes ? _minSessionMinutes : minutes);
  }

  for (final t in sortedTimestamps.skip(1)) {
    if (t.difference(sessionEnd).inMinutes > _sessionGapMinutes) {
      flush();
      sessionStart = t;
    }
    sessionEnd = t;
  }
  flush();
  return result;
}
