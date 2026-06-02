import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

/// Step before sign-up: pick the role that personalizes the experience. The
/// choice is stored in [signupRoleProvider] and consumed by the register form.
class ChooseRoleScreen extends ConsumerWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final selected = ref.watch(signupRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Role'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Who Are You?',
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your role to personalize your experience',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RoleCard(
                    role: 'parent',
                    icon: Icons.favorite_border_rounded,
                    title: "I'm a Parent",
                    subtitle: 'Find tutors for my children',
                    selected: selected == 'parent',
                    onTap: () =>
                        ref.read(signupRoleProvider.notifier).state = 'parent',
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    role: 'tutor',
                    icon: Icons.menu_book_rounded,
                    title: "I'm a Tutor",
                    subtitle: 'Teach and earn on my schedule',
                    selected: selected == 'tutor',
                    onTap: () =>
                        ref.read(signupRoleProvider.notifier).state = 'tutor',
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    role: 'student',
                    icon: Icons.edit_outlined,
                    title: "I'm a Student",
                    subtitle: 'Access lessons and assignments',
                    selected: selected == 'student',
                    onTap: () =>
                        ref.read(signupRoleProvider.notifier).state = 'student',
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('choose_role_continue_button'),
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Text('Continue'),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String role;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppTheme.cardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('role_card_$role'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.softCoralTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
