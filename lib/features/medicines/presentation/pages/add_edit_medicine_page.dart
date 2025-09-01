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

  // Common dosage units for quick selection
  static const List<String> _commonDosageUnits = [
    'mg',
    'g',
    'ml',
    'drops',
    'tablets',
    'capsules',
    'tsp',
    'tbsp',
    'IU',
    'mcg',
  ];

  // Quick preset medicines for faster input
  static const List<Map<String, dynamic>> _medicinePresets = [
    {
      'name': 'Paracetamol',
      'type': MedicineType.tablet,
      'dosage': '500',
      'unit': 'mg',
      'timing': MealTiming.anytime,
      'times': 3,
    },
    {
      'name': 'Vitamin D',
      'type': MedicineType.tablet,
      'dosage': '1000',
      'unit': 'IU',
      'timing': MealTiming.withMeal,
      'times': 1,
    },
    {
      'name': 'Cough Syrup',
      'type': MedicineType.syrup,
      'dosage': '5',
      'unit': 'ml',
      'timing': MealTiming.anytime,
      'times': 3,
    },
  ];

  MedicineType _selectedType = MedicineType.tablet;
  MealTiming _selectedMealTiming = MealTiming.anytime;
  int _timesPerDay = 1;
  DateTime _startDate = DateTime.now();
  List<TimeOfDay> _notificationTimes = [TimeOfDay.now()];
  String _selectedDosageUnit = 'mg';

  // Store loaded medicine data when editing
  Medicine? _loadedMedicine;

  bool get _isEditing => widget.medicine != null || widget.medicineId != null;

  // Get the medicine object for editing (either from widget or loaded state)
  Medicine? get _editingMedicine => widget.medicine ?? _loadedMedicine;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      _populateFields(widget.medicine!);
    } else if (widget.medicineId != null) {
      // Load medicine data from medicineId
      context.read<MedicineCubit>().loadMedicineDetail(widget.medicineId!);
    }
  }

  void _populateFields(Medicine medicine) {
    _nameController.text = medicine.name;
    _descriptionController.text = medicine.description ?? '';
    _dosageController.text = medicine.dosage.toString();
    _dosageUnitController.text = medicine.dosageUnit;
    _selectedDosageUnit = medicine.dosageUnit;
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
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
          } else if (state is MedicineDetailLoaded &&
              widget.medicineId != null) {
            // Store the loaded medicine and populate fields when medicine is loaded via medicineId
            _loadedMedicine = state.medicine;
            _populateFields(state.medicine);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              // Quick presets for common medicines
              if (!_isEditing) _buildQuickPresetsSection(),
              if (!_isEditing) const SizedBox(height: 12),

              // Main form in a single compact card
              _buildMainFormCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPresetsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _medicinePresets.map((preset) {
              return InkWell(
                onTap: () => _applyPreset(preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMedicineTypeIcon(preset['type'] as MedicineType),
                        size: 16,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        preset['name'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'];
      _selectedType = preset['type'];
      _dosageController.text = preset['dosage'];
      _selectedDosageUnit = preset['unit'];
      _dosageUnitController.text = preset['unit'];
      _selectedMealTiming = preset['timing'];
      _timesPerDay = preset['times'];

      // Update notification times based on preset
      _notificationTimes = _generateNotificationTimes(_timesPerDay);
    });
  }

  Widget _buildMainFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Medicine Name',
              hintText: 'e.g., Paracetamol',
              prefixIcon: const Icon(
                Icons.medication,
                color: Color(0xFF3B82F6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter medicine name' : null,
          ),
          const SizedBox(height: 16),

          // Medicine Type and Meal Timing in a row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MedicineType>(
                  // --- Add this line ---
                  isExpanded: true,
                  // ---------------------
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Color(0xFF3B82F6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: MedicineType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getMedicineTypeDisplayName(type),
                        overflow: TextOverflow
                            .ellipsis, // This will now work for the selected item
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<MealTiming>(
                  // --- And add this line here too ---
                  isExpanded: true,
                  // ---------------------------------
                  initialValue: _selectedMealTiming,
                  decoration: InputDecoration(
                    labelText: 'Meal Timing',
                    prefixIcon: const Icon(
                      Icons.restaurant,
                      color: Color(0xFF3B82F6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: MealTiming.values.map((timing) {
                    return DropdownMenuItem(
                      value: timing,
                      child: Text(
                        _getMealTimingDisplayName(timing),
                        overflow:
                            TextOverflow.ellipsis, // This will also work now
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedMealTiming = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dosage and Unit in a row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  // No changes needed here
                  controller: _dosageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Dosage',
                    hintText: '500',
                    prefixIcon: const Icon(
                      Icons.medical_services,
                      color: Color(0xFF3B82F6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  // --- Add this line ---
                  isExpanded: true,
                  // ---------------------
                  initialValue: _selectedDosageUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: _commonDosageUnits.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDosageUnit = value!;
                      _dosageUnitController.text = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Times per day with quick buttons
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Times per day:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(4, (index) {
                final times = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _timesPerDay = times;
                        // Generate appropriate notification times based on selection
                        _notificationTimes = _generateNotificationTimes(times);
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _timesPerDay == times
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _timesPerDay == times
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$times',

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _timesPerDay == times
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Notification times - compact grid
          if (_timesPerDay > 0) ...[
            const Text(
              'Notification Times:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_timesPerDay, (index) {
                return InkWell(
                  onTap: () => _selectTime(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _notificationTimes.length > index
                              ? _notificationTimes[index].format(context)
                              : '${8 + index * 4}:00',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Duration and Start Date in a row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (days)',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    hintText: '14',
                    prefixIcon: const Icon(
                      Icons.timer,
                      color: Color(0xFF3B82F6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (int.tryParse(value!) == null || int.parse(value) <= 0) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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

          // Optional fields - collapsible
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ExpansionTile(
                title: const Text(
                  'Additional Info (Optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'For fever and pain relief',
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Color(0xFF3B82F6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    // maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _doctorController,
                    decoration: InputDecoration(
                      labelText: 'Doctor Name',
                      hintText: 'Dr. Smith',
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFF3B82F6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Take with food',
                      prefixIcon: const Icon(
                        Icons.note,
                        color: Color(0xFF3B82F6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    // maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TimeOfDay> _generateNotificationTimes(int times) {
    switch (times) {
      case 1:
        // 8 PM
        return [const TimeOfDay(hour: 20, minute: 0)];
      case 2:
        // 8 AM, 8 PM
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      case 3:
        // 8 AM, 2 PM, 8 PM
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      case 4:
        // 7 AM, 12 PM, 5 PM, 10 PM
        return [
          const TimeOfDay(hour: 7, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 17, minute: 0),
          const TimeOfDay(hour: 22, minute: 0),
        ];
      default:
        // Fallback for any other number
        return List.generate(
          times,
          (i) => TimeOfDay(hour: 8 + i * (12 ~/ times), minute: 0),
        );
    }
  }

  Future<void> _selectTime(int index) async {
    if (index >= _notificationTimes.length) {
      _notificationTimes.add(TimeOfDay(hour: 8 + index * 4, minute: 0));
    }

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
      final editingMedicine = _editingMedicine;
      final medicine = Medicine(
        id: _isEditing
            ? editingMedicine!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        mealTiming: _selectedMealTiming,
        dosage: double.parse(_dosageController.text),
        dosageUnit: _selectedDosageUnit,
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
        createdAt: _isEditing ? editingMedicine!.createdAt : DateTime.now(),
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
        return 'Empty Stomach';
      case MealTiming.anytime:
        return 'Anytime';
    }
  }
}
