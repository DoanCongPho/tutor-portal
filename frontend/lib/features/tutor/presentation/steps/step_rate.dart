import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/tutor_vocab.dart';
import '../tutor_onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 3 — set the hourly rate. Reproduces the reference mockup: a large coral
/// amount in a white card, a slider from 100k–1,000k, and an info banner.
class StepRate extends ConsumerWidget {
  const StepRate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate =
        ref.watch(tutorOnboardingControllerProvider.select((s) => s.hourlyRate));
    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatVnd(rate),
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '₫/hour',
                  style: text.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Slider(
          key: const ValueKey('onboarding_rate_slider'),
          min: kMinRate.toDouble(),
          max: kMaxRate.toDouble(),
          divisions: (kMaxRate - kMinRate) ~/ 10000, // 10k steps
          value: rate.clamp(kMinRate, kMaxRate).toDouble(),
          onChanged: (v) => ctrl.setRate(v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('100k', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            Text('1,000k', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 24),
        const StepInfoBanner(
          'Average rate for Math tutors in your area: 300k – 450k ₫/hour',
        ),
      ],
    );
  }
}
