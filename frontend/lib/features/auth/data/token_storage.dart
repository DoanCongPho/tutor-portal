import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../domain/user.dart';

/// Persists the auth tokens and last-known [AppUser] in encrypted storage.
class TokenStorage {
  TokenStorage(this._storage);

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';
  static const _userKey = 'auth.user_json';

  final SecureStorage _storage;

  // Reads are defensive: if a value can't be decrypted (e.g. data left
  // corrupted by an older build's concurrent writes, which surfaces on web as a
  // Web Crypto OperationError), treat it as absent rather than throwing. That
  // way the user is seen as logged-out and re-authenticates cleanly instead of
  // the app blowing up mid-request.
  Future<String?> readAccessToken() => _readOrNull(_accessKey);
  Future<String?> readRefreshToken() => _readOrNull(_refreshKey);

  Future<String?> _readOrNull(String key) async {
    try {
      return await _storage.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> readUser() async {
    final raw = await _readOrNull(_userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required AppUser user,
  }) async {
    // Writes are intentionally sequential, not Future.wait. On web,
    // flutter_secure_storage encrypts every value with a single AES-GCM key it
    // lazily creates in localStorage; concurrent first-time writes race to
    // create that key and clobber each other, leaving some values encrypted
    // with a key that no longer matches. Reading those back later throws a Web
    // Crypto OperationError. Serializing the writes lets the first one create
    // the key and the rest reuse it.
    await _storage.write(_accessKey, accessToken);
    await _storage.write(_refreshKey, refreshToken);
    await _storage.write(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
    await _storage.delete(_userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});
