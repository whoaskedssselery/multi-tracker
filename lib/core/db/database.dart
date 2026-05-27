// ignore_for_file: type=lint
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
  int get schemaVersion => 2;

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

  Future<int> addWorkoutTemplate(String name) =>
      into(workoutTemplateTable)
          .insert(WorkoutTemplateTableCompanion.insert(name: name));

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

  Future<void> clearChatHistory() => delete(chatMessageTable).go();

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
