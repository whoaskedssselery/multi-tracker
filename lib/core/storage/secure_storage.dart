import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Typed keys for secure storage
enum SecureKey {
  geminiApiKey,
}

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  Future<String?> read(SecureKey key) =>
      _storage.read(key: key.name);

  Future<void> write(SecureKey key, String value) =>
      _storage.write(key: key.name, value: value);

  Future<void> delete(SecureKey key) =>
      _storage.delete(key: key.name);

  Future<bool> containsKey(SecureKey key) =>
      _storage.containsKey(key: key.name);

  // ── Convenience typed accessors ───────────────────────────────

  Future<String?> get geminiApiKey => read(SecureKey.geminiApiKey);

  Future<void> setGeminiApiKey(String key) =>
      write(SecureKey.geminiApiKey, key);

  Future<void> clearGeminiApiKey() => delete(SecureKey.geminiApiKey);
}
