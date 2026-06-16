import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/initials_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/tutor_profile_provider.dart';
import '../domain/tutor_profile.dart';
import '../domain/tutor_vocab.dart';

/// Tutor Profile tab. Shows the saved tutor profile (rate, bio, subjects,
/// availability) loaded from GET /tutors/me, with an "Edit Profile" entry into
/// the update form, plus the shared settings rows and Log Out.
class TutorProfileScreen extends ConsumerWidget {
  const TutorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(tutorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        actions: [
          IconButton(
            key: const ValueKey('tutor_profile_edit_button'),
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: profileAsync.hasValue
                ? () => context.go(AppRoutes.tutorEditProfile)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorState(
            onRetry: () => ref.invalidate(tutorProfileProvider),
          ),
          data: (profile) => _ProfileBody(profile: profile),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final TutorProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final email = ref.watch(authControllerProvider.select((s) => s.user?.email));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            InitialsAvatar(
              name: profile.name.isEmpty ? '?' : profile.name,
              radius: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name.isEmpty ? 'Tutor' : profile.name,
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email ?? '',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  _VerificationBadge(status: profile.verificationStatus),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Tutor details ---
        _Card(
          title: 'Hourly rate',
          child: Text(
            '${formatVnd(profile.hourlyRate)} đ/hour',
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'About',
          child: Text(
            (profile.bio?.trim().isNotEmpty ?? false)
                ? profile.bio!.trim()
                : 'No bio yet — tap Edit to introduce yourself.',
            style: text.bodyMedium?.copyWith(
              color: (profile.bio?.trim().isNotEmpty ?? false)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Subjects & levels',
          child: profile.subjects.isEmpty
              ? Text(
                  'No subjects added yet.',
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in profile.subjects)
                      Chip(
                        label: Text('${s.subject} · ${s.level.label}'),
                        backgroundColor: scheme.primaryContainer,
                        side: BorderSide.none,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Availability',
          child: Text(
            profile.schedule.isEmpty
                ? 'No availability set.'
                : '${profile.schedule.length} weekly time '
                    '${profile.schedule.length == 1 ? 'slot' : 'slots'}',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),

        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('tutor_profile_edit_cta'),
          onPressed: () => context.go(AppRoutes.tutorEditProfile),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
        ),

        const SizedBox(height: 24),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.shield_outlined,
              label: 'Security',
              onTap: () => _soon(context, 'Security'),
            ),
            _SettingsTile(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => _soon(context, 'Notifications'),
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              label: 'Help Center',
              onTap: () => _soon(context, 'Help Center'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('profile_logout_button'),
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.error,
            elevation: 0,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
        ),
      ],
    );
  }

  static void _soon(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what is coming soon')),
      );
}

/// Colored pill reflecting `tutor_profiles.verification_status`.
class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'verified' => ('Verified', AppTheme.success),
      'rejected' => ('Rejected', scheme.error),
      'requires_documents' => ('Action needed', AppTheme.infoBannerFg),
      _ => ('Pending review', AppTheme.infoBannerFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              "Couldn't load your profile.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// --- Settings rows (mirrors the shared Profile design). ---

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i != children.length - 1) {
        divided.add(Divider(height: 1, color: scheme.outlineVariant));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: divided),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
    );
  }
}
