import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/audio/audio_service.dart';
import '../core/db/app_database.dart';
import '../core/speech/speech_service.dart';
import '../core/sync/connectivity_sync.dart';
import '../data/content_repository.dart';
import '../data/results_repository.dart';
import '../domain/models/content.dart';

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

/// The seed lesson the slice opens.
final seedLessonProvider = FutureProvider<Lesson>((ref) {
  return ref
      .watch(contentRepositoryProvider)
      .fetchLesson(ContentRepository.seedLessonId);
});

/// Reactive learner progress for the progress view + home badge.
final progressProvider = StreamProvider<List<LocalItemState>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final learnerId = ref.watch(learnerIdProvider);
  return db.watchStates(learnerId);
});

/// Drains the offline outbox on reconnect. Kept alive by watching it from the
/// home page; starts listening to connectivity on creation.
final connectivitySyncProvider = Provider<ConnectivitySync>((ref) {
  final sync = ConnectivitySync(
    results: ref.watch(resultsRepositoryProvider),
    learnerId: () => ref.read(learnerIdProvider),
  );
  sync.start();
  ref.onDispose(sync.dispose);
  return sync;
});
