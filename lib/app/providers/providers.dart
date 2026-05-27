import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/db/database.dart';
import '../../core/storage/secure_storage.dart';
import '../../main.dart';

part 'providers.g.dart';

@riverpod
Stream<ProfileTableData?> profile(ProfileRef ref) =>
    ref.watch(dbProvider).watchProfile();

@riverpod
Stream<AppPreferencesTableData?> preferences(PreferencesRef ref) =>
    ref.watch(dbProvider).watchPreferences();

@riverpod
ThemeMode themeMode(ThemeModeRef ref) {
  final prefs = ref.watch(preferencesProvider).valueOrNull;
  return switch (prefs?.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

@riverpod
Stream<List<WeightEntryTableData>> weightEntries(WeightEntriesRef ref) =>
    ref.watch(dbProvider).watchWeightEntries();

@riverpod
Stream<List<TaskItemTableData>> tasks(TasksRef ref) =>
    ref.watch(dbProvider).watchAllTasks();

@riverpod
Stream<List<WorkoutTemplateTableData>> workoutTemplates(
        WorkoutTemplatesRef ref) =>
    ref.watch(dbProvider).watchWorkoutTemplates();

@riverpod
Stream<List<ScheduleSlotTableData>> scheduleSlots(ScheduleSlotsRef ref) =>
    ref.watch(dbProvider).watchScheduleSlots();

@riverpod
Stream<List<ExerciseTemplateTableData>> exercisesForTemplate(
        ExercisesForTemplateRef ref, int templateId) =>
    ref.watch(dbProvider).watchExercisesForTemplate(templateId);

@riverpod
Stream<List<GoalTableData>> goals(GoalsRef ref) =>
    ref.watch(dbProvider).watchGoals();

@riverpod
Stream<List<DateTime>> workoutDates(WorkoutDatesRef ref) =>
    ref.watch(dbProvider).watchWorkoutDates();

@riverpod
Stream<List<ChatMessageTableData>> chatMessages(ChatMessagesRef ref) =>
    ref.watch(dbProvider).watchChatMessages();

@riverpod
Stream<List<ChatMessageTableData>> chatMessagesForFilter(
        ChatMessagesForFilterRef ref, String filter) =>
    ref.watch(dbProvider).watchChatMessagesForFilter(filter);

@riverpod
Stream<List<NoteItemTableData>> notes(NotesRef ref) =>
    ref.watch(dbProvider).watchNotes();

@riverpod
Stream<Set<DateTime>> loggedDates(
        LoggedDatesRef ref, DateTime weekStart) =>
    ref.watch(dbProvider).watchLoggedDates(
      from: weekStart,
      to: weekStart.add(const Duration(days: 6)),
    );

@riverpod
class GroqApiKey extends _$GroqApiKey {
  @override
  Future<String?> build() => SecureStorageService.instance.groqApiKey;

  Future<void> set(String? value) async {
    var trimmed = value?.trim();
    // Strip surrounding quotes that users accidentally paste from .env files
    if (trimmed != null &&
        trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }
    if (trimmed == null || trimmed.isEmpty) {
      await SecureStorageService.instance.clearGroqApiKey();
      state = const AsyncData(null);
    } else {
      await SecureStorageService.instance.setGroqApiKey(trimmed);
      state = AsyncData(trimmed);
    }
  }
}
