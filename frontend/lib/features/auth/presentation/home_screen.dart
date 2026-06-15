import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import 'auth_controller.dart';

/// Placeholder landing screen so the auth flow has somewhere to go. Replace
/// with the real role-aware home (parent search, tutor schedule, ...) when
/// those features land.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Portal'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name.characters.first.toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${user.role} · ${user.email}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (user.isTutor) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: FilledButton(
                          key: const ValueKey('home_tutor_onboarding_cta'),
                          onPressed: () =>
                              context.go(AppRoutes.tutorOnboarding),
                          child: const Text('Complete your tutor profile'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
