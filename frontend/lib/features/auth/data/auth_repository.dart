import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_api.dart';
import 'google_sign_in_service.dart';
import 'token_storage.dart';

/// Single point of truth the rest of the app talks to for auth. Combines
/// [AuthApi] (HTTP) and [TokenStorage] (persistence) so the controller layer
/// doesn't have to coordinate them.
class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorage storage,
    required GoogleSignInService google,
  })  : _api = api,
        _storage = storage,
        _google = google;

  final AuthApi _api;
  final TokenStorage _storage;
  final GoogleSignInService _google;

  // In-memory copies of the live session's tokens. The source of truth for the
  // current session — encrypted storage is only the persistence layer for
  // surviving restarts (and is unreliable on web, where reads can fail to
  // decrypt). Keeping the tokens here means an authed feature never has to read
  // them back from storage mid-session.
  String? _accessToken;
  String? _refreshToken;

  Future<AppUser?> currentUser() => _storage.readUser();

  Future<String?> currentAccessToken() async =>
      _accessToken ?? await _storage.readAccessToken();

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
    final refreshToken = _refreshToken ?? await _storage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final tokens = await _api.refresh(refreshToken);
      await _persist(tokens);
      return tokens.user;
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
      await _storage.clear();
      return null;
    }
  }

  /// Runs native Google sign-in and exchanges the ID token with the backend.
  /// When the result does not need a role the session is already persisted;
  /// otherwise the caller collects a role and calls [completeGoogleRegistration].
  /// Returns null if the user cancelled the Google picker.
  Future<GoogleLoginResult?> signInWithGoogle() async {
    final idToken = await _google.signIn();
    if (idToken == null) return null;
    final result = await _api.googleLogin(idToken);
    if (!result.needsRole && result.tokens != null) {
      await _persist(result.tokens!);
    }
    return result;
  }

  /// Completes first-time Google sign-up once a role is chosen; persists the
  /// new session and returns the user.
  Future<AppUser> completeGoogleRegistration({
    required String registrationToken,
    required String role,
  }) async {
    final tokens = await _api.completeGoogleRegistration(
      registrationToken: registrationToken,
      role: role,
    );
    await _persist(tokens);
    return tokens.user;
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.clear();
  }

  Future<void> _persist(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await _storage.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: tokens.user,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(tokenStorageProvider),
    google: ref.watch(googleSignInServiceProvider),
  );
});
