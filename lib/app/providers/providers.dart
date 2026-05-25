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
class GeminiApiKey extends _$GeminiApiKey {
  @override
  Future<String?> build() => SecureStorageService.instance.geminiApiKey;

  Future<void> set(String? value) async {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await SecureStorageService.instance.clearGeminiApiKey();
      state = const AsyncData(null);
    } else {
      await SecureStorageService.instance.setGeminiApiKey(trimmed);
      state = AsyncData(trimmed);
    }
  }
}
