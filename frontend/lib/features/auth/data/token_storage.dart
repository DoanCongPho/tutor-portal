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

  Future<String?> readAccessToken() => _storage.read(_accessKey);
  Future<String?> readRefreshToken() => _storage.read(_refreshKey);

  Future<AppUser?> readUser() async {
    final raw = await _storage.read(_userKey);
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
    await Future.wait([
      _storage.write(_accessKey, accessToken),
      _storage.write(_refreshKey, refreshToken),
      _storage.write(_userKey, jsonEncode(user.toJson())),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(_accessKey),
      _storage.delete(_refreshKey),
      _storage.delete(_userKey),
    ]);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});
