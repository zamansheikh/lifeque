import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import 'add_edit_medicine_page.dart';

class MedicineDetailPage extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailPage({super.key, required this.medicine});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  MedicineDetailLoaded? _cachedDetail; // retain last detail snapshot
  @override
  void initState() {
    super.initState();
    context.read<MedicineCubit>().loadMedicineDetail(widget.medicine.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditMedicinePage(medicine: widget.medicine),
                ),
              );
              if (mounted) {
                context.read<MedicineCubit>().loadMedicineDetail(
                  widget.medicine.id,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MedicineCubit>().loadMedicineDetail(
              widget.medicine.id,
            ),
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineDetailLoaded &&
              state.medicine.id == widget.medicine.id) {
            setState(() => _cachedDetail = state);
          }
        },
        builder: (context, state) {
          if (state is MedicineError || state is DoseError) {
            final msg = state is MedicineError
                ? state.message
                : (state as DoseError).message;
            return Center(child: Text(msg));
          }
          if (_cachedDetail != null) {
            return _buildDetail(context, _cachedDetail!);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, MedicineDetailLoaded state) {
    final m = state.medicine;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CourseProgressCard(state: state),
        const SizedBox(height: 16),
        _InfoSection(medicine: m),
        const SizedBox(height: 16),
        _DoseHistorySection(state: state),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final MedicineDetailLoaded state;
  const _CourseProgressCard({required this.state});
  @override
  Widget build(BuildContext context) {
    final adherencePct = (state.adherencePercent * 100).toStringAsFixed(0);
    final daysPct = (state.daysElapsed / state.daysTotal * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _radialPercent(
                  label: 'Adherence',
                  value: state.adherencePercent,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statLine(
                        Icons.check,
                        'Taken',
                        state.taken,
                        Colors.green,
                      ),
                      _statLine(
                        Icons.hourglass_empty,
                        'Pending',
                        state.pending,
                        Colors.blue,
                      ),
                      _statLine(
                        Icons.cancel,
                        'Skipped',
                        state.skipped,
                        Colors.orange,
                      ),
                      _statLine(
                        Icons.error,
                        'Missed',
                        state.missed,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Days ${state.daysElapsed}/${state.daysTotal} ($daysPct%)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: state.daysElapsed / state.daysTotal,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.indigo),
            ),
            const SizedBox(height: 12),
            Text(
              'Adherence $adherencePct%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statLine(IconData icon, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color)),
          const Spacer(),
          Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _radialPercent({
    required String label,
    required double value,
    required Color color,
  }) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Medicine medicine;
  const _InfoSection({required this.medicine});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medicine Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow('Type', medicine.typeDisplayName),
            _infoRow('Dosage', medicine.dosageDisplay),
            _infoRow('Frequency', '${medicine.timesPerDay} times/day'),
            _infoRow('Timing', medicine.mealTimingDisplayName),
            _infoRow(
              'Start',
              '${medicine.startDate.day}/${medicine.startDate.month}/${medicine.startDate.year}',
            ),
            _infoRow(
              'End',
              '${medicine.calculatedEndDate.day}/${medicine.calculatedEndDate.month}/${medicine.calculatedEndDate.year}',
            ),
            if (medicine.doctorName != null)
              _infoRow('Doctor', medicine.doctorName!),
            if (medicine.notes != null) _infoRow('Notes', medicine.notes!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: medicine.notificationTimes
                  .map((t) => Chip(label: Text(t)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _DoseHistorySection extends StatelessWidget {
  final MedicineDetailLoaded state;
  const _DoseHistorySection({required this.state});

  Color _statusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.pending:
        return Colors.blue;
      case DoseStatus.skipped:
        return Colors.orange;
      case DoseStatus.missed:
        return Colors.red;
    }
  }

  IconData _statusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Icons.check_circle;
      case DoseStatus.pending:
        return Icons.hourglass_empty;
      case DoseStatus.skipped:
        return Icons.cancel;
      case DoseStatus.missed:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = state.dosesByDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dose History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...map.entries.map((e) {
              final date = e.key;
              final list = e.value;
              list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
              final taken = list
                  .where((d) => d.status == DoseStatus.taken)
                  .length;
              final total = list.length;
              return ExpansionTile(
                title: Text('${date.day}/${date.month}/${date.year}'),
                subtitle: Text('Taken $taken/$total'),
                children: list.map((d) {
                  final color = _statusColor(d.status);
                  return ListTile(
                    leading: Icon(_statusIcon(d.status), color: color),
                    title: Text(_fmtTime(d.scheduledTime)),
                    subtitle: Text(d.status.name.toUpperCase()),
                    trailing: Text(d.id.substring(d.id.length - 4)),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
