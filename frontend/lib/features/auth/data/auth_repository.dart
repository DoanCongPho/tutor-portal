import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_api.dart';
import 'token_storage.dart';

/// Single point of truth the rest of the app talks to for auth. Combines
/// [AuthApi] (HTTP) and [TokenStorage] (persistence) so the controller layer
/// doesn't have to coordinate them.
class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage storage})
      : _api = api,
        _storage = storage;

  final AuthApi _api;
  final TokenStorage _storage;

  Future<AppUser?> currentUser() => _storage.readUser();

  Future<String?> currentAccessToken() => _storage.readAccessToken();

  /// Begins email signup. Triggers the backend to email an OTP; no session is
  /// created until [verifyRegistration] succeeds. [phone] is optional contact info.
  Future<void> startRegistration({
    required String email,
    required String role,
    required String name,
    required String password,
    String? phone,
  }) {
    return _api.startRegistration(
      email: email,
      role: role,
      name: name,
      password: password,
      phone: phone,
    );
  }

  /// Completes email signup with the OTP. On success the new account is logged
  /// in and its tokens persisted.
  Future<AppUser> verifyRegistration({
    required String email,
    required String code,
  }) async {
    final tokens = await _api.verifyRegistration(email: email, code: code);
    await _persist(tokens);
    return tokens.user;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _api.login(email: email, password: password);
    await _persist(tokens);
    return tokens.user;
  }

  /// Exchanges the persisted refresh token for a new pair. Returns the
  /// refreshed user on success and clears storage on failure (caller should
  /// treat that as a logout).
  Future<AppUser?> refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final tokens = await _api.refresh(refreshToken);
      await _persist(tokens);
      return tokens.user;
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> logout() => _storage.clear();

  Future<void> _persist(AuthTokens tokens) => _storage.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        user: tokens.user,
      );
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});
