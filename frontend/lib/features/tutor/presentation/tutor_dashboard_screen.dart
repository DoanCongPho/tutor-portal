import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/initials_avatar.dart';
import '../../auth/presentation/auth_controller.dart';

/// Tutor dashboard (the "Tutor / Dashboard" mockup): greeting, verified banner,
/// month stats, today's sessions and recent activity.
///
/// Stats, sessions and activity are placeholder data — the booking and payment
/// features aren't wired to the tutor side yet. Replace the `_sample*` data with
/// real providers as those land. Only the greeting name is live (from auth).
class TutorDashboardScreen extends ConsumerWidget {
  const TutorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final name = user?.name ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _Header(name: name),
            const SizedBox(height: 16),
            const _VerifiedBanner(),
            const SizedBox(height: 16),
            const _StatsRow(),
            const SizedBox(height: 28),
            _SectionHeader(title: "Today's Sessions", onSeeAll: () {}),
            const SizedBox(height: 12),
            for (final s in _sampleSessions) ...[
              _SessionCard(session: s),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            Text(
              'Recent Activity',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final a in _sampleActivity) ...[
              _ActivityRow(activity: a),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? 'Tutor' : name,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
          style: IconButton.styleFrom(
            backgroundColor: scheme.surface,
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 10),
        InitialsAvatar(name: name.isEmpty ? '?' : name, radius: 22),
      ],
    );
  }
}

/// Green "Verified Tutor" banner. Shown for verified tutors; the verification
/// status will come from the tutor profile once the dashboard is wired.
class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppTheme.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Verified Tutor',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(value: '4,250k', label: 'This Month', accent: true),
        ),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '12', label: 'Students')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '4.9', label: 'Rating', accent: true)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent ? scheme.primary : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final _Session session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.hour,
                  style: text.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  session.meridiem,
                  style: text.labelSmall?.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  session.student,
                  style:
                      text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  session.timeRange,
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const _StatusPill(label: 'Confirmed'),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: AppTheme.success),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check, size: 18, color: AppTheme.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.title, style: text.bodyLarge),
              const SizedBox(height: 2),
              Text(
                activity.subtitle,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Placeholder data (replace with real providers once the tutor side wires
// booking + payment). ---

class _Session {
  const _Session({
    required this.hour,
    required this.meridiem,
    required this.subject,
    required this.student,
    required this.timeRange,
  });
  final String hour;
  final String meridiem;
  final String subject;
  final String student;
  final String timeRange;
}

const _sampleSessions = <_Session>[
  _Session(
    hour: '10:00',
    meridiem: 'AM',
    subject: 'Toán - Lớp 12',
    student: 'Nguyễn Hà',
    timeRange: '10:00 - 11:00 AM',
  ),
  _Session(
    hour: '14:00',
    meridiem: 'PM',
    subject: 'Vật lý - Lớp 11',
    student: 'Lê Hoàng',
    timeRange: '14:00 - 15:30 PM',
  ),
];

class _Activity {
  const _Activity({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

const _sampleActivity = <_Activity>[
  _Activity(
    title: 'Session completed with Nguyễn Hà',
    subtitle: '2 hours ago',
  ),
];
