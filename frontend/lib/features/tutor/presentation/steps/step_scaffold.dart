import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Small heading shown above an input, matching the auth screens' field labels.
class StepFieldLabel extends StatelessWidget {
  const StepFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}

/// Soft blue informational banner (e.g. the "Average rate …" note in the
/// hourly-rate mockup). Intentionally not coral — coral is reserved for the CTA.
class StepInfoBanner extends StatelessWidget {
  const StepInfoBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoBannerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.infoBannerFg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.infoBannerFg),
            ),
          ),
        ],
      ),
    );
  }
}
