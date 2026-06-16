import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/tutor_gate.dart';
import 'steps/step_documents.dart';
import 'steps/step_personal.dart';
import 'steps/step_rate.dart';
import 'steps/step_review.dart';
import 'steps/step_schedule.dart';
import 'steps/step_subjects.dart';
import 'tutor_onboarding_controller.dart';

/// Per-step heading + subtitle, matching the "Tutor Profile Setup" mockup.
const _stepMeta = <({String title, String subtitle})>[
  (title: 'Personal Information', subtitle: 'Tell families a little about you'),
  (title: 'Subjects & Levels', subtitle: 'What and who do you teach?'),
  (title: 'Set Your Hourly Rate', subtitle: 'Choose a competitive rate for your tutoring sessions'),
  (title: 'Upload Credentials', subtitle: 'Help us verify your qualifications'),
  (title: 'Your Availability', subtitle: 'When are you free to teach?'),
  (title: 'Review & Submit', subtitle: 'Check everything before sending for review'),
];

/// The 6-step tutor onboarding wizard ("Tutor Profile Setup"). Holds all steps
/// in an [IndexedStack] so per-step field state survives navigation; the central
/// draft lives in [tutorOnboardingControllerProvider].
class TutorOnboardingScreen extends ConsumerWidget {
  const TutorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorOnboardingControllerProvider);

    if (state.isSubmitted) {
      return _SubmittedView(status: state.submittedStatus!);
    }

    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final meta = _stepMeta[state.step];

    ref.listen(tutorOnboardingControllerProvider.select((s) => s.errorMessage),
        (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      ctrl.clearError();
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Tutor Profile Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.isFirstStep) {
              context.go(AppRoutes.tutorHome);
            } else {
              ctrl.back();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _ProgressBar(
                    step: state.step,
                    total: kOnboardingStepCount,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Step ${state.step + 1} of $kOnboardingStepCount',
                          style: text.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta.title,
                          style: text.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          meta.subtitle,
                          style: text.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        IndexedStack(
                          index: state.step,
                          children: const [
                            StepPersonal(),
                            StepSubjects(),
                            StepRate(),
                            StepDocuments(),
                            StepSchedule(),
                            StepReview(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _BottomBar(state: state, ctrl: ctrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar — one filled coral segment per completed/active step.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i != total - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.ctrl});
  final TutorOnboardingState state;
  final TutorOnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canAdvance = state.canAdvance && !state.isSubmitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (!state.isFirstStep)
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('onboarding_back_button'),
                onPressed: state.isSubmitting ? null : ctrl.back,
                child: const Text('Back'),
              ),
            ),
          if (!state.isFirstStep) const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              key: const ValueKey('onboarding_next_button'),
              onPressed: canAdvance
                  ? (state.isLastStep ? ctrl.submit : ctrl.next)
                  : null,
              child: state.isSubmitting
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(state.isLastStep ? 'Submit for Review' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation shown after a successful submit — the profile is now under
/// review (verification_status = pending_review).
class _SubmittedView extends ConsumerWidget {
  const _SubmittedView({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.verified_outlined, size: 72, color: scheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Submitted for review',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your tutor profile is now under review. We'll notify you "
                    'once verification is complete.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('onboarding_done_button'),
                    onPressed: () {
                      // Profile created — flip the gate so the router lets the
                      // tutor into the dashboard instead of the wizard.
                      ref.read(tutorGateProvider.notifier).markOnboarded();
                      context.go(AppRoutes.tutorHome);
                    },
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
