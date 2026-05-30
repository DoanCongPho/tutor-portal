import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// UI-facing state for the auth flow. [user] non-null = logged in. The
/// pending* fields capture the in-flight register/login step so the verify
/// screen knows which phone the OTP was sent to and which endpoint to call.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.otpSent = false,
    this.pendingPhone,
    this.pendingIsRegistration = false,
  });

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool otpSent;
  final String? pendingPhone;
  final bool pendingIsRegistration;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool? otpSent,
    String? pendingPhone,
    bool? pendingIsRegistration,
    bool clearError = false,
    bool clearUser = false,
    bool clearPending = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      otpSent: clearPending ? false : (otpSent ?? this.otpSent),
      pendingPhone: clearPending ? null : (pendingPhone ?? this.pendingPhone),
      pendingIsRegistration: clearPending
          ? false
          : (pendingIsRegistration ?? this.pendingIsRegistration),
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

  Future<void> startRegistration({
    required String phone,
    required String role,
    required String name,
  }) async {
    await _run(() async {
      await _repo.startRegistration(phone: phone, role: role, name: name);
      state = state.copyWith(
        otpSent: true,
        pendingPhone: phone,
        pendingIsRegistration: true,
      );
    });
  }

  Future<void> startLogin(String phone) async {
    await _run(() async {
      await _repo.startLogin(phone);
      state = state.copyWith(
        otpSent: true,
        pendingPhone: phone,
        pendingIsRegistration: false,
      );
    });
  }

  Future<void> verifyOtp(String code) async {
    final phone = state.pendingPhone;
    if (phone == null) {
      state = state.copyWith(errorMessage: 'No pending verification.');
      return;
    }
    await _run(() async {
      final user = state.pendingIsRegistration
          ? await _repo.verifyRegistration(phone: phone, code: code)
          : await _repo.verifyLogin(phone: phone, code: code);
      state = state.copyWith(user: user, clearPending: true);
    });
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
