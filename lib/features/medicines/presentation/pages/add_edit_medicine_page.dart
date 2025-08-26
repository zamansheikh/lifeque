import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/medicine.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';

class AddEditMedicinePage extends StatefulWidget {
  final String? medicineId;
  final Medicine? medicine;

  const AddEditMedicinePage({super.key, this.medicineId, this.medicine});

  @override
  State<AddEditMedicinePage> createState() => _AddEditMedicinePageState();
}

class _AddEditMedicinePageState extends State<AddEditMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _dosageUnitController = TextEditingController();
  final _durationController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();

  MedicineType _selectedType = MedicineType.tablet;
  MealTiming _selectedMealTiming = MealTiming.anytime;
  int _timesPerDay = 1;
  DateTime _startDate = DateTime.now();
  List<TimeOfDay> _notificationTimes = [TimeOfDay.now()];

  bool get _isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.medicine != null) {
      _populateFields(widget.medicine!);
    }
  }

  void _populateFields(Medicine medicine) {
    _nameController.text = medicine.name;
    _descriptionController.text = medicine.description ?? '';
    _dosageController.text = medicine.dosage.toString();
    _dosageUnitController.text = medicine.dosageUnit;
    _durationController.text = medicine.durationInDays.toString();
    _doctorController.text = medicine.doctorName ?? '';
    _notesController.text = medicine.notes ?? '';

    _selectedType = medicine.type;
    _selectedMealTiming = medicine.mealTiming;
    _timesPerDay = medicine.timesPerDay;
    _startDate = medicine.startDate;

    _notificationTimes = medicine.notificationTimes.map((timeString) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _dosageUnitController.dispose();
    _durationController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: _saveMedicine,
              icon: const Icon(
                Icons.save_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
            context.pop();
          } else if (state is MedicineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildMedicineDetailsSection(),
              const SizedBox(height: 24),
              _buildDosageSection(),
              const SizedBox(height: 24),
              _buildTimingSection(),
              const SizedBox(height: 24),
              _buildDurationSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Medicine Name',
              hintText: 'e.g., Paracetamol',
              prefixIcon: const Icon(
                Icons.medication_rounded,
                color: Color(0xFF3B82F6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter medicine name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'e.g., For fever and pain relief',
              prefixIcon: const Icon(
                Icons.description_rounded,
                color: Color(0xFF3B82F6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medicine Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MedicineType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Medicine Type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: MedicineType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getMedicineTypeIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getMedicineTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealTiming>(
              value: _selectedMealTiming,
              decoration: const InputDecoration(
                labelText: 'Meal Timing',
                prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(),
              ),
              items: MealTiming.values.map((timing) {
                return DropdownMenuItem(
                  value: timing,
                  child: Text(_getMealTimingDisplayName(timing)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMealTiming = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageSection() {
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: '500',
                      prefixIcon: Icon(Icons.medication_liquid),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter dosage';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dosageUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'mg',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter unit';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timing & Frequency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Times per day:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _timesPerDay > 1
                            ? () {
                                setState(() {
                                  _timesPerDay--;
                                  if (_notificationTimes.length >
                                      _timesPerDay) {
                                    _notificationTimes = _notificationTimes
                                        .take(_timesPerDay)
                                        .toList();
                                  }
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$_timesPerDay',
                        style: const TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        onPressed: _timesPerDay < 6
                            ? () {
                                setState(() {
                                  _timesPerDay++;
                                  if (_notificationTimes.length <
                                      _timesPerDay) {
                                    _notificationTimes.add(TimeOfDay.now());
                                  }
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Notification Times:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._buildNotificationTimesList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNotificationTimesList() {
    List<Widget> widgets = [];
    for (int i = 0; i < _timesPerDay; i++) {
      if (i >= _notificationTimes.length) {
        _notificationTimes.add(TimeOfDay.now());
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('Time ${i + 1}:', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule),
                        const SizedBox(width: 8),
                        Text(
                          _notificationTimes[i].format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildDurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                      hintText: '14',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid number of days';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _doctorController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name (Optional)',
                hintText: 'Dr. Smith',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Take with food to avoid stomach upset',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTimes[index],
    );
    if (picked != null) {
      setState(() {
        _notificationTimes[index] = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _saveMedicine() {
    if (_formKey.currentState!.validate()) {
      final medicine = Medicine(
        id: _isEditing
            ? widget.medicine!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        mealTiming: _selectedMealTiming,
        dosage: double.parse(_dosageController.text),
        dosageUnit: _dosageUnitController.text.trim(),
        timesPerDay: _timesPerDay,
        notificationTimes: _notificationTimes
            .map(
              (time) =>
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            )
            .toList(),
        durationInDays: int.parse(_durationController.text),
        startDate: _startDate,
        endDate: _startDate.add(
          Duration(days: int.parse(_durationController.text)),
        ),
        status: MedicineStatus.active,
        doctorName: _doctorController.text.trim().isEmpty
            ? null
            : _doctorController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _isEditing ? widget.medicine!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        context.read<MedicineCubit>().updateMedicine(medicine);
      } else {
        context.read<MedicineCubit>().addMedicine(medicine);
      }
    }
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

  String _getMealTimingDisplayName(MealTiming timing) {
    switch (timing) {
      case MealTiming.beforeMeal:
        return 'Before Meal';
      case MealTiming.afterMeal:
        return 'After Meal';
      case MealTiming.withMeal:
        return 'With Meal';
      case MealTiming.onEmptyStomach:
        return 'On Empty Stomach';
      case MealTiming.anytime:
        return 'Anytime';
    }
  }
}
