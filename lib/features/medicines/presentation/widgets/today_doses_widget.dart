import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import '../pages/medicine_detail_page.dart';

class TodayDosesWidget extends StatefulWidget {
  const TodayDosesWidget({super.key});

  @override
  State<TodayDosesWidget> createState() => _TodayDosesWidgetState();
}

class _TodayDosesWidgetState extends State<TodayDosesWidget> {
  List<Medicine> _activeMedicines = [];
  // Pending doses list to determine next dose times (only pending considered)
  List<String> _pendingDoseIds = [];
  Map<String, List<DateTime>> _pendingDoseTimesByMedicine = {};

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MedicineCubit>();
    cubit.loadActiveMedicines().then((_) {
      cubit.getPendingDoses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MedicineCubit, MedicineState>(
      listener: (context, state) {
        if (state is MedicineLoaded) {
          _activeMedicines = state.medicines
              .where((m) => m.status == MedicineStatus.active)
              .toList();
        } else if (state is DoseLoaded) {
          // Capture pending doses only for next dose computation
          _pendingDoseTimesByMedicine.clear();
          _pendingDoseIds.clear();
          for (final dose in state.doses.where(
            (d) => d.status == DoseStatus.pending,
          )) {
            _pendingDoseIds.add(dose.id);
            _pendingDoseTimesByMedicine
                .putIfAbsent(dose.medicineId, () => [])
                .add(dose.scheduledTime);
          }
        }
        // Trigger rebuild
        setState(() {});
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_activeMedicines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Medicines',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_activeMedicines.length} active',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._activeMedicines.map(_buildMedicineItem),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/medicines'),
                child: const Text('View All Medicines'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(Medicine medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getMedicineIcon(medicine.type),
              size: 20,
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${medicine.dosage} ${medicine.dosageUnit} • ${medicine.timesPerDay}x daily',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNextDoseInfo(medicine),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _navigateToMedicineDetail(medicine),
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextDoseInfo(Medicine medicine) {
    final now = DateTime.now();
    final pendingTimes = _pendingDoseTimesByMedicine[medicine.id];
    if (pendingTimes == null || pendingTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Complete',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      );
    }
    // Filter out past doses older than an hour (treated as missed / handled elsewhere)
    final upcoming =
        pendingTimes
            .where((t) => t.isAfter(now.subtract(const Duration(hours: 1))))
            .toList()
          ..sort();
    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Complete',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      );
    }
    final next = upcoming.first;
    final difference = next.difference(now);
    final isOverdue = difference.isNegative;
    String timeText;
    Color backgroundColor;
    Color textColor;
    if (isOverdue) {
      final overdueDuration = now.difference(next);
      timeText = overdueDuration.inHours > 0
          ? '${overdueDuration.inHours}h overdue'
          : '${overdueDuration.inMinutes}m overdue';
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[700]!;
    } else {
      if (difference.inHours > 0) {
        timeText = '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        timeText = '${difference.inMinutes}m';
      }
      if (difference.inMinutes <= 30) {
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
      } else {
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  IconData _getMedicineIcon(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return Icons.medication;
      case MedicineType.capsule:
        return Icons.medication_outlined;
      case MedicineType.syrup:
        return Icons.local_drink;
      case MedicineType.injection:
        return Icons.medical_services;
      case MedicineType.drops:
        return Icons.water_drop;
      case MedicineType.cream:
        return Icons.palette;
      case MedicineType.spray:
        return Icons.air;
      case MedicineType.other:
        return Icons.healing;
    }
  }

  void _navigateToMedicineDetail(Medicine medicine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicineDetailPage(medicine: medicine),
      ),
    );
  }
}
