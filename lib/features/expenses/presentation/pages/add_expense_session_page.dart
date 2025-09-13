import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/expense_session.dart';
import '../bloc/expense_bloc.dart';

class AddExpenseSessionPage extends StatefulWidget {
  final ExpenseSession? session; // For editing existing session

  const AddExpenseSessionPage({super.key, this.session});

  @override
  State<AddExpenseSessionPage> createState() => _AddExpenseSessionPageState();
}

class _AddExpenseSessionPageState extends State<AddExpenseSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final List<ExpenseItemForm> _items = [];
  DateTime _selectedDate = DateTime.now();
  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.session!.title;
      _notesController.text = widget.session!.notes ?? '';
      _selectedDate = widget.session!.date;

      // Load existing items
      for (final item in widget.session!.items) {
        final itemForm = ExpenseItemForm();
        itemForm.nameController.text = item.name;
        itemForm.amountController.text = item.amount.toString();
        itemForm.isPurchased = item.isPurchased;
        _items.add(itemForm);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(ExpenseItemForm());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSession() {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      final items = _items
          .map(
            (itemForm) => ExpenseItem(
              id: _isEditing
                  ? (widget.session!.items.length > _items.indexOf(itemForm)
                        ? widget.session!.items[_items.indexOf(itemForm)].id
                        : DateTime.now().millisecondsSinceEpoch.toString() +
                              _items.indexOf(itemForm).toString())
                  : DateTime.now().millisecondsSinceEpoch.toString() +
                        _items.indexOf(itemForm).toString(),
              name: itemForm.nameController.text.trim(),
              amount: double.parse(itemForm.amountController.text),
              isPurchased: itemForm.isPurchased,
              purchasedAt: itemForm.isPurchased ? DateTime.now() : null,
            ),
          )
          .toList();

      final session = ExpenseSession(
        id: _isEditing
            ? widget.session!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: _selectedDate,
        items: items,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _isEditing ? widget.session!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        context.read<ExpenseBloc>().add(UpdateSessionEvent(session));
      } else {
        context.read<ExpenseBloc>().add(AddSessionEvent(session));
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Session updated successfully'
                  : 'Session added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      context.pop();
    } else if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense Session' : 'Add Expense Session',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSession,
            child: Text(
              _isEditing ? 'Update' : 'Save',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Session Title',
                        hintText: 'e.g., Market 1, Grocery Store',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a session title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Additional notes about this session',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    if (_items.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_shopping_cart,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No items added yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add Item" to get started',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      ...List.generate(_items.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildItemForm(index),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Card
            if (_items.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Items: ${_items.length}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Total Amount: \$${_calculateTotal().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSession,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(_isEditing ? Icons.update : Icons.save),
        label: Text(
          _isEditing ? 'Update Session' : 'Save Session',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildItemForm(int index) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g., Rice, Bread',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: item.isPurchased,
                onChanged: (value) {
                  setState(() {
                    item.isPurchased = value ?? false;
                  });
                },
              ),
              const Text('Already purchased'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) {
      final amount = double.tryParse(item.amountController.text) ?? 0.0;
      return sum + amount;
    });
  }
}

class ExpenseItemForm {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool isPurchased = false;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
