import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/db/app_database.dart';
import '../core/srs/srs_scheduler.dart';
import '../domain/models/content.dart';

/// Records the outcome of answering an item. Small interface so activities can
/// be tested with a fake that needs neither drift nor Supabase.
abstract class ResultsSink {
  Future<void> recordResult({
    required String learnerId,
    required Item item,
    required bool correct,
    required int attempts,
    Duration? responseTime,
    double? pronunciationScore,
  });

  /// Pushes any locally-queued (unsynced) results to the backend. Safe to call
  /// repeatedly; returns how many rows synced. Called on reconnect.
  Future<int> syncPending(String learnerId);
}

/// Persists per-item results offline-first, then syncs to Supabase (PRD F3 +
/// offline requirement). This outbox pattern is the template for all writes:
/// 1. compute the new SRS state, 2. write locally (synced = false),
/// 3. best-effort push to Supabase, 4. mark synced on success.
class ResultsRepository implements ResultsSink {
  // Public named params map to private fields, so initializing formals don't apply.
  // ignore_for_file: prefer_initializing_formals
  ResultsRepository({
    required AppDatabase db,
    required SupabaseClient client,
    SrsScheduler scheduler = const SrsScheduler(),
  })  : _db = db,
        _client = client,
        _scheduler = scheduler;

  final AppDatabase _db;
  final SupabaseClient _client;
  final SrsScheduler _scheduler;

  /// Records the outcome of answering [item] and returns the updated row.
  ///
  /// When [pronunciationScore] is provided (the speak activity), it drives
  /// the SRS quality signal instead of the binary outcome and is persisted
  /// to `pronunciation_score` (PRD F3).
  @override
  Future<LocalItemState> recordResult({
    required String learnerId,
    required Item item,
    required bool correct,
    required int attempts,
    Duration? responseTime,
    double? pronunciationScore,
  }) async {
    final now = DateTime.now();

    // Load prior state (if any) to advance the SRS schedule.
    final existing = await _db.statesForItems(learnerId, [item.id]);
    final prior = existing.isEmpty ? null : existing.first;
    final priorSrs = prior == null
        ? SrsState.initial(now: now)
        : SrsState(
            ease: prior.ease,
            intervalDays: prior.intervalDays,
            repetitions: prior.repetitions,
            dueAt: prior.dueAt,
          );

    final quality = pronunciationScore != null
        ? _scheduler.qualityFromPronunciation(pronunciationScore)
        : _scheduler.qualityFromOutcome(
            correct: correct,
            attempts: attempts,
            responseTime: responseTime,
          );
    final next = _scheduler.review(priorSrs, quality, now: now);

    final companion = LocalItemStatesCompanion(
      learnerId: Value(learnerId),
      itemId: Value(item.id),
      correctCount:
          Value((prior?.correctCount ?? 0) + (correct ? 1 : 0)),
      incorrectCount:
          Value((prior?.incorrectCount ?? 0) + (correct ? 0 : 1)),
      attempts: Value((prior?.attempts ?? 0) + attempts),
      lastResponseMs: Value(responseTime?.inMilliseconds),
      pronunciationScore: pronunciationScore != null
          ? Value(pronunciationScore)
          : const Value.absent(),
      ease: Value(next.ease),
      intervalDays: Value(next.intervalDays),
      repetitions: Value(next.repetitions),
      dueAt: Value(next.dueAt),
      updatedAt: Value(now),
      synced: const Value(false),
    );

    await _db.upsertState(companion);

    // Best-effort push; failure just leaves it in the outbox for later.
    await _trySync(learnerId, item.id);

    final updated = await _db.statesForItems(learnerId, [item.id]);
    return updated.first;
  }

  /// Pushes any pending (unsynced) rows for [learnerId]. Call on reconnect.
  @override
  Future<int> syncPending(String learnerId) async {
    final pending = await _db.unsynced(learnerId);
    var synced = 0;
    for (final row in pending) {
      if (await _push(row)) {
        await _db.markSynced(learnerId, row.itemId);
        synced++;
      }
    }
    return synced;
  }

  Future<void> _trySync(String learnerId, String itemId) async {
    final rows = await _db.statesForItems(learnerId, [itemId]);
    if (rows.isEmpty) return;
    if (await _push(rows.first)) {
      await _db.markSynced(learnerId, itemId);
    }
  }

  Future<bool> _push(LocalItemState row) async {
    try {
      await _client.from('learner_item_states').upsert({
        'learner_id': row.learnerId,
        'item_id': row.itemId,
        'correct_count': row.correctCount,
        'incorrect_count': row.incorrectCount,
        'attempts': row.attempts,
        'last_response_ms': row.lastResponseMs,
        'pronunciation_score': row.pronunciationScore,
        'ease': row.ease,
        'interval_days': row.intervalDays,
        'repetitions': row.repetitions,
        'due_at': row.dueAt.toIso8601String(),
        'updated_at': row.updatedAt.toIso8601String(),
      }, onConflict: 'learner_id,item_id');
      return true;
    } catch (_) {
      return false; // offline or transient — stays in outbox
    }
  }
}
