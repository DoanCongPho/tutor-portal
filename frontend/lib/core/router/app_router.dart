import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/home_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const onboarding = '/';
  static const role = '/role';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyOtp = '/verify-otp';
  static const home = '/home';
}

/// The unauthenticated entry routes (everything in the signup/login flow).
const _authFlowRoutes = {
  AppRoutes.onboarding,
  AppRoutes.role,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.verifyOtp,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final listener = _AuthRouterListener(ref);
  ref.onDispose(listener.dispose);
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: listener,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggedIn = auth.user != null;
      final awaitingOtp = auth.pendingEmail != null;
      final loc = state.matchedLocation;
      final onAuthFlow = _authFlowRoutes.contains(loc);

      if (loggedIn) {
        // Logged in: keep the user out of the auth flow.
        return onAuthFlow ? AppRoutes.home : null;
      }
      // Not logged in. A pending email verification pins the user to the OTP
      // screen until they verify or cancel.
      if (awaitingOtp) {
        return loc == AppRoutes.verifyOtp ? null : AppRoutes.verifyOtp;
      }
      // Landed on the OTP screen with nothing pending — bounce to onboarding.
      if (loc == AppRoutes.verifyOtp) return AppRoutes.onboarding;
      if (!onAuthFlow) return AppRoutes.onboarding;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (_, __) => const ChooseRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (_, __) => const VerifyOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
});

/// Bridges Riverpod state changes into go_router's [Listenable]-based refresh.
class _AuthRouterListener extends ChangeNotifier {
  _AuthRouterListener(Ref ref) {
    ref.listen(
      authControllerProvider.select((s) => (s.user?.id, s.pendingEmail)),
      (_, __) => notifyListeners(),
    );
  }
}
