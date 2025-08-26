import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import '../../domain/entities/medicine.dart';
import 'add_edit_medicine_page.dart';
import 'medicine_detail_page.dart';

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MedicineCubit>().loadAllMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MedicineCubit>().loadAllMedicines();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MedicineOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MedicineLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicineLoaded) {
            return _buildMedicinesList(state.medicines);
          } else if (state is MedicineError) {
            return _buildErrorView(state.message);
          } else if (state is DoseLoaded ||
              state is DoseLoading ||
              state is DoseError) {
            // If we're in a dose-related state, reload medicines
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<MedicineCubit>().loadAllMedicines();
              }
            });
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(
              child: Text('Start by adding your first medicine'),
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "dose_action",
            onPressed: () => _showQuickDoseAction(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.medication, color: Colors.white),
            tooltip: 'Quick Dose Action',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "add_medicine",
            onPressed: () => _showAddMedicineDialog(context),
            child: const Icon(Icons.add),
            tooltip: 'Add Medicine',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList(List<Medicine> medicines) {
    if (medicines.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<MedicineCubit>().loadAllMedicines();
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No medicines added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first medicine',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MedicineCubit>().loadAllMedicines();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          final medicine = medicines[index];
          return _buildMedicineCard(medicine);
        },
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editMedicine(medicine),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMedicineIcon(medicine.type),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (medicine.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            medicine.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: medicine.status == MedicineStatus.active
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      medicine.statusDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: medicine.status == MedicineStatus.active
                            ? Colors.green[700]
                            : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.schedule,
                    '${medicine.timesPerDay}x daily',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.restaurant,
                    medicine.mealTimingDisplayName,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${medicine.durationInDays} days',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Dosage: ${medicine.dosage} ${medicine.dosageUnit}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    'Progress: ${medicine.progressPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: medicine.progressPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MedicineCubit>().loadAllMedicines();
            },
            child: const Text('Retry'),
          ),
        ],
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

  void _showAddMedicineDialog(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditMedicinePage()),
    );
    // Refresh medicines list when returning from add/edit page
    if (mounted) {
      context.read<MedicineCubit>().loadAllMedicines();
    }
  }

  void _showQuickDoseAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<MedicineCubit, MedicineState>(
        builder: (context, state) {
          if (state is MedicineLoaded) {
            final activeMedicines = state.medicines
                .where((medicine) => medicine.status == MedicineStatus.active)
                .toList();

            if (activeMedicines.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Active Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Add some medicines to track doses'),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Dose Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...activeMedicines
                      .map(
                        (medicine) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getMedicineIcon(medicine.type),
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(medicine.name),
                          subtitle: Text(
                            '${medicine.dosage} ${medicine.dosageUnit}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Note: This is a simplified action - in real implementation,
                                  // you'd need to get the current pending dose and mark it
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${medicine.name} dose taken!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                tooltip: 'Mark as taken',
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${medicine.name} dose skipped',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Skip dose',
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _editMedicine(medicine);
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _editMedicine(Medicine medicine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicineDetailPage(medicine: medicine),
      ),
    );
    // Refresh medicines list when returning from detail page
    if (mounted) {
      context.read<MedicineCubit>().loadAllMedicines();
    }
  }
}
