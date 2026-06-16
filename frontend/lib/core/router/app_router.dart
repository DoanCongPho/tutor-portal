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
import '../../features/connections/presentation/connect_parents_screen.dart';
import '../../features/home/presentation/parent_home_screen.dart';
import '../../features/home/presentation/student_home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/parent_shell.dart';
import '../../features/shell/presentation/placeholder_screens.dart';
import '../../features/shell/presentation/student_shell.dart';
import '../../features/shell/presentation/tutor_shell.dart';
import '../../features/tutor/data/tutor_gate.dart';
import '../../features/tutor/presentation/tutor_dashboard_screen.dart';
import '../../features/tutor/presentation/tutor_edit_profile_screen.dart';
import '../../features/tutor/presentation/tutor_loading_screen.dart';
import '../../features/tutor/presentation/tutor_onboarding_screen.dart';
import '../../features/tutor/presentation/tutor_profile_screen.dart';
import '../../features/tutor/presentation/tutor_schedule_screen.dart';

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
  // Tutor app: a bottom-nav shell (Home · Schedule · Students · Wallet ·
  // Profile), the onboarding wizard, and the splash shown while we check
  // whether the tutor has onboarded.
  static const tutorHome = '/tutor/home';
  static const tutorSchedule = '/tutor/schedule';
  static const tutorStudents = '/tutor/students';
  static const tutorWallet = '/tutor/wallet';
  static const tutorProfile = '/tutor/profile';
  static const tutorEditProfile = '/tutor/profile/edit';
  static const tutorOnboarding = '/tutor/onboarding';
  static const tutorLoading = '/tutor/loading';
  // Student app: a bottom-nav shell (Home · Materials · Tasks · Profile).
  static const studentHome = '/student/home';
  // Connect-with-parent flow, nested under Home so the bottom nav stays visible.
  static const studentConnect = '/student/home/connect';
  static const studentMaterials = '/student/materials';
  static const studentTasks = '/student/tasks';
  static const studentProfile = '/student/profile';
}

/// Top-level path prefixes that make up each role's bottom-nav shell. Used to
/// keep a signed-in user inside their own role's section of the app. Each role
/// has a different set of tabs (see the BottomNav mockups).
const _parentRoots = [
  AppRoutes.home,
  AppRoutes.search,
  AppRoutes.bookings,
  AppRoutes.wallet,
  AppRoutes.profile,
];
const _tutorRoots = [
  AppRoutes.tutorHome,
  AppRoutes.tutorSchedule,
  AppRoutes.tutorStudents,
  AppRoutes.tutorWallet,
  AppRoutes.tutorProfile,
];
const _studentRoots = [
  AppRoutes.studentHome,
  AppRoutes.studentMaterials,
  AppRoutes.studentTasks,
  AppRoutes.studentProfile,
];

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
      final needsRole = auth.needsRoleSelection;
      final loc = state.matchedLocation;
      final onAuthFlow = _authFlowRoutes.contains(loc);

      if (loggedIn) {
        // Logged in: route to the role's home and keep each role inside its own
        // section (each role has a different bottom-nav shell).
        final role = auth.user!.role;
        if (role == 'tutor') {
          // A tutor goes to their dashboard if they've onboarded, else into the
          // setup wizard. While the check is in flight, hold on a splash so we
          // don't flash the wizard before landing on the dashboard.
          final gate = ref.read(tutorGateProvider);
          final dest = switch (gate) {
            TutorGate.loading => AppRoutes.tutorLoading,
            TutorGate.needsOnboarding => AppRoutes.tutorOnboarding,
            TutorGate.onboarded => AppRoutes.tutorHome,
          };
          if (onAuthFlow) return dest;
          final allowed = switch (gate) {
            TutorGate.loading => loc == AppRoutes.tutorLoading,
            TutorGate.needsOnboarding => loc == AppRoutes.tutorOnboarding,
            TutorGate.onboarded => _tutorRoots.any(loc.startsWith),
          };
          return allowed ? null : dest;
        }
        if (role == 'student') {
          if (onAuthFlow) return AppRoutes.studentHome;
          return _studentRoots.any(loc.startsWith) ? null : AppRoutes.studentHome;
        }
        // Parent: the full bottom-nav shell.
        if (onAuthFlow) return AppRoutes.home;
        return _parentRoots.any(loc.startsWith) ? null : AppRoutes.home;
      }
      // Not logged in. A first-time Google sign-in pins the user to the role
      // screen until they pick a role (which redeems the registration token).
      if (needsRole) {
        return loc == AppRoutes.role ? null : AppRoutes.role;
      }
      // A pending email verification pins the user to the OTP screen until they
      // verify or cancel.
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
      // Splash while we check whether the tutor has onboarded.
      GoRoute(
        path: AppRoutes.tutorLoading,
        builder: (_, __) => const TutorLoadingScreen(),
      ),
      // Authenticated tutor app: bottom-nav shell (Home · Schedule · Students ·
      // Wallet · Profile). Reached only once onboarding is complete.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            TutorShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorHome,
                builder: (_, __) => const TutorDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorSchedule,
                builder: (_, __) => const TutorScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorStudents,
                builder: (_, __) => const TutorStudentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorWallet,
                builder: (_, __) => const TutorWalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutorProfile,
                builder: (_, __) => const TutorProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, __) => const TutorEditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Authenticated student app: bottom-nav shell (Home · Materials · Tasks ·
      // Profile). Fewer tabs than parent/tutor.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentHome,
                builder: (_, __) => const StudentHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'connect',
                    builder: (_, __) => const ConnectParentsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentMaterials,
                builder: (_, __) => const StudentMaterialsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentTasks,
                builder: (_, __) => const StudentTasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentProfile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
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
/// Watches auth (login/logout/OTP) and the tutor onboarding gate, so the
/// redirect re-runs the moment the tutor's onboarding status resolves.
class _AuthRouterListener extends ChangeNotifier {
  _AuthRouterListener(Ref ref) {
    ref.listen(
      authControllerProvider.select(
        (s) => (s.user?.id, s.pendingEmail, s.googleRegistrationToken),
      ),
      (_, __) => notifyListeners(),
    );
    ref.listen(tutorGateProvider, (_, __) => notifyListeners());
  }
}
