import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tutor_profile.dart';
import '../../domain/tutor_vocab.dart';
import '../tutor_onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 5 — weekly availability. Each slot is a day + start/end time, stored as
/// a row in `schedules`.
class StepSchedule extends ConsumerStatefulWidget {
  const StepSchedule({super.key});

  @override
  ConsumerState<StepSchedule> createState() => _StepScheduleState();
}

class _StepScheduleState extends ConsumerState<StepSchedule> {
  int _day = 1; // Monday
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  void _add() {
    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    ref.read(tutorOnboardingControllerProvider.notifier).addSlot(
          ScheduleSlot(
            dayOfWeek: _day,
            startTime: _fmt(_start),
            endTime: _fmt(_end),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final slots =
        ref.watch(tutorOnboardingControllerProvider.select((s) => s.schedule));
    final ctrl = ref.read(tutorOnboardingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepFieldLabel('Day of week'),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < kDayLabels.length; i++)
              ChoiceChip(
                label: Text(kDayLabels[i]),
                selected: _day == i,
                onSelected: (_) => setState(() => _day = i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('onboarding_start_time'),
                onPressed: () => _pick(true),
                child: Text('Start: ${_fmt(_start)}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('onboarding_end_time'),
                onPressed: () => _pick(false),
                child: Text('End: ${_fmt(_end)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('onboarding_add_slot_button'),
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add availability'),
        ),
        const SizedBox(height: 24),
        if (slots.isEmpty)
          const StepInfoBanner('Add at least one weekly availability slot.')
        else
          ...slots.asMap().entries.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.event_available, color: scheme.primary),
                    title: Text(kDayLabels[e.value.dayOfWeek]),
                    subtitle: Text('${e.value.startTime} – ${e.value.endTime}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ctrl.removeSlotAt(e.key),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
