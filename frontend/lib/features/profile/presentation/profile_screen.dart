import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/ui/initials_avatar.dart';
import '../../auth/presentation/auth_controller.dart';

/// Shared Profile screen (the "Shared / Profile" mockup). Settings entries are
/// stubs for now; the parent-only "My Children" row links into the children
/// management flow, and Log Out is live.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = user?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                InitialsAvatar(name: name.isEmpty ? '?' : name, radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Welcome' : name,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (user != null) _RoleBadge(role: user.role),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  label: 'Personal Information',
                  onTap: () => _soon(context, 'Personal Information'),
                ),
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
              ],
            ),
            if (user?.isParent ?? false) ...[
              const SizedBox(height: 16),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.people_outline,
                    label: 'My Children',
                    onTap: () => context.go(AppRoutes.children),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: false,
                    onChanged: (_) => _soon(context, 'Dark mode'),
                  ),
                  onTap: () => _soon(context, 'Dark mode'),
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
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.error,
                elevation: 0,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }

  static void _soon(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what is coming soon')),
      );
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label =
        role.isEmpty ? '' : '${role[0].toUpperCase()}${role.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: scheme.tertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

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
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          trailing ?? Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
    );
  }
}
