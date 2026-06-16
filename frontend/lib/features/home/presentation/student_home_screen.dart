import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/ui/initials_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../connections/presentation/connections_controller.dart';

/// Student home (mirrors the Parent / Home layout for the student role): a
/// greeting, a "connect with parents" entry point, quick actions, upcoming
/// sessions and recently shared materials.
///
/// Sessions and materials are placeholder data for now — the booking and
/// materials features aren't wired yet. Replace the `_sample*` data with real
/// providers as those land. The connect-with-parents card is the live entry
/// point into the [AppRoutes.studentConnect] flow.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

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
            const _ConnectParentCard(),
            const SizedBox(height: 24),
            const _QuickActions(),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Upcoming Sessions',
              onSeeAll: () => context.go(AppRoutes.studentTasks),
            ),
            const SizedBox(height: 12),
            for (final s in _sampleSessions) ...[
              _SessionCard(session: s),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Recent Materials',
              onSeeAll: () => context.go(AppRoutes.studentMaterials),
            ),
            const SizedBox(height: 12),
            for (final m in _sampleMaterials) ...[
              _MaterialCard(material: m),
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

/// Primary entry point into the connect-with-parents flow. Sits at the top of
/// home so a freshly signed-up student is nudged to link a parent account; once
/// connected it flips to a positive "connected" state.
class _ConnectParentCard extends ConsumerWidget {
  const _ConnectParentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref
        .watch(connectionsControllerProvider)
        .maybeWhen(data: (c) => c?.isConnected ?? false, orElse: () => false);
    final scheme = Theme.of(context).colorScheme;

    // Connected = positive (tertiary tint); not connected = call-to-action
    // (primary fill) so it reads as a prompt.
    final bg = connected ? scheme.tertiaryContainer : scheme.primary;
    final fg = connected ? scheme.onTertiaryContainer : scheme.onPrimary;
    final iconBg = connected
        ? scheme.tertiary.withValues(alpha: 0.18)
        : scheme.onPrimary.withValues(alpha: 0.18);
    final title =
        connected ? 'Connected with your parent' : 'Connect with your parent';
    final subtitle = connected
        ? 'Your parent can follow your progress and bookings.'
        : 'Link a parent account to share progress and bookings.';

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const ValueKey('home_connect_parent_card'),
        onTap: () => context.push(AppRoutes.studentConnect),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  connected ? Icons.check_rounded : Icons.family_restroom,
                  color: fg,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: fg),
            ],
          ),
        ),
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
          icon: Icons.menu_book_outlined,
          label: 'Materials',
          onTap: () => context.go(AppRoutes.studentMaterials),
        ),
        _QuickAction(
          icon: Icons.assignment_outlined,
          label: 'Tasks',
          onTap: () => context.go(AppRoutes.studentTasks),
        ),
        _QuickAction(
          icon: Icons.family_restroom,
          label: 'Connect',
          onTap: () => context.push(AppRoutes.studentConnect),
        ),
        _QuickAction(
          icon: Icons.insights_outlined,
          label: 'Progress',
          onTap: () => _soon(context, 'Progress'),
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
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});
  final _Material material;

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
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(material.icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${material.tutor} · ${material.when}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// --- Placeholder data (until booking/materials features are wired) ---

class _Session {
  const _Session(
    this.time,
    this.period,
    this.subject,
    this.tutor,
    this.when,
  );
  final String time;
  final String period;
  final String subject;
  final String tutor;
  final String when;
}

const _sampleSessions = <_Session>[
  _Session('10:00', 'AM', 'Toán học', 'Nguyễn Thảo', 'Today, 10:00 - 11:00'),
  _Session('14:00', 'PM', 'Tiếng Anh', 'Trần Hải', 'Tomorrow, 14:00 - 15:30'),
];

class _Material {
  const _Material(this.icon, this.title, this.tutor, this.when);
  final IconData icon;
  final String title;
  final String tutor;
  final String when;
}

const _sampleMaterials = <_Material>[
  _Material(
    Icons.picture_as_pdf_outlined,
    'Tích phân cơ bản',
    'Nguyễn Thảo',
    '2 days ago',
  ),
  _Material(
    Icons.description_outlined,
    'Bài tập Toán - Chương 5',
    'Nguyễn Thảo',
    '5 days ago',
  ),
];
