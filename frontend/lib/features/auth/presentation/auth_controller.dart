import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// UI-facing state for the auth flow. [user] non-null = logged in.
/// [pendingEmail] non-null = an email registration is awaiting OTP verification.
class AuthState {
  const AuthState({
    this.user,
    this.pendingEmail,
    this.googleRegistrationToken,
    this.isLoading = false,
    this.errorMessage,
  });

  final AppUser? user;
  final String? pendingEmail;

  /// Non-null after a first-time Google sign-in: the short-lived backend token
  /// to redeem once the user picks a role (see [completeGoogleRole]). Drives the
  /// router to pin the user on the role screen until they choose.
  final String? googleRegistrationToken;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
  bool get isAwaitingOtp => pendingEmail != null;
  bool get needsRoleSelection => googleRegistrationToken != null;

  AuthState copyWith({
    AppUser? user,
    String? pendingEmail,
    String? googleRegistrationToken,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
    bool clearPendingEmail = false,
    bool clearGoogleRegistrationToken = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      pendingEmail:
          clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      googleRegistrationToken: clearGoogleRegistrationToken
          ? null
          : (googleRegistrationToken ?? this.googleRegistrationToken),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    // Bootstrap is async; fire-and-forget. The router watches `user.id` so it
    // re-evaluates the redirect once this completes.
    Future.microtask(_bootstrap);
    return const AuthState();
  }

  Future<void> _bootstrap() async {
    final user = await _repo.currentUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  /// Step one of email signup. On success the backend has emailed an OTP and
  /// [pendingEmail] is set, which the router uses to route to the verify screen.
  /// [phone] is optional contact info, never verified.
  Future<void> register({
    required String email,
    required String role,
    required String name,
    required String password,
    String? phone,
  }) async {
    await _run(() async {
      await _repo.startRegistration(
        email: email,
        role: role,
        name: name,
        password: password,
        phone: phone,
      );
      state = state.copyWith(pendingEmail: email);
    });
  }

  /// Step two: submit the OTP for the pending email. On success the new account
  /// is logged in and the pending state cleared.
  Future<void> verifyOtp(String code) async {
    final email = state.pendingEmail;
    if (email == null) return;
    await _run(() async {
      final user = await _repo.verifyRegistration(email: email, code: code);
      state = state.copyWith(user: user, clearPendingEmail: true);
    });
  }

  /// Abandons a pending registration (e.g. "use a different email"), returning
  /// the flow to the login/register screens.
  void cancelRegistration() {
    state = state.copyWith(clearPendingEmail: true, clearError: true);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _run(() async {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(user: user);
    });
  }

  /// Starts Google sign-in. An existing/linked account logs straight in; a
  /// brand-new account sets [AuthState.googleRegistrationToken], which routes the
  /// user to the role screen to finish via [completeGoogleRole]. A cancelled
  /// picker is a no-op.
  Future<void> signInWithGoogle() async {
    await _run(() async {
      final result = await _repo.signInWithGoogle();
      if (result == null) return; // user cancelled
      if (result.needsRole) {
        state = state.copyWith(
          googleRegistrationToken: result.registrationToken,
        );
      } else if (result.tokens != null) {
        state = state.copyWith(user: result.tokens!.user);
      }
    });
  }

  /// Completes a first-time Google sign-up with the chosen role.
  Future<void> completeGoogleRole(String role) async {
    final token = state.googleRegistrationToken;
    if (token == null) return;
    await _run(() async {
      final user = await _repo.completeGoogleRegistration(
        registrationToken: token,
        role: role,
      );
      state = state.copyWith(
        user: user,
        clearGoogleRegistrationToken: true,
      );
    });
  }

  /// Abandons a pending Google role selection (e.g. user backs out), returning
  /// the flow to the unauthenticated entry screens.
  void cancelGoogleRegistration() {
    state = state.copyWith(
      clearGoogleRegistrationToken: true,
      clearError: true,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _run(Future<void> Function() body) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await body();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Role chosen on the "Choose Role" screen, carried into the sign-up form.
/// Defaults to parent. Lives outside [AuthState] because it's transient signup
/// UI state, not authentication state.
final signupRoleProvider = StateProvider<String>((ref) => 'parent');
