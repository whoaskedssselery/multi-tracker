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
class GroqApiKey extends _$GroqApiKey {
  @override
  Future<String?> build() => SecureStorageService.instance.groqApiKey;

  Future<void> set(String? value) async {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await SecureStorageService.instance.clearGroqApiKey();
      state = const AsyncData(null);
    } else {
      await SecureStorageService.instance.setGroqApiKey(trimmed);
      state = AsyncData(trimmed);
    }
  }
}
