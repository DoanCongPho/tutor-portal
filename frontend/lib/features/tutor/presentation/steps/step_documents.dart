import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/tutor_vocab.dart';
import '../tutor_onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 4 — credential upload (degree, certificate, national ID). Real file
/// upload is skipped in v1, so each slot captures a file URL/reference string;
/// a filled slot shows the "success" state.
class StepDocuments extends ConsumerStatefulWidget {
  const StepDocuments({super.key});

  @override
  ConsumerState<StepDocuments> createState() => _StepDocumentsState();
}

class _StepDocumentsState extends ConsumerState<StepDocuments> {
  late final Map<DocType, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final docs = ref.read(tutorOnboardingControllerProvider).documents;
    _controllers = {
      for (final t in DocType.values)
        t: TextEditingController(text: docs[t] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);
    final docs =
        ref.watch(tutorOnboardingControllerProvider.select((s) => s.documents));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepInfoBanner(
          'Provide a link to each document (PDF or image). Upload from your '
          'device is coming soon.',
        ),
        const SizedBox(height: 16),
        for (final type in DocType.values) ...[
          Row(
            children: [
              Expanded(child: StepFieldLabel(type.label)),
              if ((docs[type] ?? '').isNotEmpty)
                const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            ],
          ),
          TextField(
            key: ValueKey('onboarding_doc_${type.api}'),
            controller: _controllers[type],
            keyboardType: TextInputType.url,
            onChanged: (v) => ctrl.setDocument(type, v),
            decoration: const InputDecoration(
              hintText: 'https://…/document.pdf',
              prefixIcon:
                  Icon(Icons.attach_file_outlined, color: AppTheme.authHint),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'At least one document is required to submit for review.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
