import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/user.dart';

/// Raw HTTP-level binding to the backend's `internal/auth/routes.go` endpoints.
/// No state, no storage — pure request/response.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Step one of email signup: the backend stashes a pending registration and
  /// emails an OTP. Returns nothing — no tokens are issued until [verifyRegistration].
  /// [phone] is optional contact info and is omitted from the payload when empty.
  Future<void> startRegistration({
    required String email,
    required String role,
    required String name,
    required String password,
    String? phone,
  }) async {
    await _client.postJson(
      '/auth/register',
      body: {
        'email': email,
        'role': role,
        'name': name,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  /// Step two: confirm the emailed OTP and receive the token pair for the new account.
  Future<AuthTokens> verifyRegistration({
    required String email,
    required String code,
  }) async {
    final json = await _client.postJson(
      '/auth/register/verify',
      body: {'email': email, 'code': code},
    );
    return AuthTokens.fromJson(json);
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
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

  /// Verifies a Google ID token. Returns either issued tokens (an existing or
  /// email-linked account) or a registration token requiring role selection (a
  /// brand-new account) — see [GoogleLoginResult].
  Future<GoogleLoginResult> googleLogin(String idToken) async {
    final json = await _client.postJson(
      '/auth/google',
      body: {'id_token': idToken},
    );
    return GoogleLoginResult.fromJson(json);
  }

  /// Completes first-time Google sign-up: creates the account with the chosen
  /// role and returns its token pair.
  Future<AuthTokens> completeGoogleRegistration({
    required String registrationToken,
    required String role,
  }) async {
    final json = await _client.postJson(
      '/auth/google/complete',
      body: {'registration_token': registrationToken, 'role': role},
    );
    return AuthTokens.fromJson(json);
  }
}

/// Wraps the backend `GoogleLoginResponse` from `internal/auth/dto.go`, which is
/// one of two shapes: a returning/linked user carries [tokens] (needsRole
/// false); a brand-new user carries [registrationToken] (needsRole true) and the
/// client must collect a role and call [AuthApi.completeGoogleRegistration].
class GoogleLoginResult {
  const GoogleLoginResult({
    required this.needsRole,
    this.registrationToken,
    this.tokens,
  });

  final bool needsRole;
  final String? registrationToken;
  final AuthTokens? tokens;

  factory GoogleLoginResult.fromJson(Map<String, dynamic> json) {
    final auth = json['auth'];
    return GoogleLoginResult(
      needsRole: json['needs_role'] as bool? ?? false,
      registrationToken: json['registration_token'] as String?,
      tokens: auth == null
          ? null
          : AuthTokens.fromJson(auth as Map<String, dynamic>),
    );
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
