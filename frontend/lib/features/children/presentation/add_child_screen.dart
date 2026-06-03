import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/child.dart';
import 'children_controller.dart';

/// "Add Child" (the Parent / Add Child mockup): connect to a child via an invite
/// code, QR, or by generating an invitation to send.
///
/// Backed by the children API: "Send Invitation" creates a child profile and
/// mints a shareable code; "Enter Invite Code" accepts a pending code to connect.
/// QR scanning needs a camera package + permissions, so it's stubbed for now.
class AddChildScreen extends ConsumerWidget {
  const AddChildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Child')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.people_outline,
                  size: 32,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connect with your child',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "Link your child's student account to monitor their learning "
              'progress and manage bookings.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _MethodCard(
              icon: Icons.keyboard_alt_outlined,
              title: 'Enter Invite Code',
              subtitle: "Enter the code from your child's app",
              onTap: () => _enterCode(context, ref),
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: Icons.qr_code_scanner,
              title: 'Scan QR Code',
              subtitle: "Scan the QR code on your child's device",
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR scanning is coming soon')),
              ),
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: Icons.send_outlined,
              title: 'Send Invitation',
              subtitle: 'Create a profile and generate an invite code',
              onTap: () => _sendInvitation(context, ref),
            ),
            const SizedBox(height: 28),
            Text(
              'How it works',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const _Step(
              number: 1,
              text: 'Add your child to generate a connection code',
            ),
            const _Step(
              number: 2,
              text: "Share the code or scan QR from your child's app",
            ),
            const _Step(
              number: 3,
              text: 'Your child confirms the connection on their device',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<Child>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddChildSheet(),
    );
    if (created == null || !context.mounted) return;
    await _showCodeDialog(context, created);
    if (context.mounted) context.pop(); // back to My Children
  }

  Future<void> _enterCode(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Invite Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'VN-2026-XXXX'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    try {
      final child =
          await ref.read(childrenControllerProvider.notifier).connect(code);
      messenger.showSnackBar(
        SnackBar(content: Text('Connected with ${child.name}')),
      );
      if (context.mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showCodeDialog(BuildContext context, Child child) {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this code with ${child.name} to connect:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                child.inviteCode ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: child.inviteCode ?? ''),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: scheme.primary,
            child: Text(
              '$number',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet form that creates a child profile and returns the created
/// [Child] (carrying its fresh invite code) to the caller.
class _AddChildSheet extends ConsumerStatefulWidget {
  const _AddChildSheet();

  @override
  ConsumerState<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grade = TextEditingController();
  final _school = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _grade.dispose();
    _school.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final child =
          await ref.read(childrenControllerProvider.notifier).addChild(
                name: _name.text.trim(),
                grade: _grade.text.trim(),
                school: _school.text.trim(),
              );
      if (mounted) Navigator.pop(context, child);
    } catch (e) {
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Child',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              "We'll generate an invite code to connect their account.",
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Child's name",
                hintText: 'Nguyễn Minh Anh',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grade,
              decoration: const InputDecoration(
                labelText: 'Grade (optional)',
                hintText: 'Lớp 8',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _school,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'School (optional)',
                hintText: 'Trường THCS Nguyễn Du',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Invite Code'),
            ),
          ],
        ),
      ),
    );
  }
}
