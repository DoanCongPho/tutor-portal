import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import 'tutor_repository.dart';

/// Where an authenticated tutor belongs, decided by whether they've completed
/// onboarding:
/// - [loading]        — still checking (GET /tutors/me in flight on login).
/// - [needsOnboarding] — no profile yet (404): show the setup wizard.
/// - [onboarded]      — profile exists: go straight to the tutor home shell.
enum TutorGate { loading, needsOnboarding, onboarded }

/// Resolves [TutorGate] for the signed-in tutor. The router reads this to send
/// a tutor to the wizard or to their dashboard, and re-runs its redirect when
/// this changes (the router's listener watches this provider).
///
/// Re-checks whenever the authenticated user changes (login / logout / switch).
/// For non-tutor users the value is irrelevant and stays [loading].
class TutorGateController extends Notifier<TutorGate> {
  @override
  TutorGate build() {
    final id = ref.watch(authControllerProvider.select((s) => s.user?.id));
    final role = ref.watch(authControllerProvider.select((s) => s.user?.role));
    if (id == null || role != 'tutor') return TutorGate.loading;
    // Async check; the router re-evaluates when state lands. Fire-and-forget.
    Future.microtask(_check);
    return TutorGate.loading;
  }

  Future<void> _check() async {
    try {
      await ref.read(tutorRepositoryProvider).getMyProfile();
      state = TutorGate.onboarded;
    } catch (_) {
      // 404 = not onboarded. Any other failure (network, 5xx) also falls back to
      // the wizard rather than trapping the tutor on a spinner; a re-submit of an
      // already-created profile is the backend's to reject.
      state = TutorGate.needsOnboarding;
    }
  }

  /// Called after a successful onboarding submit so the router moves the tutor
  /// to their dashboard without re-fetching.
  void markOnboarded() => state = TutorGate.onboarded;
}

final tutorGateProvider =
    NotifierProvider<TutorGateController, TutorGate>(TutorGateController.new);
