import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key/value persistence for small secrets (the auth tokens + cached user).
///
/// Backend is chosen per platform:
///  - **Mobile/desktop:** [FlutterSecureStorage] — OS-backed encryption
///    (iOS Keychain, Android Keystore-backed EncryptedSharedPreferences). The
///    token is a credential, so it gets real at-rest protection.
///  - **Web:** [SharedPreferences] (browser localStorage, plaintext). The web
///    build of flutter_secure_storage encrypts with a key kept right next to the
///    data in localStorage — so its "encryption" adds little real protection
///    (anything with page/JS access reads both) while its decryption is flaky
///    across reloads (throws "OperationError"). Plain localStorage is the
///    standard, reliable choice for an SPA and avoids that bug.
///
/// Reads tolerate failures: an unreadable value is treated as absent (and
/// dropped) so the app degrades to "logged out" instead of crashing.
class SecureStorage {
  SecureStorage();

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> read(String key) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
      return await _secure.read(key: key);
    } catch (_) {
      try {
        await delete(key);
      } catch (_) {
        // Best effort — nothing more we can do if cleanup also fails.
      }
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    await _secure.delete(key: key);
  }
}

final secureStorageProvider = Provider<SecureStorage>((_) => SecureStorage());
