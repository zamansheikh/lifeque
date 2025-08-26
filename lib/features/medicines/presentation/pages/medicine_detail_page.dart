import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';

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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Navigate to edit page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit functionality coming soon')),
                );
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
      body: BlocListener<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MedicineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DoseLoaded) {
            // Doses loaded - UI will be rebuilt automatically
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildDosesTab(),
            _buildProgressTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMedicineInfoCard(),
          const SizedBox(height: 16),
          _buildDosageInfoCard(),
          const SizedBox(height: 16),
          _buildTimingInfoCard(),
          const SizedBox(height: 16),
          _buildDurationInfoCard(),
          const SizedBox(height: 16),
          _buildAdditionalInfoCard(),
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
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.medication,
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
                        widget.medicine.typeDisplayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.medicine.description?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.medicine.description!),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Dosage', widget.medicine.dosageDisplay, Icons.medication_liquid),
            _buildInfoItem('Type', widget.medicine.typeDisplayName, Icons.category),
            _buildInfoItem('Times per day', '${widget.medicine.timesPerDay}', Icons.schedule),
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
              'Timing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'Times',
              widget.medicine.notificationTimes.join(', '),
              Icons.access_time,
            ),
            _buildInfoItem('Meal timing', widget.medicine.mealTimingDisplayName, Icons.restaurant),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Start Date', _formatDate(widget.medicine.startDate), Icons.calendar_today),
            _buildInfoItem('End Date', _formatDate(widget.medicine.calculatedEndDate), Icons.event),
            _buildInfoItem('Duration', '${widget.medicine.durationInDays} days', Icons.timelapse),
            _buildInfoItem('Remaining', '${widget.medicine.remainingDays} days', Icons.today),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${(widget.medicine.progressPercentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.medicine.progressPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Status', widget.medicine.statusDisplayName, Icons.info),
            if (widget.medicine.doctorName?.isNotEmpty == true)
              _buildInfoItem('Doctor', widget.medicine.doctorName!, Icons.person),
            if (widget.medicine.notes?.isNotEmpty == true)
              _buildInfoItem('Notes', widget.medicine.notes!, Icons.note),
            _buildInfoItem('Total Doses', '${widget.medicine.totalDoses}', Icons.medication),
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
          final doses = state.doses;
          return Column(
            children: [
              if (doses.isNotEmpty) _buildQuickDoseActions(doses),
              Expanded(child: _buildDosesList(doses)),
            ],
          );
        } else if (state is DoseError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MedicineCubit>().getDosesForMedicine(widget.medicine.id);
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
    final pendingDoses = doses.where((dose) => 
      dose.status == DoseStatus.pending &&
      dose.scheduledTime.isBefore(now.add(const Duration(hours: 1)))
    ).toList();

    if (pendingDoses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...pendingDoses.map((dose) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      dose.isDueSoon ? Icons.notification_important : Icons.schedule,
                      color: dose.isDueSoon ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dose.isDueSoon ? 'Due soon' : 'Upcoming',
                            style: TextStyle(
                              color: dose.isDueSoon ? Colors.orange : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            context.read<MedicineCubit>().markDoseAsTaken(dose.id, dose.medicineId);
                          },
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Mark as taken',
                        ),
                        IconButton(
                          onPressed: () {
                            context.read<MedicineCubit>().markDoseAsSkipped(dose.id, dose.medicineId);
                          },
                          icon: const Icon(Icons.close, color: Colors.orange),
                          tooltip: 'Mark as skipped',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDosesList(List<MedicineDose> doses) {
    if (doses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No doses scheduled yet'),
            const SizedBox(height: 8),
            const Text(
              'Doses will be generated automatically based on your medicine schedule',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group doses by date
    final groupedDoses = <DateTime, List<MedicineDose>>{};
    for (final dose in doses) {
      final dateKey = DateTime(dose.scheduledTime.year, dose.scheduledTime.month, dose.scheduledTime.day);
      groupedDoses.putIfAbsent(dateKey, () => []).add(dose);
    }

    final sortedDates = groupedDoses.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayDoses = groupedDoses[date]!;
        dayDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        return _buildDayDosesCard(date, dayDoses);
      },
    );
  }

  Widget _buildDayDosesCard(DateTime date, List<MedicineDose> doses) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getDoseStatusColor(dose.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dose.statusDisplayName,
              style: TextStyle(
                color: _getDoseStatusColor(dose.status),
                fontSize: 14,
              ),
            ),
          ),
          if (dose.status == DoseStatus.pending) ...[
            IconButton(
              onPressed: () {
                context.read<MedicineCubit>().markDoseAsTaken(dose.id, dose.medicineId);
              },
              icon: const Icon(Icons.check, size: 20, color: Colors.green),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              onPressed: () {
                context.read<MedicineCubit>().markDoseAsSkipped(dose.id, dose.medicineId);
              },
              icon: const Icon(Icons.close, size: 20, color: Colors.orange),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        if (state is DoseLoaded) {
          final allDoses = state.doses;
          final totalDoses = allDoses.length;
          final takenDoses = allDoses.where((dose) => dose.status == DoseStatus.taken).length;
          final completionRate = totalDoses > 0 ? (takenDoses / totalDoses * 100).round() : 0;
          
          // Group doses by date for weekly/monthly stats
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final monthAgo = now.subtract(const Duration(days: 30));
          
          final weeklyDoses = allDoses.where((dose) => 
            dose.scheduledTime.isAfter(weekAgo)
          ).toList();
          final monthlyDoses = allDoses.where((dose) => 
            dose.scheduledTime.isAfter(monthAgo)
          ).toList();
          
          final weeklyTaken = weeklyDoses.where((dose) => dose.status == DoseStatus.taken).length;
          final monthlyTaken = monthlyDoses.where((dose) => dose.status == DoseStatus.taken).length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Progress Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Completion Rate'),
                                  Text(
                                    '$completionRate%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: completionRate >= 80 ? Colors.green : 
                                             completionRate >= 60 ? Colors.orange : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Doses'),
                                  Text(
                                    '$takenDoses / $totalDoses',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: totalDoses > 0 ? takenDoses / totalDoses : 0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                            completionRate >= 80 ? Colors.green : 
                            completionRate >= 60 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Weekly Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Week',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$weeklyTaken / ${weeklyDoses.length} doses taken'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Monthly Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$monthlyTaken / ${monthlyDoses.length} doses taken'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return const Center(child: Text('No progress data available'));
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medicine'),
          content: Text('Are you sure you want to delete "${widget.medicine.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<MedicineCubit>().deleteMedicine(widget.medicine.id);
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getDoseStatusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.skipped:
        return Colors.orange;
      case DoseStatus.missed:
        return Colors.red;
      case DoseStatus.pending:
        return Colors.grey;
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (dateOnly == todayOnly) {
      return 'Today';
    } else if (dateOnly == todayOnly.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly == todayOnly.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
