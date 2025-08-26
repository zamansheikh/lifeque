import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import 'add_edit_medicine_page.dart';
import 'medicine_progress_page.dart';

class MedicineDetailPage extends StatefulWidget {
  final Medicine medicine;

  const MedicineDetailPage({super.key, required this.medicine});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MedicineCubit>().getDosesForMedicine(widget.medicine.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      MedicineProgressPage(medicine: widget.medicine),
                ),
              );
            },
            tooltip: 'View Progress Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditMedicinePage(medicine: widget.medicine),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Doses'),
            Tab(text: 'Progress'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildDosesTab(), _buildProgressTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedicineInfoCard(),
          const SizedBox(height: 16),
          _buildDosageInfoCard(),
          const SizedBox(height: 16),
          _buildTimingInfoCard(),
          const SizedBox(height: 16),
          _buildDurationInfoCard(),
          if (widget.medicine.doctorName != null ||
              widget.medicine.notes != null) ...[
            const SizedBox(height: 16),
            _buildAdditionalInfoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMedicineTypeIcon(widget.medicine.type),
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.medicine.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getMedicineTypeDisplayName(widget.medicine.type),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.medicine.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.medicine.statusDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(widget.medicine.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.medicine.description != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.medicine.description!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDosageInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dosage Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  'Dosage',
                  '${widget.medicine.dosage} ${widget.medicine.dosageUnit}',
                  Icons.medication_liquid,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  'Frequency',
                  '${widget.medicine.timesPerDay}x daily',
                  Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Meal Timing',
              widget.medicine.mealTimingDisplayName,
              Icons.restaurant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Times',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.medicine.notificationTimes
                  .map(
                    (time) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duration & Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Duration',
                    '${widget.medicine.durationInDays} days',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Progress',
                    '${widget.medicine.progressPercentage.toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: widget.medicine.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Started: ${_formatDate(widget.medicine.startDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (widget.medicine.endDate != null)
                  Text(
                    'Ends: ${_formatDate(widget.medicine.endDate!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.medicine.doctorName != null)
              _buildInfoItem(
                'Doctor',
                widget.medicine.doctorName!,
                Icons.person,
              ),
            if (widget.medicine.notes != null) ...[
              const SizedBox(height: 12),
              _buildInfoItem('Notes', widget.medicine.notes!, Icons.note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDosesTab() {
    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        if (state is DoseLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DoseLoaded) {
          return Column(
            children: [
              _buildQuickDoseActions(state.doses),
              Expanded(child: _buildDosesList(state.doses)),
            ],
          );
        } else if (state is DoseError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                ElevatedButton(
                  onPressed: () {
                    context.read<MedicineCubit>().getDosesForMedicine(
                      widget.medicine.id,
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No doses available'));
      },
    );
  }

  Widget _buildQuickDoseActions(List<MedicineDose> doses) {
    final now = DateTime.now();
    final pendingDoses =
        doses
            .where(
              (dose) =>
                  dose.status == DoseStatus.pending &&
                  dose.scheduledTime.isBefore(
                    now.add(const Duration(hours: 2)),
                  ),
            )
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (pendingDoses.isEmpty) {
      return const SizedBox.shrink();
    }

    final nextDose = pendingDoses.first;
    final isOverdue = now.isAfter(nextDose.scheduledTime);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red : Colors.blue,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isOverdue ? Icons.warning : Icons.schedule,
                color: isOverdue ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverdue ? 'Overdue Dose' : 'Next Dose',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.blue,
                      ),
                    ),
                    Text(
                      '${nextDose.scheduledTime.hour.toString().padLeft(2, '0')}:${nextDose.scheduledTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<MedicineCubit>().markDoseAsTaken(
                      nextDose.id,
                      nextDose.medicineId,
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Take Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<MedicineCubit>().markDoseAsSkipped(
                      nextDose.id,
                      nextDose.medicineId,
                    );
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDosesList(List<MedicineDose> doses) {
    if (doses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No doses scheduled yet'),
          ],
        ),
      );
    }

    // Group doses by date
    final groupedDoses = <DateTime, List<MedicineDose>>{};
    for (final dose in doses) {
      final date = DateTime(
        dose.scheduledTime.year,
        dose.scheduledTime.month,
        dose.scheduledTime.day,
      );
      groupedDoses[date] = [...(groupedDoses[date] ?? []), dose];
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedDoses.length,
      itemBuilder: (context, index) {
        final date = groupedDoses.keys.toList()[index];
        final dayDoses = groupedDoses[date]!;
        return _buildDayDosesCard(date, dayDoses);
      },
    );
  }

  Widget _buildDayDosesCard(DateTime date, List<MedicineDose> doses) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...doses.map((dose) => _buildDoseItem(dose)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseItem(MedicineDose dose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getDoseStatusIcon(dose.status),
            color: _getDoseStatusColor(dose.status),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  dose.statusDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getDoseStatusColor(dose.status),
                  ),
                ),
              ],
            ),
          ),
          if (dose.status == DoseStatus.pending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    context.read<MedicineCubit>().markDoseAsTaken(
                      dose.id,
                      dose.medicineId,
                    );
                  },
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Mark as taken',
                ),
                IconButton(
                  onPressed: () {
                    context.read<MedicineCubit>().markDoseAsSkipped(
                      dose.id,
                      dose.medicineId,
                    );
                  },
                  icon: const Icon(Icons.close, color: Colors.orange),
                  tooltip: 'Mark as skipped',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: widget.medicine.progressPercentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${widget.medicine.progressPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Days completed: ${(widget.medicine.progressPercentage * widget.medicine.durationInDays / 100).round()} / ${widget.medicine.durationInDays}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem(
                      'Days Remaining',
                      '${widget.medicine.remainingDays}',
                    ),
                    _buildStatItem(
                      'Total Doses',
                      '${widget.medicine.totalDoses}',
                    ),
                    if (widget.medicine.getNextDoseTime() != null)
                      _buildStatItem(
                        'Next Dose',
                        _formatDateTime(widget.medicine.getNextDoseTime()!),
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  IconData _getMedicineTypeIcon(MedicineType type) {
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
        return Icons.help_outline;
    }
  }

  String _getMedicineTypeDisplayName(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return 'Tablet';
      case MedicineType.capsule:
        return 'Capsule';
      case MedicineType.syrup:
        return 'Syrup';
      case MedicineType.injection:
        return 'Injection';
      case MedicineType.drops:
        return 'Drops';
      case MedicineType.cream:
        return 'Cream';
      case MedicineType.spray:
        return 'Spray';
      case MedicineType.other:
        return 'Other';
    }
  }

  Color _getStatusColor(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.active:
        return Colors.green;
      case MedicineStatus.completed:
        return Colors.blue;
      case MedicineStatus.paused:
        return Colors.orange;
      case MedicineStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getDoseStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.pending:
        return Icons.schedule;
      case DoseStatus.taken:
        return Icons.check_circle;
      case DoseStatus.skipped:
        return Icons.cancel;
      case DoseStatus.missed:
        return Icons.error;
    }
  }

  Color _getDoseStatusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.pending:
        return Colors.orange;
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.skipped:
        return Colors.blue;
      case DoseStatus.missed:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
