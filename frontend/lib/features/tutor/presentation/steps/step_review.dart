import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tutor_vocab.dart';
import '../tutor_onboarding_controller.dart';

/// Step 6 — review everything before submitting. The Submit action lives in the
/// wizard's bottom bar; this body is the read-only summary.
class StepReview extends ConsumerWidget {
  const StepReview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tutorOnboardingControllerProvider);
    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewSection(
          title: 'Personal info',
          onEdit: () => ctrl.goTo(0),
          children: [
            _row('Name', s.name),
            if (s.phone.isNotEmpty) _row('Phone', s.phone),
          ],
        ),
        _ReviewSection(
          title: 'Subjects',
          onEdit: () => ctrl.goTo(1),
          children: [
            for (final e in s.subjects) _row(e.subject, e.level.label),
          ],
        ),
        _ReviewSection(
          title: 'Hourly rate',
          onEdit: () => ctrl.goTo(2),
          children: [_row('Rate', '${formatVnd(s.hourlyRate)} ₫/hour')],
        ),
        _ReviewSection(
          title: 'Documents',
          onEdit: () => ctrl.goTo(3),
          children: [
            for (final entry in s.documents.entries)
              _row(entry.key.label, 'Provided'),
          ],
        ),
        _ReviewSection(
          title: 'Schedule',
          onEdit: () => ctrl.goTo(4),
          children: [
            for (final slot in s.schedule)
              _row(kDayLabels[slot.dayOfWeek], '${slot.startTime} – ${slot.endTime}'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Submitting sends your profile to our team for verification. You'
          "'ll be notified once it's reviewed.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label)),
            Expanded(
              flex: 3,
              child: Text(value, textAlign: TextAlign.end),
            ),
          ],
        ),
      );
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
