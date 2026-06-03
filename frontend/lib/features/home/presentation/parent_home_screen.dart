import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/ui/initials_avatar.dart';
import '../../auth/presentation/auth_controller.dart';

/// Parent dashboard (the "Parent / Home" mockup): greeting, wallet balance,
/// quick actions, upcoming sessions and recommended tutors.
///
/// Wallet, sessions and tutors are placeholder data for now — the booking,
/// payment and tutor-search features aren't wired yet. Children navigation is
/// live. Replace the `_sample*` data with real providers as those land.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

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
            const SizedBox(height: 20),
            const _WalletCard(balance: 2500000),
            const SizedBox(height: 24),
            const _QuickActions(),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Upcoming Sessions',
              onSeeAll: () => context.go(AppRoutes.bookings),
            ),
            const SizedBox(height: 12),
            for (final s in _sampleSessions) ...[
              _SessionCard(session: s),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Recommended Tutors',
              onSeeAll: () => context.go(AppRoutes.search),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sampleTutors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _TutorCard(tutor: _sampleTutors[i]),
              ),
            ),
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
                'Good morning 👋',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? 'Welcome' : name,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications are coming soon')),
          ),
          style: IconButton.styleFrom(
            backgroundColor: scheme.surface,
            shape: CircleBorder(
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          icon: const Icon(Icons.notifications_none),
        ),
        const SizedBox(width: 8),
        InitialsAvatar(name: name.isEmpty ? '?' : name, radius: 22),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatVnd(balance)}đ',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Top up is coming soon')),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.onPrimary,
              foregroundColor: scheme.primary,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Top Up'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.search,
          label: 'Find Tutor',
          onTap: () => context.go(AppRoutes.search),
        ),
        _QuickAction(
          icon: Icons.insights_outlined,
          label: 'Progress',
          onTap: () => _soon(context, 'Progress'),
        ),
        _QuickAction(
          icon: Icons.calendar_today_outlined,
          label: 'Schedule',
          onTap: () => context.go(AppRoutes.bookings),
        ),
        _QuickAction(
          icon: Icons.people_outline,
          label: 'Children',
          onTap: () => context.go(AppRoutes.children),
        ),
      ],
    );
  }

  static void _soon(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what is coming soon')),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
        Text(
          title,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('See All'),
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  session.time,
                  style: text.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  session.period,
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
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'with ${session.tutor}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.when,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(label: session.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: scheme.tertiary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.tutor});
  final _Tutor tutor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InitialsAvatar(name: tutor.name, radius: 26),
          const SizedBox(height: 10),
          Text(
            tutor.name,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  tutor.subject,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ' • ${tutor.rating}',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Icon(Icons.star_border, size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tutor.price,
            style: text.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatVnd(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// --- Placeholder data (until booking/tutor features are wired) ---

class _Session {
  const _Session(
    this.time,
    this.period,
    this.subject,
    this.tutor,
    this.when,
    this.status,
  );
  final String time;
  final String period;
  final String subject;
  final String tutor;
  final String when;
  final String status;
}

const _sampleSessions = <_Session>[
  _Session(
    '10:00',
    'AM',
    'Toán học',
    'Nguyễn Thảo',
    'Today, 10:00 - 11:00',
    'Confirmed',
  ),
  _Session(
    '14:00',
    'PM',
    'Tiếng Anh',
    'Trần Hải',
    'Tomorrow, 14:00 - 15:30',
    'Confirmed',
  ),
];

class _Tutor {
  const _Tutor(this.name, this.subject, this.rating, this.price);
  final String name;
  final String subject;
  final String rating;
  final String price;
}

const _sampleTutors = <_Tutor>[
  _Tutor('Lê Hương', 'Toán', '4.8', '300k/h'),
  _Tutor('Trần Hải', 'English', '4.9', '400k/h'),
];
