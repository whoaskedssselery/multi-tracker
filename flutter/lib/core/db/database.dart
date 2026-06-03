// ignore_for_file: type=lint
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ─────────────────────────────────────────────────────────────
// Tables
// ─────────────────────────────────────────────────────────────

/// Singleton user profile (always id = 1)
class ProfileTable extends Table {
  @override
  String get tableName => 'profile';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  DateTimeColumn get birthDate => dateTime().nullable()();
  IntColumn get heightCm => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()();
  TextColumn get units => text().withDefault(const Constant('kg'))(); // 'kg' | 'lbs'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Singleton app preferences (always id = 1)
class AppPreferencesTable extends Table {
  @override
  String get tableName => 'app_preferences';

  IntColumn get id => integer().autoIncrement()();
  // 'light' | 'dark' | 'system'
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  // 'llama-3.3-70b-versatile' | 'llama-3.1-8b-instant' | 'mixtral-8x7b-32768'
  TextColumn get aiModel => text().withDefault(const Constant('llama-3.3-70b-versatile'))();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// User goals (e.g. "Lose to 78 kg", "Deadlift 140 kg")
class GoalTable extends Table {
  @override
  String get tableName => 'goals';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  RealColumn get startValue => real()();
  RealColumn get currentValue => real()();
  RealColumn get targetValue => real()();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Daily weight log
class WeightEntryTable extends Table {
  @override
  String get tableName => 'weight_entries';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();  // stored as midnight UTC
  RealColumn get value => real()();        // in user units
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Workout program template (Push, Pull, Legs, …)
class WorkoutTemplateTable extends Table {
  @override
  String get tableName => 'workout_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF6B8F71))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Exercise within a workout template
class ExerciseTemplateTable extends Table {
  @override
  String get tableName => 'exercise_templates';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutTemplateId => integer().references(WorkoutTemplateTable, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get defaultSetsJson => text().withDefault(const Constant('[]'))();
  // JSON: [{"weight": 80.0, "reps": 8}, …] — last known default
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Weekly schedule: which workout goes on which day
class ScheduleSlotTable extends Table {
  @override
  String get tableName => 'schedule_slots';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutTemplateId => integer().references(WorkoutTemplateTable, #id)();
  IntColumn get dayOfWeek => integer()(); // 1=Mon … 7=Sun (ISO 8601)
}

/// Individual set logged for an exercise on a date
class SetEntryTable extends Table {
  @override
  String get tableName => 'set_entries';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseTemplateId => integer().references(ExerciseTemplateTable, #id)();
  DateTimeColumn get date => dateTime()(); // day of the session
  IntColumn get setIndex => integer()();   // 0-based within the session
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Freeform note attached to a workout session on a specific date
class WorkoutNoteTable extends Table {
  @override
  String get tableName => 'workout_notes';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutTemplateId => integer().references(WorkoutTemplateTable, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cached AI analysis verdict for an exercise
class AiAnalysisTable extends Table {
  @override
  String get tableName => 'ai_analyses';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseTemplateId => integer().references(ExerciseTemplateTable, #id)();
  DateTimeColumn get date => dateTime()();
  // 'progress' | 'plateau' | 'regress' | 'loading'
  TextColumn get verdict => text()();
  TextColumn get explanation => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Task item with optional recurrence and notifications
class TaskItemTable extends Table {
  @override
  String get tableName => 'task_items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get body => text()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get notifyAt => dateTime().nullable()();
  // 'none' | 'daily' | 'weekly' | 'weekdays' | 'monthly'
  TextColumn get recurrence => text().withDefault(const Constant('none'))();
  IntColumn get parentRecurringId => integer().nullable()();
  // 'none' | 'low' | 'mid' | 'high'
  TextColumn get priority => text().withDefault(const Constant('none'))();
  TextColumn get group => text().withDefault(const Constant('none'))();
  // 'today' | 'tomorrow' | 'week' | 'later' | 'none'
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get notificationId => integer().nullable()(); // for cancel
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Markdown note
class NoteItemTable extends Table {
  @override
  String get tableName => 'note_items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// AI chat messages
class ChatMessageTable extends Table {
  @override
  String get tableName => 'chat_messages';

  IntColumn get id => integer().autoIncrement()();
  // 'user' | 'assistant'
  TextColumn get role => text()();
  TextColumn get content => text()();
  // 'all' | 'train' | 'weight' | 'tasks'
  TextColumn get contextFilter => text().withDefault(const Constant('all'))();
  // JSON array of cited references
  TextColumn get citedRefsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────
// Database
// ─────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  ProfileTable,
  AppPreferencesTable,
  GoalTable,
  WeightEntryTable,
  WorkoutTemplateTable,
  ExerciseTemplateTable,
  ScheduleSlotTable,
  SetEntryTable,
  WorkoutNoteTable,
  AiAnalysisTable,
  TaskItemTable,
  NoteItemTable,
  ChatMessageTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultProfile();
      await _seedDefaultPreferences();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(appPreferencesTable);
        await _seedDefaultPreferences();
      }
      if (from < 3) {
        await m.addColumn(workoutTemplateTable, workoutTemplateTable.color);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _seedDefaultProfile() async {
    await into(profileTable).insert(
      ProfileTableCompanion.insert(
        name: 'User',
        units: const Value('kg'),
      ),
    );
  }

  Future<void> _seedDefaultPreferences() async {
    await into(appPreferencesTable).insert(
      AppPreferencesTableCompanion.insert(),
    );
  }

  // ── Profile DAO ──────────────────────────────────────────────

  Stream<ProfileTableData?> watchProfile() =>
      (select(profileTable)..where((t) => t.id.equals(1)))
          .watchSingleOrNull();

  Future<void> upsertProfile(ProfileTableCompanion companion) =>
      (update(profileTable)..where((t) => t.id.equals(1)))
          .write(companion.copyWith(updatedAt: Value(DateTime.now())));

  // ── Preferences DAO ─────────────────────────────────────────

  Stream<AppPreferencesTableData?> watchPreferences() =>
      (select(appPreferencesTable)..where((t) => t.id.equals(1)))
          .watchSingleOrNull();

  Future<void> upsertPreferences(AppPreferencesTableCompanion companion) =>
      (update(appPreferencesTable)..where((t) => t.id.equals(1)))
          .write(companion.copyWith(updatedAt: Value(DateTime.now())));

  // ── Weight DAO ───────────────────────────────────────────────────────────

  /// Stream of weight entries newest-first, capped at [limit] rows.
  Stream<List<WeightEntryTableData>> watchWeightEntries(
          {int limit = 366}) =>
      (select(weightEntryTable)
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt), // tiebreaker for same-day entries
            ])
            ..limit(limit))
          .watch();

  Future<void> addWeightEntry({
    required double value,
    required DateTime date,
    String? note,
  }) =>
      into(weightEntryTable).insert(
        WeightEntryTableCompanion.insert(
          value: value,
          date: date,
          note: Value(note),
        ),
      );

  Future<void> deleteWeightEntry(int id) =>
      (delete(weightEntryTable)..where((t) => t.id.equals(id))).go();

  // ── Tasks DAO ────────────────────────────────────────────────────────────

  /// All tasks, active first, then by creation time.
  Stream<List<TaskItemTableData>> watchAllTasks() =>
      (select(taskItemTable)
            ..orderBy([
              (t) => OrderingTerm(expression: t.isDone),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  Future<int> addTask({
    required String body,
    String group = 'none',
    String priority = 'none',
    DateTime? notifyAt,
  }) =>
      into(taskItemTable).insert(
        TaskItemTableCompanion.insert(
          body: body,
          group: Value(group),
          priority: Value(priority),
          notifyAt: Value(notifyAt),
        ),
      );

  Future<void> setTaskNotificationId(int id, int? notifId) =>
      (update(taskItemTable)..where((t) => t.id.equals(id))).write(
        TaskItemTableCompanion(notificationId: Value(notifId)),
      );

  Future<void> toggleTaskDone(int id, {required bool done}) =>
      (update(taskItemTable)..where((t) => t.id.equals(id))).write(
        TaskItemTableCompanion(
          isDone: Value(done),
          completedAt: Value(done ? DateTime.now() : null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateTask(
    int id, {
    String? body,
    String? group,
    String? priority,
    DateTime? notifyAt,
    bool clearNotifyAt = false,
  }) =>
      (update(taskItemTable)..where((t) => t.id.equals(id))).write(
        TaskItemTableCompanion(
          body: body != null ? Value(body) : const Value.absent(),
          group: group != null ? Value(group) : const Value.absent(),
          priority: priority != null ? Value(priority) : const Value.absent(),
          notifyAt: clearNotifyAt
              ? const Value(null)
              : notifyAt != null
                  ? Value(notifyAt)
                  : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteTask(int id) =>
      (delete(taskItemTable)..where((t) => t.id.equals(id))).go();

  // ── Workout DAO ──────────────────────────────────────────────────────────

  Stream<List<WorkoutTemplateTableData>> watchWorkoutTemplates() =>
      (select(workoutTemplateTable)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Stream<List<ExerciseTemplateTableData>> watchExercisesForTemplate(
          int templateId) =>
      (select(exerciseTemplateTable)
            ..where((t) => t.workoutTemplateId.equals(templateId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Stream<List<ScheduleSlotTableData>> watchScheduleSlots() =>
      select(scheduleSlotTable).watch();

  /// Stream of midnight-local DateTimes within [from]..[to] that have logged sets.
  Stream<Set<DateTime>> watchLoggedDates(
          {required DateTime from, required DateTime to}) =>
      (select(setEntryTable)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(from) &
                t.date.isSmallerOrEqualValue(to)))
          .watch()
          .map((rows) => {
                for (final r in rows)
                  DateTime(r.date.year, r.date.month, r.date.day)
              });

  /// Summary string of the last logged sets for [exerciseId], e.g. "80×8 · 80×8".
  Future<String> getLastSetsString(int exerciseId) async {
    final rows = await (select(setEntryTable)
          ..where((t) => t.exerciseTemplateId.equals(exerciseId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.setIndex),
          ]))
        .get();
    if (rows.isEmpty) return '';
    final lastDate = rows.first.date;
    return rows
        .where((r) =>
            r.date.year == lastDate.year &&
            r.date.month == lastDate.month &&
            r.date.day == lastDate.day)
        .map((s) {
          final w = s.weightKg == s.weightKg.roundToDouble()
              ? s.weightKg.toInt().toString()
              : s.weightKg.toStringAsFixed(1);
          return '${w}×${s.reps}';
        })
        .join(' · ');
  }

  Future<int> addWorkoutTemplate(String name, {int color = 0xFF6B8F71}) =>
      into(workoutTemplateTable).insert(
          WorkoutTemplateTableCompanion.insert(
              name: name, color: Value(color)));

  Future<void> updateWorkoutTemplate(int id,
      {String? name, int? color}) async {
    await (update(workoutTemplateTable)..where((t) => t.id.equals(id))).write(
      WorkoutTemplateTableCompanion(
        name: name == null ? const Value.absent() : Value(name),
        color: color == null ? const Value.absent() : Value(color),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Reconciles a template's exercises with [exs] (id==null → insert,
  /// id!=null → update, existing-but-absent → delete with its set log).
  /// Each exercise stores [sets] empty rows of [reps] in defaultSetsJson.
  Future<void> setTemplateExercises(
      int templateId,
      List<({int? id, String name, int sets, int reps})> exs) async {
    final existing = await (select(exerciseTemplateTable)
          ..where((t) => t.workoutTemplateId.equals(templateId)))
        .get();
    final keepIds = exs.where((e) => e.id != null).map((e) => e.id).toSet();
    for (final ex in existing) {
      if (!keepIds.contains(ex.id)) {
        await (delete(setEntryTable)
              ..where((t) => t.exerciseTemplateId.equals(ex.id)))
            .go();
        await (delete(exerciseTemplateTable)..where((t) => t.id.equals(ex.id)))
            .go();
      }
    }
    for (var i = 0; i < exs.length; i++) {
      final e = exs[i];
      final n = e.sets < 1 ? 1 : e.sets;
      final setsJson = jsonEncode(
          List.generate(n, (_) => {'weight': 0.0, 'reps': e.reps}));
      if (e.id != null) {
        await (update(exerciseTemplateTable)..where((t) => t.id.equals(e.id!)))
            .write(ExerciseTemplateTableCompanion(
          name: Value(e.name),
          sortOrder: Value(i),
          defaultSetsJson: Value(setsJson),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        await into(exerciseTemplateTable).insert(
          ExerciseTemplateTableCompanion.insert(
            workoutTemplateId: templateId,
            name: e.name,
            sortOrder: Value(i),
            defaultSetsJson: Value(setsJson),
          ),
        );
      }
    }
  }

  /// Deletes template and all its exercises + their set entries.
  Future<void> deleteWorkoutTemplate(int id) async {
    final exs = await (select(exerciseTemplateTable)
          ..where((t) => t.workoutTemplateId.equals(id)))
        .get();
    for (final ex in exs) {
      await (delete(setEntryTable)
            ..where((t) => t.exerciseTemplateId.equals(ex.id)))
          .go();
    }
    await (delete(exerciseTemplateTable)
          ..where((t) => t.workoutTemplateId.equals(id)))
        .go();
    await (delete(scheduleSlotTable)
          ..where((t) => t.workoutTemplateId.equals(id)))
        .go();
    await (delete(workoutTemplateTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addExercise(
          {required int templateId, required String name}) async {
    final count = await (select(exerciseTemplateTable)
          ..where((t) => t.workoutTemplateId.equals(templateId)))
        .get();
    await into(exerciseTemplateTable).insert(
      ExerciseTemplateTableCompanion.insert(
        workoutTemplateId: templateId,
        name: name,
        sortOrder: Value(count.length),
      ),
    );
  }

  Future<void> deleteExercise(int id) async {
    await (delete(setEntryTable)
          ..where((t) => t.exerciseTemplateId.equals(id)))
        .go();
    await (delete(exerciseTemplateTable)..where((t) => t.id.equals(id))).go();
  }

  /// Sets workout [templateId] for [dayOfWeek] (1=Mon..7=Sun).
  /// Pass null to clear (mark as rest).
  Future<void> setScheduleSlot(int dayOfWeek, int? templateId) async {
    await (delete(scheduleSlotTable)
          ..where((t) => t.dayOfWeek.equals(dayOfWeek)))
        .go();
    if (templateId != null) {
      await into(scheduleSlotTable).insert(
        ScheduleSlotTableCompanion.insert(
          workoutTemplateId: templateId,
          dayOfWeek: dayOfWeek,
        ),
      );
    }
  }

  // ── Goals DAO ────────────────────────────────────────────────────────────

  Stream<List<GoalTableData>> watchGoals() =>
      (select(goalTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> addGoal({
    required String label,
    required double startValue,
    required double currentValue,
    required double targetValue,
    String unit = 'kg',
  }) =>
      into(goalTable).insert(GoalTableCompanion.insert(
        label: label,
        startValue: startValue,
        currentValue: currentValue,
        targetValue: targetValue,
        unit: Value(unit),
      ));

  Future<void> updateGoal(
    int id, {
    String? label,
    double? startValue,
    double? currentValue,
    double? targetValue,
    String? unit,
  }) =>
      (update(goalTable)..where((t) => t.id.equals(id))).write(
        GoalTableCompanion(
          label: label != null ? Value(label) : const Value.absent(),
          startValue:
              startValue != null ? Value(startValue) : const Value.absent(),
          currentValue:
              currentValue != null ? Value(currentValue) : const Value.absent(),
          targetValue:
              targetValue != null ? Value(targetValue) : const Value.absent(),
          unit: unit != null ? Value(unit) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteGoal(int id) =>
      (delete(goalTable)..where((t) => t.id.equals(id))).go();

  // ── Workout dates (for streaks) ──────────────────────────────────────────

  Stream<List<DateTime>> watchWorkoutDates() =>
      select(setEntryTable).watch().map((rows) {
        final seen = <String>{};
        final result = <DateTime>[];
        for (final r in rows) {
          final key =
              '${r.date.year}-${r.date.month}-${r.date.day}';
          if (seen.add(key)) {
            result.add(DateTime(r.date.year, r.date.month, r.date.day));
          }
        }
        result.sort((a, b) => b.compareTo(a)); // desc
        return result;
      });

  // ── Chat DAO ─────────────────────────────────────────────────────────────

  Stream<List<ChatMessageTableData>> watchChatMessages() =>
      (select(chatMessageTable)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Streams only messages with the given [filter] ('all' | 'train' | 'weight' | 'tasks').
  Stream<List<ChatMessageTableData>> watchChatMessagesForFilter(
          String filter) =>
      (select(chatMessageTable)
            ..where((t) => t.contextFilter.equals(filter))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> addChatMessage({
    required String role,
    required String content,
    String contextFilter = 'all',
  }) =>
      into(chatMessageTable).insert(
        ChatMessageTableCompanion.insert(
          role: role,
          content: content,
          contextFilter: Value(contextFilter),
        ),
      );

  Future<List<ChatMessageTableData>> getLastChatMessages({int limit = 20}) async {
    final rows = await (select(chatMessageTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.reversed.toList();
  }

  /// Returns the last [limit] messages for the given [filter], chronological order.
  Future<List<ChatMessageTableData>> getLastChatMessagesForFilter(
    String filter, {
    int limit = 20,
  }) async {
    final rows = await (select(chatMessageTable)
          ..where((t) => t.contextFilter.equals(filter))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.reversed.toList();
  }

  Future<void> clearChatHistory() => delete(chatMessageTable).go();

  /// Clears only messages belonging to [filter].
  Future<void> clearChatHistoryForFilter(String filter) =>
      (delete(chatMessageTable)
            ..where((t) => t.contextFilter.equals(filter)))
          .go();

  // ── Notes DAO ────────────────────────────────────────────────────────────

  Stream<List<NoteItemTableData>> watchNotes() =>
      (select(noteItemTable)
            ..orderBy([
              (t) => OrderingTerm.desc(t.isPinned),
              (t) => OrderingTerm.desc(t.updatedAt),
            ]))
          .watch();

  Future<int> addNote({String title = '', String body = ''}) =>
      into(noteItemTable).insert(NoteItemTableCompanion.insert(
        title: title.isEmpty ? 'Без названия' : title,
        body: Value(body),
      ));

  Future<void> updateNote(
    int id, {
    String? title,
    String? body,
    bool? isPinned,
  }) =>
      (update(noteItemTable)..where((t) => t.id.equals(id))).write(
        NoteItemTableCompanion(
          title:    title    != null ? Value(title)    : const Value.absent(),
          body:     body     != null ? Value(body)     : const Value.absent(),
          isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteNote(int id) =>
      (delete(noteItemTable)..where((t) => t.id.equals(id))).go();

  // ── Export / Reset DAO ───────────────────────────────────────────────────

  Future<void> clearAllData() async {
    await delete(chatMessageTable).go();
    await delete(setEntryTable).go();
    await delete(scheduleSlotTable).go();
    await delete(exerciseTemplateTable).go();
    await delete(workoutTemplateTable).go();
    await delete(noteItemTable).go();
    await delete(taskItemTable).go();
    await delete(goalTable).go();
    await delete(weightEntryTable).go();
    // Profile and preferences are intentionally kept.
  }

  /// Full local wipe used on sign-out: clears EVERY table (incl. profile &
  /// preferences), resets autoincrement counters, then re-seeds fresh default
  /// profile + preferences so the app's singletons (id = 1) still exist.
  Future<void> wipeLocal() async {
    await transaction(() async {
      await delete(chatMessageTable).go();
      await delete(aiAnalysisTable).go();
      await delete(workoutNoteTable).go();
      await delete(setEntryTable).go();
      await delete(scheduleSlotTable).go();
      await delete(exerciseTemplateTable).go();
      await delete(workoutTemplateTable).go();
      await delete(noteItemTable).go();
      await delete(taskItemTable).go();
      await delete(goalTable).go();
      await delete(weightEntryTable).go();
      await delete(appPreferencesTable).go();
      await delete(profileTable).go();
      // Reset autoincrement so fresh inserts start at id = 1 again.
      await customStatement('DELETE FROM sqlite_sequence');
      await _seedDefaultProfile();
      await _seedDefaultPreferences();
    });
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final weights   = await select(weightEntryTable).get();
    final tasks     = await select(taskItemTable).get();
    final notes     = await select(noteItemTable).get();
    final goals     = await select(goalTable).get();
    final templates = await (select(workoutTemplateTable)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    final workoutsJson = <Map<String, dynamic>>[];
    for (final tmpl in templates) {
      final exercises = await (select(exerciseTemplateTable)
            ..where((e) => e.workoutTemplateId.equals(tmpl.id))
            ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
          .get();
      final exList = <Map<String, dynamic>>[];
      for (final ex in exercises) {
        final sets = await (select(setEntryTable)
              ..where((s) => s.exerciseTemplateId.equals(ex.id))
              ..orderBy([
                (s) => OrderingTerm.desc(s.date),
                (s) => OrderingTerm.asc(s.setIndex),
              ]))
            .get();
        exList.add({
          'name': ex.name,
          'sets': sets.map((s) => {
                'date': s.date.toIso8601String(),
                'setIndex': s.setIndex,
                'weightKg': s.weightKg,
                'reps': s.reps,
              }).toList(),
        });
      }
      workoutsJson.add({'name': tmpl.name, 'exercises': exList});
    }

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'weight': weights.map((w) => {
            'date': w.date.toIso8601String(),
            'value': w.value,
            'note': w.note,
          }).toList(),
      'tasks': tasks.map((t) => {
            'body': t.body,
            'group': t.group,
            'priority': t.priority,
            'isDone': t.isDone,
            'completedAt': t.completedAt?.toIso8601String(),
            'createdAt': t.createdAt.toIso8601String(),
          }).toList(),
      'notes': notes.map((n) => {
            'title': n.title,
            'body': n.body,
            'isPinned': n.isPinned,
            'createdAt': n.createdAt.toIso8601String(),
            'updatedAt': n.updatedAt.toIso8601String(),
          }).toList(),
      'goals': goals.map((g) => {
            'label': g.label,
            'startValue': g.startValue,
            'currentValue': g.currentValue,
            'targetValue': g.targetValue,
            'unit': g.unit,
          }).toList(),
      'workouts': workoutsJson,
    };
  }

  // ── Full lossless snapshot (cloud sync / backup) ──────────────────────────
  //
  // Unlike exportAllData() (human-readable, lossy), these capture EVERY table
  // and column with primary keys intact, so importing reproduces the database
  // byte-for-byte. Used by the Supabase sync layer and JSON import.

  static const int snapshotVersion = 1;

  /// True if the local DB holds any real user data (ignores the always-present
  /// singleton profile / preferences rows). Used by sync to avoid letting an
  /// empty cloud snapshot overwrite a populated device.
  Future<bool> hasUserData() async {
    final res = await customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM weight_entries) + '
      '(SELECT COUNT(*) FROM task_items) + '
      '(SELECT COUNT(*) FROM note_items) + '
      '(SELECT COUNT(*) FROM goals) + '
      '(SELECT COUNT(*) FROM workout_templates) + '
      '(SELECT COUNT(*) FROM exercise_templates) + '
      '(SELECT COUNT(*) FROM set_entries) AS c',
    ).getSingle();
    return (res.data['c'] as int) > 0;
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    return {
      'snapshotVersion': snapshotVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': {
        'profile':
            (await select(profileTable).get()).map((r) => r.toJson()).toList(),
        'app_preferences': (await select(appPreferencesTable).get())
            .map((r) => r.toJson())
            .toList(),
        'goals':
            (await select(goalTable).get()).map((r) => r.toJson()).toList(),
        'weight_entries': (await select(weightEntryTable).get())
            .map((r) => r.toJson())
            .toList(),
        'workout_templates': (await select(workoutTemplateTable).get())
            .map((r) => r.toJson())
            .toList(),
        'exercise_templates': (await select(exerciseTemplateTable).get())
            .map((r) => r.toJson())
            .toList(),
        'schedule_slots': (await select(scheduleSlotTable).get())
            .map((r) => r.toJson())
            .toList(),
        'set_entries': (await select(setEntryTable).get())
            .map((r) => r.toJson())
            .toList(),
        'workout_notes': (await select(workoutNoteTable).get())
            .map((r) => r.toJson())
            .toList(),
        'ai_analyses': (await select(aiAnalysisTable).get())
            .map((r) => r.toJson())
            .toList(),
        'task_items': (await select(taskItemTable).get())
            .map((r) => r.toJson())
            .toList(),
        'note_items': (await select(noteItemTable).get())
            .map((r) => r.toJson())
            .toList(),
        'chat_messages': (await select(chatMessageTable).get())
            .map((r) => r.toJson())
            .toList(),
      },
    };
  }

  /// Replaces the entire database with [snapshot]. Atomic (transaction).
  /// Rows are deleted children→parents and re-inserted parents→children so
  /// foreign-key constraints stay satisfied without toggling PRAGMA.
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    final tables =
        ((snapshot['tables'] as Map?) ?? const {}).cast<String, dynamic>();
    List<Map<String, dynamic>> rows(String key) =>
        ((tables[key] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    await transaction(() async {
      // Delete children → parents.
      await delete(chatMessageTable).go();
      await delete(aiAnalysisTable).go();
      await delete(workoutNoteTable).go();
      await delete(setEntryTable).go();
      await delete(scheduleSlotTable).go();
      await delete(exerciseTemplateTable).go();
      await delete(workoutTemplateTable).go();
      await delete(noteItemTable).go();
      await delete(taskItemTable).go();
      await delete(goalTable).go();
      await delete(weightEntryTable).go();
      await delete(appPreferencesTable).go();
      await delete(profileTable).go();

      // Insert parents → children.
      for (final j in rows('profile')) {
        await into(profileTable)
            .insert(ProfileTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('app_preferences')) {
        await into(appPreferencesTable).insert(
            AppPreferencesTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('goals')) {
        await into(goalTable)
            .insert(GoalTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('weight_entries')) {
        await into(weightEntryTable).insert(
            WeightEntryTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('workout_templates')) {
        await into(workoutTemplateTable).insert(
            WorkoutTemplateTableData.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('exercise_templates')) {
        await into(exerciseTemplateTable).insert(
            ExerciseTemplateTableData.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('schedule_slots')) {
        await into(scheduleSlotTable).insert(
            ScheduleSlotTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('set_entries')) {
        await into(setEntryTable).insert(
            SetEntryTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('workout_notes')) {
        await into(workoutNoteTable).insert(
            WorkoutNoteTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('ai_analyses')) {
        await into(aiAnalysisTable).insert(
            AiAnalysisTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('task_items')) {
        await into(taskItemTable).insert(
            TaskItemTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('note_items')) {
        await into(noteItemTable).insert(
            NoteItemTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('chat_messages')) {
        await into(chatMessageTable).insert(
            ChatMessageTableData.fromJson(j), mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Overwrites all sets for [exerciseId] on [date] with [sets].
  Future<void> logSets({
    required int exerciseId,
    required DateTime date,
    required List<({double weightKg, int reps})> sets,
  }) async {
    final midnight = DateTime(date.year, date.month, date.day);
    await (delete(setEntryTable)
          ..where((t) =>
              t.exerciseTemplateId.equals(exerciseId) &
              t.date.equals(midnight)))
        .go();
    for (var i = 0; i < sets.length; i++) {
      await into(setEntryTable).insert(
        SetEntryTableCompanion.insert(
          exerciseTemplateId: exerciseId,
          date: midnight,
          setIndex: i,
          weightKg: sets[i].weightKg,
          reps: sets[i].reps,
        ),
      );
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'multi_tracker');
}
