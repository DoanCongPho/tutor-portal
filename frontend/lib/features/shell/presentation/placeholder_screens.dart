import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';

/// Lightweight "coming soon" scaffold for parent tabs that aren't built yet
/// (Search, Bookings, Wallet). Keeps the shell navigable end to end while those
/// features land. Mirrors the Shared / Empty State mockup.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, size: 40, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                '$title is coming soon',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Search',
        icon: Icons.search,
        message: 'Find and filter verified tutors by subject, level and price.',
      );
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Bookings',
        icon: Icons.calendar_today,
        message: 'Track your upcoming and past sessions here.',
      );
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Wallet',
        icon: Icons.account_balance_wallet,
        message: 'Top up, view your balance and review transactions.',
      );
}

/// Full-screen landing for roles whose app isn't built yet. Parent is the only
/// fully-wired experience for now (the BottomNav/Parent design); the tutor
/// (BottomNav/Tutor) and student (BottomNav/Student) shells will land later.
/// Until then these roles see a "coming soon" page with a way to sign out so
/// they aren't dropped into the parent shell or trapped without navigation.
class RoleComingSoonScreen extends ConsumerWidget {
  const RoleComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        actions: [
          IconButton(
            key: const ValueKey('role_logout_button'),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, size: 40, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                '$title is coming soon',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Tutor shell tabs not built yet (Home + Schedule are real screens). ---

class TutorStudentsScreen extends StatelessWidget {
  const TutorStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Students',
        icon: Icons.people_outline,
        message: 'Your students, their progress and shared materials.',
      );
}

class TutorWalletScreen extends StatelessWidget {
  const TutorWalletScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Wallet',
        icon: Icons.account_balance_wallet,
        message: 'Your earnings, payouts and transaction history.',
      );
}

// --- Student shell tabs (Home is a real screen; the rest aren't built yet). ---

class StudentMaterialsScreen extends StatelessWidget {
  const StudentMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Materials',
        icon: Icons.menu_book_outlined,
        message: 'Slides, notes and assignments shared by your tutors.',
      );
}

class StudentTasksScreen extends StatelessWidget {
  const StudentTasksScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Tasks',
        icon: Icons.assignment_outlined,
        message: 'Assignments and deadlines to keep track of.',
      );
}
