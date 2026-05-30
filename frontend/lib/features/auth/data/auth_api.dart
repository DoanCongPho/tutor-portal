import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/user.dart';

/// Raw HTTP-level binding to the backend's `internal/auth/routes.go` endpoints.
/// No state, no storage — pure request/response.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<void> registerStart({
    required String phone,
    required String role,
    required String name,
  }) async {
    await _client.postJson(
      '/auth/register/start',
      body: {'phone': phone, 'role': role, 'name': name},
    );
  }

  Future<AuthTokens> registerVerify({
    required String phone,
    required String code,
  }) async {
    final json = await _client.postJson(
      '/auth/register/verify',
      body: {'phone': phone, 'code': code},
    );
    return AuthTokens.fromJson(json);
  }

  Future<void> loginStart(String phone) async {
    await _client.postJson('/auth/login/start', body: {'phone': phone});
  }

  Future<AuthTokens> loginVerify({
    required String phone,
    required String code,
  }) async {
    final json = await _client.postJson(
      '/auth/login/verify',
      body: {'phone': phone, 'code': code},
    );
    return AuthTokens.fromJson(json);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final json = await _client.postJson(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return AuthTokens.fromJson(json);
  }
}

/// Wraps the backend `TokenResponse` from `internal/auth/dto.go`.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresInSeconds,
    required this.refreshExpiresInSeconds,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int accessExpiresInSeconds;
  final int refreshExpiresInSeconds;
  final AppUser user;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        accessExpiresInSeconds:
            (json['access_expires_in_seconds'] as num).toInt(),
        refreshExpiresInSeconds:
            (json['refresh_expires_in_seconds'] as num).toInt(),
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});
