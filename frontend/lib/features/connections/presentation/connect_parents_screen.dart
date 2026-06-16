import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/parent_connection.dart';
import 'connections_controller.dart';

/// "Connect with Parent" — the student enters the invite code their parent
/// generated (in the parent's Add Child flow). Accepting the code links the two
/// accounts and flips the child profile to `connected` on the backend
/// (`POST /children/link`). Once connected, the screen shows the linked state.
class ConnectParentsScreen extends ConsumerStatefulWidget {
  const ConnectParentsScreen({super.key});

  @override
  ConsumerState<ConnectParentsScreen> createState() =>
      _ConnectParentsScreenState();
}

class _ConnectParentsScreenState extends ConsumerState<ConnectParentsScreen> {
  final _code = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conn =
          await ref.read(connectionsControllerProvider.notifier).connect(code);
      messenger.showSnackBar(
        SnackBar(content: Text('Connected with ${conn.name}')),
      );
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  /// Friendly message for the common connect failures the backend returns.
  String _message(Object e) {
    final s = e.toString();
    if (s.contains('not found')) return 'That code is invalid. Check and retry.';
    if (s.contains('expired')) return 'That code has expired. Ask for a new one.';
    if (s.contains('already connected')) {
      return 'That code has already been used.';
    }
    return 'Could not connect. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connect with Parent')),
      body: SafeArea(
        child: connection.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _form(context),
          data: (conn) => conn != null && conn.isConnected
              ? _connected(context, conn)
              : _form(context),
        ),
      ),
    );
  }

  Widget _connected(BuildContext context, ParentConnection conn) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: scheme.tertiaryContainer,
            child: Icon(Icons.check_rounded, size: 40, color: scheme.tertiary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "You're connected!",
          key: const ValueKey('connect_connected_state'),
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your account is linked to your parent as “${conn.name}”. They can '
          'now follow your learning progress and help manage bookings.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: scheme.primaryContainer,
            child: Icon(
              Icons.family_restroom,
              size: 32,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Connect with your parent',
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the invite code your parent generated in their app to link your '
          'accounts.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('connect_code_field'),
          controller: _code,
          autofocus: true,
          enabled: !_submitting,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Parent invite code',
            hintText: 'VN-2026-XXXX',
            prefixIcon: Icon(Icons.keyboard_alt_outlined),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('connect_submit_button'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
        const SizedBox(height: 28),
        Text(
          'How it works',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const _Step(
          number: 1,
          text: 'Ask your parent to add you in their app and share the code',
        ),
        const _Step(
          number: 2,
          text: 'Enter that code above and tap Connect',
        ),
        const _Step(
          number: 3,
          text: 'Once connected, your parent can follow your progress',
        ),
      ],
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
