import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// First-run landing: the TutorMatch brand mark, a hero illustration, and the
/// two entry points — start signup (→ choose role) or sign in.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const _BrandMark(),
                      const SizedBox(height: 40),
                      const _HeroIllustration(),
                      const SizedBox(height: 32),
                      Text(
                        'Find Your Perfect Tutor',
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connect with verified tutors, book sessions, '
                        'and track your learning journey.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      FilledButton(
                        key: const ValueKey('onboarding_get_started_button'),
                        onPressed: () => context.go(AppRoutes.role),
                        child: const Text('Get Started'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const ValueKey('onboarding_sign_in_button'),
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('I Already Have an Account'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.school_rounded, color: scheme.onPrimary, size: 36),
        ),
        const SizedBox(height: 12),
        Text(
          'TutorMatch',
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Hero artwork — the tutor + student illustration from the landing mockup.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.asset(
          'assets/images/landing_page.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
