import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SecureKey {
  groqApiKey,
}

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  Future<String?> read(SecureKey key) => _storage.read(key: key.name);
  Future<void> write(SecureKey key, String value) =>
      _storage.write(key: key.name, value: value);
  Future<void> delete(SecureKey key) => _storage.delete(key: key.name);

  Future<String?> get groqApiKey => read(SecureKey.groqApiKey);
  Future<void> setGroqApiKey(String key) =>
      write(SecureKey.groqApiKey, key);
  Future<void> clearGroqApiKey() => delete(SecureKey.groqApiKey);
}
