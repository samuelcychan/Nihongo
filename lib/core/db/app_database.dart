import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

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

@DriftDatabase(tables: [LocalItemStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'kids_lang'));

  @override
  int get schemaVersion => 1;

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
}
