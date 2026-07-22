import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Where the M1 consent gate persists its confirmation -- a narrow
/// interface (not the full [AppDatabase]) so widget tests can fake it
/// without spinning up a real backend, matching AudioService/ResultsSink's
/// existing fake-based testing pattern in this codebase.
abstract class ConsentStore {
  Future<void> setConsentGiven(String learnerId, bool given);
}

/// Where the landing page persists that it's been shown once on this device
/// -- same narrow-interface rationale as [ConsentStore].
abstract class LandingStore {
  Future<void> setHasSeenLanding(String learnerId, bool seen);
}

/// Local SQLite cache of per-learner SRS state (PRD F3 + offline requirement).
///
/// This table is the offline-first source of truth: every result is written
/// here first with [synced] = false, then pushed to Supabase. Unsynced rows act
/// as the outbox queue — they are retried on reconnect, so results are never
/// lost if the device is offline mid-activity.
class LocalItemStates extends Table {
  TextColumn get learnerId => text()();
  TextColumn get itemId => text()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get lastResponseMs => integer().nullable()();
  RealColumn get pronunciationScore => real().nullable()();
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  RealColumn get intervalDays => real().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// False = pending upload to Supabase (outbox).
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {learnerId, itemId};
}

/// M1's "basic screen-time setting" (NFR-parent) and parental-consent gate
/// (NFR-safety) -- per-learner local settings. Screen-time enforcement
/// (actually blocking play past the limit) is out of scope here, this just
/// persists the values a parent sets/confirms.
class LearnerSettings extends Table {
  TextColumn get learnerId => text()();
  IntColumn get dailyLimitMinutes => integer().withDefault(const Constant(30))();

  /// True once a parent/guardian has confirmed the age-gate. Checked before
  /// the first play session; anonymous auth continues underneath either way.
  BoolColumn get consentGiven => boolean().withDefault(const Constant(false))();

  /// M2 NFR-a11y "no-reading" mode: activities hide prompt text and rely on
  /// audio + pictures only, so pre-readers can play with no on-screen text.
  BoolColumn get noReadingMode => boolean().withDefault(const Constant(false))();

  /// True once the landing page (sign up / log in / continue as guest) has
  /// been shown and dismissed once for this device -- gates the '/' route
  /// (see app_router.dart), never shown again after a choice is made.
  BoolColumn get hasSeenLanding => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {learnerId};
}

/// M2 NFR-offline: durable cache of fetched course content, so a lesson the
/// learner has loaded once stays fully playable with no network. One row per
/// course holding the serialized lesson list -- ContentRepository owns the
/// (de)serialization; this table just stores the JSON.
class CachedCourses extends Table {
  TextColumn get courseId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {courseId};
}

