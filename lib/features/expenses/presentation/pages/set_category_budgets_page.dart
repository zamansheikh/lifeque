import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';
import '../bloc/expense_bloc.dart';

class SetCategoryBudgetsPage extends StatefulWidget {
  final DateTime selectedMonth;
  final List<CategoryBudget> existingBudgets;

  const SetCategoryBudgetsPage({
    super.key,
    required this.selectedMonth,
    this.existingBudgets = const [],
  });

  @override
  State<SetCategoryBudgetsPage> createState() => _SetCategoryBudgetsPageState();
}

class _SetCategoryBudgetsPageState extends State<SetCategoryBudgetsPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<ExpenseCategory, TextEditingController> _controllers = {};
  final Map<ExpenseCategory, bool> _enabledCategories = {};

  @override
  void initState() {
    super.initState();

    // Initialize controllers for all categories
    for (final category in ExpenseCategory.values) {
      if (category == ExpenseCategory.uncategorized) continue;

      _controllers[category] = TextEditingController();

      // Check if budget exists for this category
      final existingBudget = widget.existingBudgets.firstWhere(
        (b) => b.category == category,
        orElse: () => CategoryBudget(
          id: '',
          year: 0,
          month: 0,
          category: category,
          budgetAmount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingBudget.budgetAmount > 0) {
        _controllers[category]!.text = existingBudget.budgetAmount.toString();
        _enabledCategories[category] = true;
      } else {
        _enabledCategories[category] = false;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveBudgets() {
    if (_formKey.currentState!.validate()) {
      bool hasAtLeastOne = false;

      for (final category in _enabledCategories.keys) {
        if (_enabledCategories[category] == true) {
          final amount = double.tryParse(_controllers[category]!.text);
          if (amount != null && amount > 0) {
            hasAtLeastOne = true;

            // Find existing budget or create new
            final existingBudget = widget.existingBudgets.firstWhere(
              (b) => b.category == category,
              orElse: () => CategoryBudget(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    category.name,
                year: widget.selectedMonth.year,
                month: widget.selectedMonth.month,
                category: category,
                budgetAmount: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            final budget = CategoryBudget(
              id: existingBudget.id.isEmpty
                  ? DateTime.now().millisecondsSinceEpoch.toString() +
                        category.name
                  : existingBudget.id,
              year: widget.selectedMonth.year,
              month: widget.selectedMonth.month,
              category: category,
              budgetAmount: amount,
              createdAt: existingBudget.createdAt,
              updatedAt: DateTime.now(),
            );

            context.read<ExpenseBloc>().add(SetCategoryBudgetEvent(budget));
          }
        }
      }

      if (!hasAtLeastOne) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please set at least one category budget'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category budgets saved successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    }
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Category Budgets',
          style: TextStyle(
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
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: _saveBudgets,
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
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            // Month header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatMonthYear(widget.selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),

            // Instruction text
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDEF7EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toggle categories and set budget amounts',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category budget cards
            ...ExpenseCategory.values
                .where((c) => c != ExpenseCategory.uncategorized)
                .map((category) => _buildCategoryBudgetCard(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetCard(ExpenseCategory category) {
    final isEnabled = _enabledCategories[category] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? category.color.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category header with toggle
          InkWell(
            onTap: () {
              setState(() {
                _enabledCategories[category] = !isEnabled;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.icon, color: category.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _enabledCategories[category] = value;
                      });
                    },
                    activeTrackColor: category.color,
                  ),
                ],
              ),
            ),
          ),

          // Budget input (shown only when enabled)
          if (isEnabled)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextFormField(
                controller: _controllers[category],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_lira, color: category.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: category.color.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: category.color, width: 2),
                  ),
                  filled: true,
                  fillColor: category.color.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (isEnabled) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Invalid amount';
                    }
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }
}
