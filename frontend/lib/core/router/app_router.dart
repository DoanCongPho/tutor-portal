import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/children/presentation/add_child_screen.dart';
import '../../features/children/presentation/my_children_screen.dart';
import '../../features/home/presentation/parent_home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/parent_shell.dart';
import '../../features/shell/presentation/placeholder_screens.dart';
import '../../features/tutor/presentation/tutor_onboarding_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const onboarding = '/';
  static const role = '/role';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyOtp = '/verify-otp';
  // Parent shell tabs.
  static const home = '/home';
  static const search = '/search';
  static const bookings = '/bookings';
  static const wallet = '/wallet';
  static const profile = '/profile';
  // Children flow (nested under the Home tab so the bottom nav stays visible).
  static const children = '/home/children';
  static const addChild = '/home/children/add';
  // Role landings whose full app isn't built yet (coming soon).
  static const tutor = '/tutor';
  static const student = '/student';
  static const tutorOnboarding = '/tutor/onboarding';
}

/// Top-level path prefixes that make up the parent app (the parent bottom-nav
/// shell + everything nested under its tabs). Used to gate non-parent roles out
/// of the parent shell.
const _parentRoots = [
  AppRoutes.home,
  AppRoutes.search,
  AppRoutes.bookings,
  AppRoutes.wallet,
  AppRoutes.profile,
];

/// Where a freshly authenticated user of [role] belongs. Parent is the only
/// fully-built experience; tutor and student land on a "coming soon" page.
String _homeForRole(String role) => switch (role) {
      'tutor' => AppRoutes.tutor,
      'student' => AppRoutes.student,
      _ => AppRoutes.home,
    };

/// Whether [loc] is a section the given [role] is allowed to view. Keeps each
/// role inside its own part of the app (a tutor can't open the parent shell).
bool _locAllowedForRole(String loc, String role) => switch (role) {
      'tutor' => loc == AppRoutes.tutor,
      'student' => loc == AppRoutes.student,
      _ => _parentRoots.any(loc.startsWith),
    };

/// The unauthenticated entry routes (everything in the signup/login flow).
const _authFlowRoutes = {
  AppRoutes.onboarding,
  AppRoutes.role,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.verifyOtp,
};

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final listener = _AuthRouterListener(ref);
  ref.onDispose(listener.dispose);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.onboarding,
    refreshListenable: listener,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggedIn = auth.user != null;
      final awaitingOtp = auth.pendingEmail != null;
      final loc = state.matchedLocation;
      final onAuthFlow = _authFlowRoutes.contains(loc);

      if (loggedIn) {
        // Logged in: route to the role's home and keep each role inside its
        // own section. Parent gets the full shell; tutor/student land on a
        // "coming soon" page until those apps are built.
        final role = auth.user!.role;
        final roleHome = _homeForRole(role);
        if (onAuthFlow) return roleHome;
        return _locAllowedForRole(loc, role) ? null : roleHome;
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
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
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
      // Role landings whose full app isn't built yet — coming-soon pages.
      GoRoute(
        path: AppRoutes.tutor,
        builder: (_, __) => const TutorHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.student,
        builder: (_, __) => const StudentHomeScreen(),
      ),
      // Authenticated parent app: a bottom-nav shell, one branch per tab.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ParentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const ParentHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'children',
                    builder: (_, __) => const MyChildrenScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (_, __) => const AddChildScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, __) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookings,
                builder: (_, __) => const BookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wallet,
                builder: (_, __) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.tutorOnboarding,
        builder: (_, __) => const TutorOnboardingScreen(),
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
