import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';

class MedicineProgressPage extends StatefulWidget {
  final Medicine medicine;

  const MedicineProgressPage({super.key, required this.medicine});

  @override
  State<MedicineProgressPage> createState() => _MedicineProgressPageState();
}

class _MedicineProgressPageState extends State<MedicineProgressPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<MedicineDose> _doses = [];

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
        title: Text('${widget.medicine.name} Progress'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: BlocListener<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is DoseLoaded) {
            setState(() {
              _doses = state.doses;
            });
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCalendarTab(),
            _buildChartsTab(),
            _buildStatisticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: TableCalendar<MedicineDose>(
            firstDay: widget.medicine.startDate,
            lastDay:
                widget.medicine.endDate ??
                DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              markersMaxCount: 10,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.red[400]),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        Expanded(child: _buildDayDetails()),
      ],
    );
  }

  Widget _buildDayDetails() {
    final dayDoses = _getEventsForDay(_selectedDay);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(_selectedDay),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (dayDoses.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No doses scheduled for this day'),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: dayDoses.length,
                  itemBuilder: (context, index) {
                    final dose = dayDoses[index];
                    return _buildDoseCard(dose);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseCard(MedicineDose dose) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDoseStatusColor(dose.status).withOpacity(0.1),
          child: Icon(
            _getDoseStatusIcon(dose.status),
            color: _getDoseStatusColor(dose.status),
          ),
        ),
        title: Text(
          '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(dose.statusDisplayName),
        trailing: dose.status == DoseStatus.pending
            ? Row(
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
              )
            : Icon(
                _getDoseStatusIcon(dose.status),
                color: _getDoseStatusColor(dose.status),
              ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Progress Pie Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Overall Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: _buildProgressPieChartSections(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProgressLegend(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Weekly Adherence Chart
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Weekly Adherence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const titles = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  return Text(
                                    titles[value.toInt() % 7],
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}%');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _buildWeeklyAdherenceBarData(),
                        ),
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

  Widget _buildStatisticsTab() {
    final adherenceStats = _calculateAdherenceStatistics();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Adherence Rate',
                  '${adherenceStats['adherenceRate']?.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Streak',
                  '${adherenceStats['currentStreak']} days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Taken',
                  '${adherenceStats['totalTaken']}',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Missed',
                  '${adherenceStats['totalMissed']}',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Detailed Statistics
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detailed Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailedStatItem(
                      'Best Streak',
                      '${adherenceStats['bestStreak']} days',
                      Icons.star,
                    ),
                    _buildDetailedStatItem(
                      'Average Daily Adherence',
                      '${adherenceStats['dailyAdherence']?.toStringAsFixed(1)}%',
                      Icons.bar_chart,
                    ),
                    _buildDetailedStatItem(
                      'Days Completed',
                      '${adherenceStats['daysCompleted']} / ${widget.medicine.durationInDays}',
                      Icons.calendar_today,
                    ),
                    _buildDetailedStatItem(
                      'Days Remaining',
                      '${widget.medicine.remainingDays}',
                      Icons.schedule,
                    ),
                    _buildDetailedStatItem(
                      'Next Dose',
                      widget.medicine.getNextDoseTime() != null
                          ? _formatDateTime(widget.medicine.getNextDoseTime()!)
                          : 'No upcoming doses',
                      Icons.alarm,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProgressLegend() {
    final adherenceStats = _calculateAdherenceStatistics();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          'Taken',
          Colors.green,
          adherenceStats['totalTaken'] ?? 0,
        ),
        _buildLegendItem(
          'Skipped',
          Colors.orange,
          adherenceStats['totalSkipped'] ?? 0,
        ),
        _buildLegendItem(
          'Missed',
          Colors.red,
          adherenceStats['totalMissed'] ?? 0,
        ),
        _buildLegendItem(
          'Pending',
          Colors.blue,
          adherenceStats['totalPending'] ?? 0,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(count.toString(), style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  List<PieChartSectionData> _buildProgressPieChartSections() {
    final adherenceStats = _calculateAdherenceStatistics();
    final total =
        (adherenceStats['totalTaken'] ?? 0) +
        (adherenceStats['totalSkipped'] ?? 0) +
        (adherenceStats['totalMissed'] ?? 0) +
        (adherenceStats['totalPending'] ?? 0);

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No data',
          radius: 50,
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.green,
        value: ((adherenceStats['totalTaken'] ?? 0) / total * 100),
        title: '${adherenceStats['totalTaken']}',
        radius: 50,
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: ((adherenceStats['totalSkipped'] ?? 0) / total * 100),
        title: '${adherenceStats['totalSkipped']}',
        radius: 50,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: ((adherenceStats['totalMissed'] ?? 0) / total * 100),
        title: '${adherenceStats['totalMissed']}',
        radius: 50,
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: ((adherenceStats['totalPending'] ?? 0) / total * 100),
        title: '${adherenceStats['totalPending']}',
        radius: 50,
      ),
    ];
  }

  List<BarChartGroupData> _buildWeeklyAdherenceBarData() {
    // Calculate adherence for last 7 days
    final now = DateTime.now();
    final List<BarChartGroupData> barData = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayDoses = _getEventsForDay(day);

      double adherence = 0;
      if (dayDoses.isNotEmpty) {
        final takenDoses = dayDoses
            .where((dose) => dose.status == DoseStatus.taken)
            .length;
        adherence = (takenDoses / dayDoses.length) * 100;
      }

      barData.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: adherence,
              color: _getAdherenceColor(adherence),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barData;
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> _calculateAdherenceStatistics() {
    final takenDoses = _doses
        .where((dose) => dose.status == DoseStatus.taken)
        .length;
    final skippedDoses = _doses
        .where((dose) => dose.status == DoseStatus.skipped)
        .length;
    final missedDoses = _doses
        .where((dose) => dose.status == DoseStatus.missed)
        .length;
    final pendingDoses = _doses
        .where((dose) => dose.status == DoseStatus.pending)
        .length;

    final totalCompletedDoses = takenDoses + skippedDoses + missedDoses;
    final adherenceRate = totalCompletedDoses > 0
        ? (takenDoses / totalCompletedDoses) * 100
        : 0.0;

    // Calculate current streak
    int currentStreak = 0;
    final sortedDoses =
        _doses.where((dose) => dose.status != DoseStatus.pending).toList()
          ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    for (final dose in sortedDoses) {
      if (dose.status == DoseStatus.taken) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate best streak
    int bestStreak = 0;
    int tempStreak = 0;
    for (final dose in sortedDoses.reversed) {
      if (dose.status == DoseStatus.taken) {
        tempStreak++;
        bestStreak = tempStreak > bestStreak ? tempStreak : bestStreak;
      } else {
        tempStreak = 0;
      }
    }

    // Calculate days completed
    final uniqueDays = _doses
        .where((dose) => dose.status != DoseStatus.pending)
        .map(
          (dose) => DateTime(
            dose.scheduledTime.year,
            dose.scheduledTime.month,
            dose.scheduledTime.day,
          ),
        )
        .toSet()
        .length;

    return {
      'totalTaken': takenDoses,
      'totalSkipped': skippedDoses,
      'totalMissed': missedDoses,
      'totalPending': pendingDoses,
      'adherenceRate': adherenceRate,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'daysCompleted': uniqueDays,
      'dailyAdherence': adherenceRate,
    };
  }

  List<MedicineDose> _getEventsForDay(DateTime day) {
    return _doses.where((dose) {
      return isSameDay(dose.scheduledTime, day);
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
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
