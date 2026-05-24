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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Seed default data
      await _seedDefaultProfile();
    },
    onUpgrade: (m, from, to) async {
      // Future migrations go here — never lose data
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
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'multi_tracker');
}
