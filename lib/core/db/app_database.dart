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

  @override
  Set<Column> get primaryKey => {learnerId};
}

@DriftDatabase(tables: [LocalItemStates, LearnerSettings])
class AppDatabase extends _$AppDatabase implements ConsentStore {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'kids_lang'));

  @override
  int get schemaVersion => 3;

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

  /// Merges into the existing row (if any) rather than a plain
  /// insertOnConflictUpdate, so setting one field never clobbers the other.
  Future<void> _upsertSettings(
    String learnerId, {
    int? dailyLimitMinutes,
    bool? consentGiven,
  }) async {
    final existing = await (select(learnerSettings)
          ..where((t) => t.learnerId.equals(learnerId)))
        .getSingleOrNull();
    await into(learnerSettings).insertOnConflictUpdate(
      LearnerSettingsCompanion(
        learnerId: Value(learnerId),
        dailyLimitMinutes: Value(dailyLimitMinutes ?? existing?.dailyLimitMinutes ?? 30),
        consentGiven: Value(consentGiven ?? existing?.consentGiven ?? false),
      ),
    );
  }
}
