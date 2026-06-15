import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tutor_profile.dart';
import '../../domain/tutor_vocab.dart';
import '../tutor_onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 2 — subjects and levels. Each (subject, level) pair becomes a row in
/// `tutor_subjects`; a tutor may add several.
class StepSubjects extends ConsumerStatefulWidget {
  const StepSubjects({super.key});

  @override
  ConsumerState<StepSubjects> createState() => _StepSubjectsState();
}

class _StepSubjectsState extends ConsumerState<StepSubjects> {
  String _subject = kSubjects.first;
  Level _level = Level.highSchool;

  void _add() {
    ref.read(tutorOnboardingControllerProvider.notifier).addSubject(
          TutorSubjectEntry(subject: _subject, level: _level),
        );
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        ref.watch(tutorOnboardingControllerProvider.select((s) => s.subjects));
    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepFieldLabel('Subject'),
        DropdownButtonFormField<String>(
          key: const ValueKey('onboarding_subject_dropdown'),
          value: _subject,
          items: [
            for (final s in kSubjects)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
          onChanged: (v) => setState(() => _subject = v ?? _subject),
        ),
        const SizedBox(height: 16),
        const StepFieldLabel('Level'),
        DropdownButtonFormField<Level>(
          key: const ValueKey('onboarding_level_dropdown'),
          value: _level,
          items: [
            for (final l in Level.values)
              DropdownMenuItem(value: l, child: Text(l.label)),
          ],
          onChanged: (v) => setState(() => _level = v ?? _level),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('onboarding_add_subject_button'),
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add subject'),
        ),
        const SizedBox(height: 24),
        if (entries.isEmpty)
          const StepInfoBanner('Add at least one subject and level you teach.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in entries)
                Chip(
                  label: Text('${e.subject} · ${e.level.label}'),
                  onDeleted: () => ctrl.removeSubject(e),
                ),
            ],
          ),
      ],
    );
  }
}
