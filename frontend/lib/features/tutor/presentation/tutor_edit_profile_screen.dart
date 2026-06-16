import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../data/tutor_profile_provider.dart';
import '../data/tutor_repository.dart';
import '../domain/tutor_profile.dart';
import '../domain/tutor_vocab.dart';
import 'tutor_onboarding_controller.dart' show kMinRate, kMaxRate, kDefaultRate;

/// Edit form for the tutor profile. Pre-filled from the saved profile; on Save
/// it re-submits the full aggregate via POST /tutors/onboarding (an upsert).
///
/// Because that endpoint replaces the subject and schedule sets, the existing
/// schedule is resent unchanged so editing personal info / rate / subjects never
/// wipes availability. Re-submitting also re-enters the verification queue
/// (verification_status → pending_review), which the success message calls out.
class TutorEditProfileScreen extends ConsumerStatefulWidget {
  const TutorEditProfileScreen({super.key});

  @override
  ConsumerState<TutorEditProfileScreen> createState() =>
      _TutorEditProfileScreenState();
}

class _TutorEditProfileScreenState
    extends ConsumerState<TutorEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  int _rate = kDefaultRate;
  List<TutorSubjectEntry> _subjects = const [];
  List<ScheduleSlot> _schedule = const []; // preserved, resent unchanged.

  String _pickSubject = kSubjects.first;
  Level _pickLevel = Level.highSchool;

  bool _initialized = false;
  bool _saving = false;

  void _initFrom(TutorProfile p) {
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone ?? '';
    _bioCtrl.text = p.bio ?? '';
    _rate = p.hourlyRate.clamp(kMinRate, kMaxRate).toInt();
    _subjects = List.of(p.subjects);
    _schedule = p.schedule;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _addSubject() {
    final entry = TutorSubjectEntry(subject: _pickSubject, level: _pickLevel);
    if (_subjects.contains(entry)) return;
    setState(() => _subjects = [..._subjects, entry]);
  }

  void _removeSubject(TutorSubjectEntry e) =>
      setState(() => _subjects = _subjects.where((x) => x != e).toList());

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Please enter your name.');
      return;
    }
    if (_subjects.isEmpty) {
      _snack('Add at least one subject you teach.');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'name': name,
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        'hourly_rate': _rate,
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
        'subjects': _subjects.map((s) => s.toJson()).toList(),
        'documents': const <Map<String, dynamic>>[],
        'schedule': _schedule.map((s) => s.toJson()).toList(),
      };
      await ref.read(tutorRepositoryProvider).submitOnboarding(payload);
      ref.invalidate(tutorProfileProvider);
      if (!mounted) return;
      await _showSuccess();
      if (!mounted) return;
      context.go(AppRoutes.tutorProfile);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showSuccess() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _SuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final profileAsync = ref.watch(tutorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.tutorProfile),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              "Couldn't load your profile.",
              style: text.titleMedium,
            ),
          ),
          data: (profile) {
            if (!_initialized) _initFrom(profile);
            return _form(context);
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  const _FieldLabel('Full name'),
                  TextField(
                    key: const ValueKey('edit_name_field'),
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Phone'),
                  TextField(
                    key: const ValueKey('edit_phone_field'),
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('About you'),
                  TextField(
                    key: const ValueKey('edit_bio_field'),
                    controller: _bioCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Tell families about your experience',
                    ),
                  ),
                  const SizedBox(height: 24),

                  _FieldLabel('Hourly rate · ${formatVnd(_rate)} đ'),
                  Slider(
                    value: _rate.toDouble(),
                    min: kMinRate.toDouble(),
                    max: kMaxRate.toDouble(),
                    divisions: (kMaxRate - kMinRate) ~/ 50000,
                    label: '${formatVnd(_rate)} đ',
                    onChanged: (v) =>
                        setState(() => _rate = (v ~/ 50000) * 50000),
                  ),
                  const SizedBox(height: 8),

                  const _FieldLabel('Subjects & levels'),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('edit_subject_dropdown'),
                          value: _pickSubject,
                          isExpanded: true,
                          items: [
                            for (final s in kSubjects)
                              DropdownMenuItem(value: s, child: Text(s)),
                          ],
                          onChanged: (v) =>
                              setState(() => _pickSubject = v ?? _pickSubject),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<Level>(
                          key: const ValueKey('edit_level_dropdown'),
                          value: _pickLevel,
                          isExpanded: true,
                          items: [
                            for (final l in Level.values)
                              DropdownMenuItem(value: l, child: Text(l.label)),
                          ],
                          onChanged: (v) =>
                              setState(() => _pickLevel = v ?? _pickLevel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('edit_add_subject_button'),
                    onPressed: _addSubject,
                    icon: const Icon(Icons.add),
                    label: const Text('Add subject'),
                  ),
                  const SizedBox(height: 16),
                  if (_subjects.isEmpty)
                    Text(
                      'Add at least one subject and level you teach.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in _subjects)
                          Chip(
                            label: Text('${e.subject} · ${e.level.label}'),
                            onDeleted: () => _removeSubject(e),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            _SaveBar(saving: _saving, onSave: _saving ? null : _save),
          ],
        ),
      ),
    );
  }
}

/// Celebratory confirmation shown after a successful re-submission. A spring-in
/// check badge, then a short note that the profile is back in the review queue.
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, t, child) => Transform.scale(
                scale: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
                child: child,
              ),
              child: Container(
                height: 88,
                width: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile updated',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Your changes are saved and your profile has re-entered the '
              'verification queue. We’ll notify you once it’s reviewed.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 16,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pending review',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('edit_success_done_button'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onSave});
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: FilledButton(
        key: const ValueKey('edit_save_button'),
        onPressed: onSave,
        child: saving
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            : const Text('Save Changes'),
      ),
    );
  }
}
