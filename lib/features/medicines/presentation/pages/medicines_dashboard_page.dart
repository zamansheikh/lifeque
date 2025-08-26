import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import 'add_edit_medicine_page.dart';
import 'medicine_detail_page.dart';

class MedicinesDashboardPage extends StatefulWidget {
  const MedicinesDashboardPage({super.key});
  @override
  State<MedicinesDashboardPage> createState() => _MedicinesDashboardPageState();
}

class _MedicinesDashboardPageState extends State<MedicinesDashboardPage> {
  DateTime _selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    context.read<MedicineCubit>().loadDashboard(date: _selectedDate);
  }

  void _refresh() =>
      context.read<MedicineCubit>().loadDashboard(date: _selectedDate);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Dashboard'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditMedicinePage()),
              );
              if (mounted) _refresh();
            },
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineError || state is DoseError) {
            final msg = state is MedicineError
                ? state.message
                : (state as DoseError).message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          } else if (state is DoseOperationSuccess ||
              state is MedicineOperationSuccess) {
            final msg = state is DoseOperationSuccess
                ? state.message
                : (state as MedicineOperationSuccess).message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state is MedicineLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MedicineDashboardLoaded) {
            final active = state.medicines
                .where((m) => m.status == MedicineStatus.active)
                .toList();
            if (active.isEmpty) {
              return _EmptyState(
                onAdd: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditMedicinePage(),
                    ),
                  );
                  if (mounted) _refresh();
                },
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DayHeader(
                    date: state.date,
                    onChange: (d) {
                      setState(() => _selectedDate = d);
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  _SummaryBar(doses: state.todayDoses),
                  const SizedBox(height: 16),
                  ...active.map(
                    (m) => _MedicineProgressCard(
                      medicine: m,
                      doses: state.dosesForMedicine(m.id),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            );
          }
          return const Center(child: Text('Loading dashboard...'));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No medicines yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add medicines to start tracking your doses.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChange;
  const _DayHeader({required this.date, required this.onChange});
  @override
  Widget build(BuildContext context) {
    final formatted = '${date.day}/${date.month}/${date.year}';
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChange(date.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: Center(
            child: Text(
              formatted,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChange(date.add(const Duration(days: 1))),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List<MedicineDose> doses;
  const _SummaryBar({required this.doses});
  @override
  Widget build(BuildContext context) {
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final skipped = doses.where((d) => d.status == DoseStatus.skipped).length;
    final missed = doses.where((d) => d.status == DoseStatus.missed).length;
    final pending = doses.where((d) => d.status == DoseStatus.pending).length;
    final total = doses.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CountChip(label: 'Taken', value: taken, color: Colors.green),
                _CountChip(
                  label: 'Pending',
                  value: pending,
                  color: Colors.blue,
                ),
                _CountChip(
                  label: 'Skipped',
                  value: skipped,
                  color: Colors.orange,
                ),
                _CountChip(label: 'Missed', value: missed, color: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : taken / total,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'Progress: ${total == 0 ? 0 : ((taken / total) * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: _bestShade(color))),
      ],
    );
  }

  Color _bestShade(Color base) {
    // If it's a MaterialColor, try shade700; else darken manually
    if (base is MaterialColor) {
      return base.shade700;
    }
    // Manual darken
    final h = base.computeLuminance();
    if (h > 0.5) {
      return Colors.black87;
    }
    return base.withOpacity(0.9);
  }
}

class _MedicineProgressCard extends StatelessWidget {
  final Medicine medicine;
  final List<MedicineDose> doses;
  const _MedicineProgressCard({required this.medicine, required this.doses});

  @override
  Widget build(BuildContext context) {
    // Today stats for this medicine
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final pending = doses.where((d) => d.status == DoseStatus.pending).length;
    final skipped = doses.where((d) => d.status == DoseStatus.skipped).length;
    final missed = doses.where((d) => d.status == DoseStatus.missed).length;
    final totalToday = doses.length;
    final pct = totalToday == 0 ? 0.0 : taken / totalToday;

    // Next pending / upcoming
    final now = DateTime.now();
    final upcoming =
        doses
            .where((d) => d.status == DoseStatus.pending)
            .where((d) => d.scheduledTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final next = upcoming.isNotEmpty ? upcoming.first : null;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MedicineDetailPage(medicine: medicine),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.12),
                    child: Icon(
                      Icons.medication,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${medicine.dosage} ${medicine.dosageUnit} • ${medicine.timesPerDay}x daily',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          medicine.mealTimingDisplayName,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _TodayStatusPill(taken: taken, total: totalToday),
                      IconButton(
                        tooltip: 'Details',
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => _showDetails(context),
                      ),
                    ],
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _miniChip(Icons.check, 'Taken $taken', Colors.green),
                  _miniChip(
                    Icons.hourglass_empty,
                    'Pending $pending',
                    Colors.blue,
                  ),
                  if (skipped > 0)
                    _miniChip(
                      Icons.skip_next,
                      'Skipped $skipped',
                      Colors.orange,
                    ),
                  if (missed > 0)
                    _miniChip(Icons.error, 'Missed $missed', Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: next == null
                        ? Text(
                            'Today completed',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            'Next: ${_fmt(next.scheduledTime)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                  ),
                  _ActionButtons(medicine: medicine, doses: doses),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final totalCourseDoses = medicine.totalDoses;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final taken = doses.where((d) => d.status == DoseStatus.taken).length;
        final skipped = doses
            .where((d) => d.status == DoseStatus.skipped)
            .length;
        final missed = doses.where((d) => d.status == DoseStatus.missed).length;
        final pending = doses
            .where((d) => d.status == DoseStatus.pending)
            .length;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditMedicinePage(medicineId: medicine.id),
                        ),
                      );
                      if (context.mounted)
                        context.read<MedicineCubit>().loadDashboard();
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Medicine'),
                          content: const Text(
                            'Are you sure you want to delete this medicine and its doses?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        Navigator.pop(ctx);
                        context.read<MedicineCubit>().deleteMedicine(
                          medicine.id,
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _miniChip(
                    Icons.calendar_today,
                    'Start ${medicine.startDate.day}/${medicine.startDate.month}',
                    Colors.blueGrey,
                  ),
                  _miniChip(
                    Icons.event,
                    'End ${medicine.calculatedEndDate.day}/${medicine.calculatedEndDate.month}',
                    Colors.blueGrey,
                  ),
                  _miniChip(
                    Icons.timelapse,
                    '${medicine.durationInDays} days',
                    Colors.indigo,
                  ),
                  _miniChip(
                    Icons.list_alt,
                    '$totalCourseDoses doses total',
                    Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Today',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _count('Taken', taken, Colors.green),
                  _count('Pending', pending, Colors.blue),
                  _count('Skipped', skipped, Colors.orange),
                  _count('Missed', missed, Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _count(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _TodayStatusPill extends StatelessWidget {
  final int taken;
  final int total;
  const _TodayStatusPill({required this.taken, required this.total});
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (taken / total * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Medicine medicine;
  final List<MedicineDose> doses;
  const _ActionButtons({required this.medicine, required this.doses});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MedicineCubit>();
    // Find earliest pending dose for actions
    final pending = doses.where((d) => d.status == DoseStatus.pending).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final target = pending.isNotEmpty ? pending.first : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Taken',
          onPressed: target == null
              ? null
              : () => cubit.markDoseAsTaken(target.id, medicine.id),
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
        IconButton(
          tooltip: 'Skip',
          onPressed: target == null
              ? null
              : () => cubit.markDoseAsSkipped(target.id, medicine.id),
          icon: const Icon(Icons.cancel, color: Colors.orange),
        ),
        IconButton(
          tooltip: 'Miss',
          onPressed: target == null
              ? null
              : () => cubit.markDoseAsMissed(target.id, medicine.id),
          icon: const Icon(Icons.error, color: Colors.red),
        ),
      ],
    );
  }
}
