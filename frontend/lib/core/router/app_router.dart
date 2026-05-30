import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/home_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const verify = '/verify';
  static const home = '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listener = _AuthRouterListener(ref);
  ref.onDispose(listener.dispose);
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: listener,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggedIn = auth.user != null;
      final loggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.verify;

      if (!loggedIn && !loggingIn) return AppRoutes.login;
      if (loggedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verify,
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
      authControllerProvider.select((s) => s.user?.id),
      (_, __) => notifyListeners(),
    );
  }
}
