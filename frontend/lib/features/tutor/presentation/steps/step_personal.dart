import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../tutor_onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 1 — personal info (name, phone, avatar). Avatar upload is skipped in
/// v1, so the avatar field takes a URL/reference string.
class StepPersonal extends ConsumerStatefulWidget {
  const StepPersonal({super.key});

  @override
  ConsumerState<StepPersonal> createState() => _StepPersonalState();
}

class _StepPersonalState extends ConsumerState<StepPersonal> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _avatar;

  @override
  void initState() {
    super.initState();
    final s = ref.read(tutorOnboardingControllerProvider);
    _name = TextEditingController(text: s.name);
    _phone = TextEditingController(text: s.phone);
    _avatar = TextEditingController(text: s.avatarUrl);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepFieldLabel('Full Name'),
        TextField(
          key: const ValueKey('onboarding_name_field'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => ctrl.setPersonal(name: v),
          decoration: const InputDecoration(
            hintText: 'Nguyễn Văn A',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.authHint),
          ),
        ),
        const SizedBox(height: 16),
        const StepFieldLabel('Phone Number'),
        TextField(
          key: const ValueKey('onboarding_phone_field'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          onChanged: (v) => ctrl.setPersonal(phone: v),
          decoration: const InputDecoration(
            hintText: '+84 xxx xxx xxx',
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.authHint),
          ),
        ),
        const SizedBox(height: 16),
        const StepFieldLabel('Avatar (optional)'),
        TextField(
          key: const ValueKey('onboarding_avatar_field'),
          controller: _avatar,
          keyboardType: TextInputType.url,
          onChanged: (v) => ctrl.setPersonal(avatarUrl: v),
          decoration: const InputDecoration(
            hintText: 'https://…/photo.jpg',
            prefixIcon: Icon(Icons.image_outlined, color: AppTheme.authHint),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photo upload is coming soon — paste an image URL for now.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
