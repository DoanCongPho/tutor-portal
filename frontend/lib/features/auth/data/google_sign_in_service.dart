import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The Web/server OAuth client id (client_type 3 in google-services.json). The
/// Google ID token is minted with this as its audience, so the Go backend —
/// which verifies against the same id (GOOGLE_OAUTH_CLIENT_ID) — accepts it.
/// Keep the two in sync.
const String kGoogleServerClientId =
    '860812429904-72345i6uiej86722vk1gn9apn32glpg3.apps.googleusercontent.com';

/// Thin wrapper over google_sign_in v7 that yields a Google ID token for the
/// backend to verify. Initialization is lazy and one-shot (initialize() must run
/// once before authenticate()).
class GoogleSignInService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: kGoogleServerClientId,
    );
    _initialized = true;
  }

  /// Triggers the native Google account picker and returns the resulting ID
  /// token, or null if the user cancelled. Throws on unsupported platforms or
  /// when Google returns no ID token.
  Future<String?> signIn() async {
    await _ensureInitialized();
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google sign-in is not supported on this platform.',
      );
    }
    try {
      // scopeHint: 'email' ensures the email claim is present in the ID token,
      // which the backend needs to find-or-create the account.
      final account = await signIn.authenticate(scopeHint: const ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google did not return an ID token.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      // A user-cancelled picker is a normal outcome, not an error.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