@DriftDatabase(tables: [LocalItemStates, LearnerSettings, CachedCourses])
class AppDatabase extends _$AppDatabase implements ConsentStore, LandingStore {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'kids_lang'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(learnerSettings);
          }
          if (from < 3) {
            await m.addColumn(learnerSettings, learnerSettings.consentGiven);
          }
          if (from < 4) {
            await m.addColumn(learnerSettings, learnerSettings.noReadingMode);
            await m.createTable(cachedCourses);
          }
          if (from < 5) {
            await m.addColumn(learnerSettings, learnerSettings.hasSeenLanding);
          }
        },
      );

  /// Insert or replace a learner's state for an item.
  Future<void> upsertState(LocalItemStatesCompanion state) =>
      into(localItemStates).insertOnConflictUpdate(state);

  /// All states for a learner (for the progress view), reactive.
  Stream<List<LocalItemState>> watchStates(String learnerId) =>
      (select(localItemStates)..where((t) => t.learnerId.equals(learnerId)))
          .watch();

  /// States for specific items (for adaptive next-item selection).
  Future<List<LocalItemState>> statesForItems(
    String learnerId,
    List<String> itemIds,
  ) =>
      (select(localItemStates)
            ..where((t) =>
                t.learnerId.equals(learnerId) & t.itemId.isIn(itemIds)))
          .get();

  /// Outbox: rows that still need pushing to Supabase.
  Future<List<LocalItemState>> unsynced(String learnerId) =>
      (select(localItemStates)
            ..where((t) => t.learnerId.equals(learnerId) & t.synced.equals(false)))
          .get();

  Future<void> markSynced(String learnerId, String itemId) =>
      (update(localItemStates)
            ..where((t) =>
                t.learnerId.equals(learnerId) & t.itemId.equals(itemId)))
          .write(const LocalItemStatesCompanion(synced: Value(true)));

  /// Reactive daily screen-time limit for a learner, defaulting to 30 min
  /// when no row exists yet.
  Stream<int> watchDailyLimitMinutes(String learnerId) =>
      (select(learnerSettings)..where((t) => t.learnerId.equals(learnerId)))
          .watchSingleOrNull()
          .map((row) => row?.dailyLimitMinutes ?? 30);

  Future<void> setDailyLimitMinutes(String learnerId, int minutes) =>
      _upsertSettings(learnerId, dailyLimitMinutes: minutes);

  /// Reactive parental-consent status, false when no row exists yet.
  Stream<bool> watchConsentGiven(String learnerId) =>
      (select(learnerSettings)..where((t) => t.learnerId.equals(learnerId)))
          .watchSingleOrNull()
          .map((row) => row?.consentGiven ?? false);

  @override
  Future<void> setConsentGiven(String learnerId, bool given) =>
      _upsertSettings(learnerId, consentGiven: given);

  /// Reactive no-reading-mode flag (M2 NFR-a11y), false when unset.
  Stream<bool> watchNoReadingMode(String learnerId) =>
      (select(learnerSettings)..where((t) => t.learnerId.equals(learnerId)))
          .watchSingleOrNull()
          .map((row) => row?.noReadingMode ?? false);

  Future<void> setNoReadingMode(String learnerId, bool enabled) =>
      _upsertSettings(learnerId, noReadingMode: enabled);

  /// Reactive landing-page-seen flag, false when unset (i.e. the landing
  /// page hasn't been dismissed on this device yet).
  Stream<bool> watchHasSeenLanding(String learnerId) =>
      (select(learnerSettings)..where((t) => t.learnerId.equals(learnerId)))
          .watchSingleOrNull()
          .map((row) => row?.hasSeenLanding ?? false);

  @override
  Future<void> setHasSeenLanding(String learnerId, bool seen) =>
      _upsertSettings(learnerId, hasSeenLanding: seen);

  /// M2 NFR-offline content cache: last-fetched lesson JSON for [courseId].
  Future<String?> cachedCoursePayload(String courseId) async {
    final row = await (select(cachedCourses)
          ..where((t) => t.courseId.equals(courseId)))
        .getSingleOrNull();
    return row?.payload;
  }

  Future<void> cacheCoursePayload(String courseId, String payload) =>
      into(cachedCourses).insertOnConflictUpdate(
        CachedCoursesCompanion(
          courseId: Value(courseId),
          payload: Value(payload),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Merges into the existing row (if any) rather than a plain
  /// insertOnConflictUpdate, so setting one field never clobbers the other.
  Future<void> _upsertSettings(
    String learnerId, {
    int? dailyLimitMinutes,
    bool? consentGiven,
    bool? noReadingMode,
    bool? hasSeenLanding,
  }) async {
    final existing = await (select(learnerSettings)
          ..where((t) => t.learnerId.equals(learnerId)))
        .getSingleOrNull();
    await into(learnerSettings).insertOnConflictUpdate(
      LearnerSettingsCompanion(
        learnerId: Value(learnerId),
        dailyLimitMinutes: Value(dailyLimitMinutes ?? existing?.dailyLimitMinutes ?? 30),
        consentGiven: Value(consentGiven ?? existing?.consentGiven ?? false),
        noReadingMode: Value(noReadingMode ?? existing?.noReadingMode ?? false),
        hasSeenLanding: Value(hasSeenLanding ?? existing?.hasSeenLanding ?? false),
      ),
    );
  }
}
