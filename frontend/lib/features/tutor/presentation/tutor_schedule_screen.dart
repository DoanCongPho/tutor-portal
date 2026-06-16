import 'package:flutter/material.dart';

/// Tutor weekly schedule (the "Tutor / Schedule" mockup): a week-day selector
/// over a timeline of availability and booked sessions.
///
/// The week and slots are placeholder data — schedule management isn't wired to
/// the backend yet. Replace `_sampleDays` / `_sampleSlots` with real providers
/// (GET the tutor's schedules + bookings) once that lands.
class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends State<TutorScheduleScreen> {
  int _selected = 2; // Wed in the mockup.

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Schedule',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            key: const ValueKey('schedule_add_button'),
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WeekStrip(
              days: _sampleDays,
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _sampleSlots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _SlotRow(slot: _sampleSlots[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final List<_Day> days;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        days[i].weekday,
                        style: text.labelSmall?.copyWith(
                          color: i == selected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days[i].date,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: i == selected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot});
  final _Slot slot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final available = slot.booking == null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              slot.start,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: available
                  ? scheme.primaryContainer.withValues(alpha: 0.5)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: available ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available ? 'Available' : slot.booking!.subject,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: available ? scheme.primary : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available
                      ? '${slot.start} - ${slot.end}'
                      : '${slot.start} - ${slot.end} • Booked',
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Placeholder data (replace with real schedule + booking providers). ---

class _Day {
  const _Day(this.weekday, this.date);
  final String weekday;
  final String date;
}

const _sampleDays = <_Day>[
  _Day('Mon', '13'),
  _Day('Tue', '14'),
  _Day('Wed', '15'),
  _Day('Thu', '16'),
  _Day('Fri', '17'),
  _Day('Sat', '18'),
  _Day('Sun', '19'),
];

class _Booking {
  const _Booking(this.subject);
  final String subject;
}

class _Slot {
  const _Slot({required this.start, required this.end, this.booking});
  final String start;
  final String end;
  final _Booking? booking;
}

const _sampleSlots = <_Slot>[
  _Slot(start: '08:00', end: '09:00'),
  _Slot(start: '10:00', end: '11:00', booking: _Booking('Toán - Nguyễn Hà')),
  _Slot(start: '14:00', end: '15:30', booking: _Booking('Vật lý - Lê Hoàng')),
  _Slot(start: '16:00', end: '17:00'),
  _Slot(start: '18:00', end: '19:00'),
];
