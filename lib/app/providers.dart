import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/audio/audio_service.dart';
import '../core/db/app_database.dart';
import '../core/speech/speech_service.dart';
import '../core/supabase/app_supabase.dart';
import '../core/sync/connectivity_sync.dart';
import '../data/content_repository.dart';
import '../data/lesson_generator_service.dart';
import '../data/results_repository.dart';
import '../domain/models/content.dart';
import '../features/parent_dashboard/parent_metrics.dart';

/// The active Supabase client (initialized during bootstrap).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Local offline-first database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Audio output (TTS). Overridable in tests.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = TtsAudioService();
  ref.onDispose(service.dispose);
  return service;
});

/// Speech input — stub for the slice (see [SpeechService]).
final speechServiceProvider =
    Provider<SpeechService>((ref) => const UnavailableSpeechService());

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(supabaseClientProvider)),
);

final resultsRepositoryProvider = Provider<ResultsSink>(
  (ref) => ResultsRepository(
    db: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
  ),
);

/// Current learner's id (anonymous auth uid for the slice).
final learnerIdProvider = Provider<String>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser?.id ?? 'anonymous';
});

/// Reactive Supabase auth state — lets widgets rebuild on sign-in/out, e.g.
/// the M0.5 teacher sign-in swapping out the default anonymous session.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// True once the signed-in user is confirmed as a teacher via `profiles.role`.
/// Anonymous sessions have no profile row and resolve to false.
final isTeacherProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null || user.isAnonymous) return false;
  final row = await client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
  return row?['role'] == 'teacher';
});

/// The seed lesson the slice opens.
final seedLessonProvider = FutureProvider<Lesson>((ref) {
  return ref
      .watch(contentRepositoryProvider)
      .fetchLesson(ContentRepository.seedLessonId);
});

/// All real lessons in the published course, in course order -- replaces the
/// lesson map's old hardcoded placeholder node list. Includes both the seed
/// lesson and any AI-generated lessons a teacher has approved (M0.5).
final courseLessonsProvider = FutureProvider<List<Lesson>>((ref) {
  return ref
      .watch(contentRepositoryProvider)
      .fetchCourseLessons(ContentRepository.publishedCourseId);
});

enum LessonStatus { done, current, locked }

class LessonProgress {
  const LessonProgress({required this.lesson, required this.status});
  final Lesson lesson;
  final LessonStatus status;
}

/// Per-lesson pass/current/locked status, derived from real SRS progress: a
/// lesson counts as passed once every item in it has been answered correctly
/// at least once (repetitions >= 1 -- matches finishing one full round, see
/// activity_match_page.dart). The first not-yet-passed lesson in course order
/// is "current"; everything after it is "locked".
final courseProgressProvider = Provider<AsyncValue<List<LessonProgress>>>((ref) {
  final lessonsAsync = ref.watch(courseLessonsProvider);
  final states = ref.watch(progressProvider).value ?? const [];
  final repsByItem = {for (final s in states) s.itemId: s.repetitions};

  bool isPassed(Lesson lesson) =>
      lesson.allItems.isNotEmpty &&
      lesson.allItems.every((item) => (repsByItem[item.id] ?? 0) >= 1);

  return lessonsAsync.whenData((lessons) {
    final result = <LessonProgress>[];
    var currentAssigned = false;
    for (final lesson in lessons) {
      if (isPassed(lesson)) {
        result.add(LessonProgress(lesson: lesson, status: LessonStatus.done));
      } else if (!currentAssigned) {
        result.add(LessonProgress(lesson: lesson, status: LessonStatus.current));
        currentAssigned = true;
      } else {
        result.add(LessonProgress(lesson: lesson, status: LessonStatus.locked));
      }
    }
    return result;
  });
});

/// Reactive learner progress for the progress view + home badge.
final progressProvider = StreamProvider<List<LocalItemState>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final learnerId = ref.watch(learnerIdProvider);
  return db.watchStates(learnerId);
});

/// M0.5 AI Lesson Generator client (calls the `generate-lesson` Edge
/// Function). Real implementation — override with [MockLessonGeneratorService]
/// in widget tests / while the function isn't deployed yet.
final lessonGeneratorServiceProvider = Provider<LessonGeneratorService>(
  (ref) => SupabaseLessonGeneratorService(ref.watch(supabaseClientProvider)),
);

/// M1 NFR-parent: real parent-dashboard aggregates, computed from actual SRS
/// progress + the real course content (see parent_metrics.dart) instead of
/// the placeholder numbers the dashboard used to show.
final parentMetricsProvider = Provider<ParentMetrics>((ref) {
  final states = ref.watch(progressProvider).value ?? const [];
  final lessons = ref.watch(courseLessonsProvider).value ?? const [];
  return computeParentMetrics(states: states, courseLessons: lessons);
});

/// M1's basic screen-time setting: a per-learner daily minutes limit the
/// parent dashboard can show/adjust (defaults to 30 when unset).
final dailyLimitMinutesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final learnerId = ref.watch(learnerIdProvider);
  return db.watchDailyLimitMinutes(learnerId);
});

/// M1 NFR-safety: whether a parent/guardian has confirmed the consent gate
/// yet. Checked before the first play session (see consent_gate_page.dart).
final consentGivenProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final learnerId = ref.watch(learnerIdProvider);
  return db.watchConsentGiven(learnerId);
});

/// Narrow write-only view of [appDatabaseProvider] for the consent gate
/// (see [ConsentStore]) -- lets widget tests fake the write without a real
/// database backend.
final consentStoreProvider = Provider<ConsentStore>((ref) => ref.watch(appDatabaseProvider));

/// Drains the offline outbox on reconnect. Kept alive by watching it from the
/// home page; starts listening to connectivity on creation.
///
/// Guarded on [Env.isConfigured]: without dart-defines (offline/no-backend UI
/// work, and CI's iOS smoke test) there's nothing to sync, and touching
/// [resultsRepositoryProvider]/[supabaseClientProvider] here would throw --
/// `Supabase.instance.client` asserts if `Supabase.initialize` was never
/// called, which would crash every unconditional watcher of this provider.
final connectivitySyncProvider = Provider<ConnectivitySync>((ref) {
  if (!Env.isConfigured) {
    return ConnectivitySync(
      results: _NoopResultsSink(),
      learnerId: () => 'anonymous',
    );
  }
  final sync = ConnectivitySync(
    results: ref.watch(resultsRepositoryProvider),
    learnerId: () => ref.read(learnerIdProvider),
  );
  sync.start();
  ref.onDispose(sync.dispose);
  return sync;
});

class _NoopResultsSink implements ResultsSink {
  @override
  Future<void> recordResult({
    required String learnerId,
    required Item item,
    required bool correct,
    required int attempts,
    Duration? responseTime,
  }) async {}

  @override
  Future<int> syncPending(String learnerId) async => 0;
}
