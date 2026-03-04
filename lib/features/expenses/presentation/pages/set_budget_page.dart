import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/monthly_budget.dart';
import '../bloc/expense_bloc.dart';

class SetBudgetPage extends StatefulWidget {
  final DateTime selectedMonth;
  final MonthlyBudget? existingBudget;
  final List<CategoryBudget> existingCategoryBudgets;

  const SetBudgetPage({
    super.key,
    required this.selectedMonth,
    this.existingBudget,
    this.existingCategoryBudgets = const [],
  });

  @override
  State<SetBudgetPage> createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends State<SetBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final Map<ExpenseCategory, TextEditingController> _categoryControllers = {};
  final Map<ExpenseCategory, bool> _enabledCategories = {};

  double get _totalBudget => double.tryParse(_amountController.text) ?? 0.0;

  double get _totalAllocated {
    double total = 0;
    for (final cat in ExpenseCategory.values) {
      if (cat == ExpenseCategory.uncategorized) continue;
      if (_enabledCategories[cat] == true) {
        total += double.tryParse(_categoryControllers[cat]?.text ?? '') ?? 0.0;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _amountController.text = widget.existingBudget!.targetAmount
          .toStringAsFixed(0);
    }
    _amountController.addListener(() => setState(() {}));

    for (final cat in ExpenseCategory.values) {
      if (cat == ExpenseCategory.uncategorized) continue;
      final ctrl = TextEditingController();
      final existing = widget.existingCategoryBudgets.where(
        (b) => b.category == cat,
      );
      if (existing.isNotEmpty && existing.first.budgetAmount > 0) {
        ctrl.text = existing.first.budgetAmount.toStringAsFixed(0);
        _enabledCategories[cat] = true;
      } else {
        _enabledCategories[cat] = false;
      }
      ctrl.addListener(() => setState(() {}));
      _categoryControllers[cat] = ctrl;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveBudget() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);

    // Validate: category totals must not exceed main budget
    if (_totalAllocated > amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Category budgets (৳${_totalAllocated.toStringAsFixed(0)}) exceed total budget (৳${amount.toStringAsFixed(0)})',
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Save monthly budget
    final budget = MonthlyBudget(
      id:
          widget.existingBudget?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      year: widget.selectedMonth.year,
      month: widget.selectedMonth.month,
      targetAmount: amount,
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    context.read<ExpenseBloc>().add(SetBudgetEvent(budget));

    // Save each enabled category budget
    for (final cat in ExpenseCategory.values) {
      if (cat == ExpenseCategory.uncategorized) continue;
      if (_enabledCategories[cat] == true) {
        final catAmount =
            double.tryParse(_categoryControllers[cat]?.text ?? '') ?? 0.0;
        if (catAmount > 0) {
          final existing = widget.existingCategoryBudgets.where(
            (b) => b.category == cat,
          );
          final catBudget = CategoryBudget(
            id: existing.isNotEmpty && existing.first.id.isNotEmpty
                ? existing.first.id
                : DateTime.now().millisecondsSinceEpoch.toString() + cat.name,
            year: widget.selectedMonth.year,
            month: widget.selectedMonth.month,
            category: cat,
            budgetAmount: catAmount,
            createdAt: existing.isNotEmpty
                ? existing.first.createdAt
                : DateTime.now(),
            updatedAt: DateTime.now(),
          );
          context.read<ExpenseBloc>().add(SetCategoryBudgetEvent(catBudget));
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingBudget != null
                ? 'Budget updated successfully'
                : 'Budget set successfully',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBudget != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Budget' : 'Set Budget',
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
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
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
              onPressed: _saveBudget,
              icon: const Icon(
                Icons.save_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                isEditing ? 'Update' : 'Save',
                style: const TextStyle(
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
            _buildBudgetAmountCard(),
            const SizedBox(height: 10),
            _buildQuickSelectCard(),
            const SizedBox(height: 10),
            _buildCategoryAllocationCard(),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _saveBudget,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(isEditing ? 'Update Budget' : 'Set Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Budget Amount Section ─────────────────────────────────────────────────
  Widget _buildBudgetAmountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMonthYear(widget.selectedMonth),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              labelText: 'Total Budget Amount',
              hintText: '0',
              prefixText: '৳ ',
              prefixStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon: _amountController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _amountController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a budget amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set a realistic monthly budget, then split into categories below.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Select Section ──────────────────────────────────────────────────
  Widget _buildQuickSelectCard() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              500,
              1000,
              3000,
              5000,
              7500,
              10000,
              15000,
              20000,
            ].map((a) => _buildQuickAmountButton(a.toDouble())).toList(),
          ),
        ],
      ),
    );
  }

  // ── Category Allocation Section ───────────────────────────────────────────
  Widget _buildCategoryAllocationCard() {
    final totalBudget = _totalBudget;
    final totalAllocated = _totalAllocated;
    final remaining = totalBudget - totalAllocated;
    final overAllocated = remaining < 0;
    final allocationProgress = totalBudget > 0
        ? (totalAllocated / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Category Budgets',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '${_enabledCategories.values.where((e) => e).length} active',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Allocation progress bar (only if total budget > 0)
          if (totalBudget > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allocated: ৳${totalAllocated.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overAllocated
                        ? Colors.red[600]
                        : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  overAllocated
                      ? '৳${(-remaining).toStringAsFixed(0)} over limit!'
                      : '৳${remaining.toStringAsFixed(0)} unallocated',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overAllocated
                        ? Colors.red[600]
                        : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: allocationProgress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  overAllocated ? Colors.red : const Color(0xFF8B5CF6),
                ),
              ),
            ),
            if (overAllocated)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Category budgets exceed monthly budget — please reduce.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter a monthly budget above first to set category allocations.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Category rows
          ...ExpenseCategory.values
              .where((c) => c != ExpenseCategory.uncategorized)
              .map((cat) => _buildCategoryRow(cat, remaining)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(ExpenseCategory cat, double globalRemaining) {
    final isEnabled = _enabledCategories[cat] == true;
    final currentValue =
        double.tryParse(_categoryControllers[cat]?.text ?? '') ?? 0.0;
    // available = free budget + what this cat already uses
    final availableForThis = globalRemaining + (isEnabled ? currentValue : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled
            ? cat.color.withValues(alpha: 0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? cat.color.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: isEnabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isEnabled
                  ? cat.color.withValues(alpha: 0.15)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              cat.icon,
              color: isEnabled ? cat.color : const Color(0xFF94A3B8),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),

          // Name + hint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                if (isEnabled && _totalBudget > 0)
                  Text(
                    'Max ৳${availableForThis.toStringAsFixed(0)} available',
                    style: TextStyle(
                      fontSize: 11,
                      color: cat.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Amount field (shows only when enabled)
          if (isEnabled) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 95,
              child: TextFormField(
                controller: _categoryControllers[cat],
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cat.color,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '৳',
                  prefixStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cat.color,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: cat.color.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: cat.color.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cat.color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (_enabledCategories[cat] != true) return null;
                  if (value == null || value.isEmpty) return 'Enter amount';
                  final amt = double.tryParse(value);
                  if (amt == null || amt <= 0) return 'Invalid';
                  if (_totalBudget > 0 && amt > availableForThis + 0.01) {
                    return 'Too high';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Toggle switch
          Switch(
            value: isEnabled,
            activeThumbColor: cat.color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() {
                _enabledCategories[cat] = val;
                if (!val) _categoryControllers[cat]?.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    final isSelected = _amountController.text == amount.toInt().toString();
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: () {
          _amountController.text = amount.toInt().toString();
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Colors.transparent
              : const Color(0xFFF8FAFC),
          foregroundColor: isSelected ? Colors.white : const Color(0xFF64748B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Text(
          '৳${amount.toInt()}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
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
}
