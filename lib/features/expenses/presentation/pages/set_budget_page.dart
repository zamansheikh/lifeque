import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/local_numbers.dart';
import '../../../../injection_container.dart' as di;
import '../../../../l10n/app_localizations.dart';
import '../../data/services/custom_category_service.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/custom_category.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_session.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/repositories/expense_repository.dart';
import '../bloc/expense_bloc.dart';
import '../utils/taka.dart';

/// Set or change a month's budget: one total, then as much or as little of
/// it split into categories as the person wants. Whatever is not assigned
/// lands in "Other" automatically, so the split never has to add up.
class SetBudgetPage extends StatefulWidget {
  final DateTime selectedMonth;
  final MonthlyBudget? existingBudget;
  final List<CategoryBudget> existingCategoryBudgets;
  final Map<String, double> categorySpending;

  const SetBudgetPage({
    super.key,
    required this.selectedMonth,
    this.existingBudget,
    this.existingCategoryBudgets = const [],
    this.categorySpending = const {},
  });

  @override
  State<SetBudgetPage> createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends State<SetBudgetPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _green = Color(0xFF059669);
  static const _red = Color(0xFFDC2626);
  static const _quickAmounts = [
    500.0,
    1000.0,
    3000.0,
    5000.0,
    7500.0,
    10000.0,
    15000.0,
    20000.0,
  ];

  final _amount = TextEditingController();
  final Map<ExpenseCategory, TextEditingController> _catAmount = {};
  final Map<ExpenseCategory, bool> _catOn = {};

  List<CustomCategory> _custom = [];
  final Map<String, TextEditingController> _customAmount = {};
  final Map<String, bool> _customOn = {};

  double get _total => double.tryParse(_amount.text) ?? 0.0;

  double _of(TextEditingController? c) => double.tryParse(c?.text ?? '') ?? 0.0;

  /// Everything assigned to a category other than "Other".
  double get _allocated {
    var sum = 0.0;
    for (final cat in ExpenseCategory.values) {
      if (cat == ExpenseCategory.other) continue;
      if (_catOn[cat] == true) sum += _of(_catAmount[cat]);
    }
    for (final cc in _custom) {
      if (_customOn[cc.name] == true) sum += _of(_customAmount[cc.name]);
    }
    return sum;
  }

  double get _otherAmount {
    final left = _total - _allocated;
    return left > 0 ? left : 0;
  }

  bool get _overAllocated => _allocated > _total;

  int get _activeCount =>
      _catOn.values.where((v) => v).length +
      _customOn.values.where((v) => v).length;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBudget;
    if (existing != null) {
      _amount.text = existing.targetAmount.toStringAsFixed(0);
    }
    _amount.addListener(_refresh);

    for (final cat in ExpenseCategory.values) {
      final ctrl = TextEditingController()..addListener(_refresh);
      final saved = widget.existingCategoryBudgets
          .where((b) => b.category == cat && b.customCategoryName == null)
          .firstOrNull;
      final on = saved != null && saved.budgetAmount > 0;
      if (on) ctrl.text = saved.budgetAmount.toStringAsFixed(0);
      _catAmount[cat] = ctrl;
      _catOn[cat] = on;
    }

    _custom = di.sl<CustomCategoryService>().getAll();
    for (final cc in _custom) {
      final ctrl = TextEditingController()..addListener(_refresh);
      final saved = widget.existingCategoryBudgets
          .where((b) => b.customCategoryName == cc.name)
          .firstOrNull;
      final on = saved != null && saved.budgetAmount > 0;
      if (on) ctrl.text = saved.budgetAmount.toStringAsFixed(0);
      _customAmount[cc.name] = ctrl;
      _customOn[cc.name] = on;
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amount.dispose();
    for (final c in _catAmount.values) {
      c.dispose();
    }
    for (final c in _customAmount.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────

  void _save() {
    final l = L.of(context);
    final amount = _total;
    if (amount <= 0) {
      _snack(l.expNeedValidAmount, error: true);
      return;
    }
    if (_overAllocated) {
      _snack(
        l.expCategoryOverBudgetDetail(taka(_allocated), taka(amount)),
        error: true,
      );
      return;
    }

    final bloc = context.read<ExpenseBloc>();
    final now = DateTime.now();
    final month = widget.selectedMonth;

    bloc.add(
      SetBudgetEvent(
        MonthlyBudget(
          id:
              widget.existingBudget?.id ??
              now.millisecondsSinceEpoch.toString(),
          year: month.year,
          month: month.month,
          targetAmount: amount,
          createdAt: widget.existingBudget?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );

    CategoryBudget? savedFor(ExpenseCategory cat, [String? custom]) => widget
        .existingCategoryBudgets
        .where(
          (b) => custom != null
              ? b.customCategoryName == custom
              : b.category == cat && b.customCategoryName == null,
        )
        .firstOrNull;

    void upsert(
      ExpenseCategory cat,
      double value, {
      String? custom,
      required String fallbackId,
    }) {
      final saved = savedFor(cat, custom);
      bloc.add(
        SetCategoryBudgetEvent(
          CategoryBudget(
            id: saved != null && saved.id.isNotEmpty ? saved.id : fallbackId,
            year: month.year,
            month: month.month,
            category: cat,
            budgetAmount: value,
            createdAt: saved?.createdAt ?? now,
            updatedAt: now,
            customCategoryName: custom,
          ),
        ),
      );
    }

    void dropIfSaved(ExpenseCategory cat, [String? custom]) {
      final saved = savedFor(cat, custom);
      if (saved != null && saved.id.isNotEmpty) {
        bloc.add(DeleteCategoryBudgetEvent(saved.id));
      }
    }

    for (final cat in ExpenseCategory.values) {
      if (cat == ExpenseCategory.other) continue;
      final value = _of(_catAmount[cat]);
      if (_catOn[cat] == true && value > 0) {
        upsert(
          cat,
          value,
          fallbackId: '${now.millisecondsSinceEpoch}${cat.name}',
        );
      } else {
        dropIfSaved(cat);
      }
    }

    // "Other" is always written: it is the remainder, and the dashboard
    // reads it back to show where the unassigned money went.
    upsert(
      ExpenseCategory.other,
      _otherAmount,
      fallbackId: '${now.millisecondsSinceEpoch}other',
    );

    for (final cc in _custom) {
      final value = _of(_customAmount[cc.name]);
      if (_customOn[cc.name] == true && value > 0) {
        upsert(
          ExpenseCategory.other,
          value,
          custom: cc.name,
          fallbackId: '${now.millisecondsSinceEpoch}custom_${cc.name}',
        );
      } else {
        dropIfSaved(ExpenseCategory.other, cc.name);
      }
    }

    _snack(l.expBudgetSaved);
    context.pop();
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final editing = widget.existingBudget != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          editing ? l.expEditBudget : l.expSetBudget,
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _amountCard(l),
          const SizedBox(height: 14),
          _categoriesCard(l),
        ],
      ),
      bottomNavigationBar: _saveBar(l),
    );
  }

  // ── Total ─────────────────────────────────────────────────────────────

  Widget _amountCard(L l) {
    final month = DateFormat('MMMM y').format(widget.selectedMonth);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.calendar_month_rounded, const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Text(
                      l.expMonthlyBudget,
                      style: const TextStyle(fontSize: 12.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
            decoration: InputDecoration(
              labelText: l.expBudgetAmount,
              hintText: l.expEnterAmount,
              prefixText: '৳ ',
              prefixStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _green,
              ),
              suffixIcon: _amount.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _amount.clear(),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _green, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.expQuickPick,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in _quickAmounts)
                _chip(
                  taka(a),
                  selected: _total == a,
                  onTap: () => _amount.text = a.toStringAsFixed(0),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.expBudgetIntro,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF1D4ED8),
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

  // ── Categories ────────────────────────────────────────────────────────

  Widget _categoriesCard(L l) {
    final total = _total;
    final allocated = _allocated;
    final fraction = total > 0 ? (allocated / total).clamp(0.0, 1.0) : 0.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.pie_chart_rounded, const Color(0xFF7C3AED)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.expCategoryBudgets,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                l.expActiveCount(_activeCount),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${l.expAllocated}: ${taka(allocated)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _overAllocated ? _red : _ink,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  l.expOtherGetsRest(taka(_otherAmount)),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _overAllocated ? _red : const Color(0xFF7C3AED),
              ),
            ),
          ),
          if (_overAllocated) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: _red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.expOverAllocated,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _red,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          for (final cat in ExpenseCategory.values)
            if (cat != ExpenseCategory.other)
              _categoryTile(
                l,
                icon: cat.icon,
                color: cat.color,
                name: cat.labelFor(context),
                on: _catOn[cat] ?? false,
                controller: _catAmount[cat]!,
                spent: widget.categorySpending[cat.name] ?? 0.0,
                onToggle: (v) => setState(() => _catOn[cat] = v),
              ),
          for (final cc in _custom)
            _categoryTile(
              l,
              icon: cc.icon,
              color: cc.color,
              name: cc.displayName,
              on: _customOn[cc.name] ?? false,
              controller: _customAmount[cc.name]!,
              spent: widget.categorySpending['custom:${cc.name}'] ?? 0.0,
              onToggle: (v) => setState(() => _customOn[cc.name] = v),
              onDelete: () => _confirmDeleteCustom(cc),
            ),
          _otherTile(l),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _addCustom,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFFC4B5FD)),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              l.expAddCustomCategory,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(
    L l, {
    required IconData icon,
    required Color color,
    required String name,
    required bool on,
    required TextEditingController controller,
    required double spent,
    required ValueChanged<bool> onToggle,
    VoidCallback? onDelete,
  }) {
    final value = _of(controller);
    final percent = _total > 0 && value > 0 ? (value / _total * 100) : 0.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: on ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: on ? color.withValues(alpha: 0.45) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: on
                      ? color.withValues(alpha: 0.16)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: on ? color : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: on ? _ink : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (spent > 0)
                      Text(
                        l.expSpentSoFar(taka(spent)),
                        style: const TextStyle(fontSize: 11.5, color: _muted),
                      ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFF94A3B8),
                  onPressed: onDelete,
                  tooltip: l.expDeleteCategory,
                ),
              Switch.adaptive(
                value: on,
                onChanged: onToggle,
                activeTrackColor: color,
              ),
            ],
          ),
          if (on) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l.expAmount,
                      prefixText: '৳ ',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: color.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: color.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: color, width: 1.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: Text(
                    percent > 0
                        ? l.expPercentOfBudget(N.of(percent.round()))
                        : '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "Other" is not a switch: it is what is left, always.
  Widget _otherTile(L l) {
    final cat = ExpenseCategory.other;
    final spent = widget.categorySpending[cat.name] ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, size: 18, color: cat.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.labelFor(context),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                Text(
                  spent > 0 ? l.expSpentSoFar(taka(spent)) : l.expUnallocated,
                  style: const TextStyle(fontSize: 11.5, color: _muted),
                ),
              ],
            ),
          ),
          Text(
            taka(_otherAmount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  // ── Save bar ──────────────────────────────────────────────────────────

  Widget _saveBar(L l) {
    final canSave = _total > 0 && !_overAllocated;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  taka(_total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                Text(
                  '${l.expAllocated}: ${taka(_allocated)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _overAllocated ? _red : _muted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              l.expSaveBudget,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom categories ─────────────────────────────────────────────────

  void _addCustom() {
    final l = L.of(context);
    final nameCtrl = TextEditingController();
    var iconIndex = 0;
    var colorIndex = 0;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final color = CustomCategory.availableColors[colorIndex];
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              l.expCreateCustomCategory,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CustomCategory.availableIcons[iconIndex],
                        color: color,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l.expCategoryName,
                      hintText: l.expCustomCategoryHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.expIcon,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (
                        var i = 0;
                        i < CustomCategory.availableIcons.length;
                        i++
                      )
                        InkWell(
                          onTap: () => setDialog(() => iconIndex = i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: i == iconIndex
                                  ? color.withValues(alpha: 0.18)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: i == iconIndex
                                    ? color
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              CustomCategory.availableIcons[i],
                              size: 20,
                              color: i == iconIndex ? color : _muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.expColor,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var i = 0;
                        i < CustomCategory.availableColors.length;
                        i++
                      )
                        InkWell(
                          onTap: () => setDialog(() => colorIndex = i),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: CustomCategory.availableColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i == colorIndex
                                    ? _ink
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: i == colorIndex
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.commonCancel),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final added = await di.sl<CustomCategoryService>().add(
                    CustomCategory(
                      name: name,
                      iconIndex: iconIndex,
                      colorValue: CustomCategory.availableColors[colorIndex]
                          .toARGB32(),
                    ),
                  );
                  if (!ctx.mounted) return;
                  if (!added) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l.expCategoryExists)),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  setState(() {
                    _custom = di.sl<CustomCategoryService>().getAll();
                    _customAmount[name] = TextEditingController()
                      ..addListener(_refresh);
                    _customOn[name] = true;
                  });
                },
                child: Text(l.expCreate),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Deleting a custom category touches every month, not just this one:
  /// items filed under it move to "Other" and its budget rows go, so nothing
  /// is left pointing at a name that no longer exists.
  Future<void> _confirmDeleteCustom(CustomCategory cc) async {
    final l = L.of(context);
    final repo = di.sl<ExpenseRepository>();
    final sessions = (await repo.getAllSessions()).getOrElse(
      () => <ExpenseSession>[],
    );
    final budgets = (await repo.getAllCategoryBudgets()).getOrElse(
      () => <CategoryBudget>[],
    );

    final touched = sessions
        .where((s) => s.items.any((i) => i.customCategoryName == cc.name))
        .toList();
    final itemCount = touched.fold<int>(
      0,
      (n, s) =>
          n + s.items.where((i) => i.customCategoryName == cc.name).length,
    );
    final affectedBudgets = budgets
        .where((b) => b.customCategoryName == cc.name)
        .toList();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          l.expDeleteCategory,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.expDeleteCustomBody(cc.displayName),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (itemCount > 0 || affectedBudgets.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (itemCount > 0)
                Text(
                  '• ${l.expDeleteCustomItems(itemCount, touched.length)}',
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              if (affectedBudgets.isNotEmpty)
                Text(
                  '• ${l.expDeleteCustomBudgets(affectedBudgets.length)}',
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _red),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final s in touched) {
      await repo.updateSession(
        s.copyWith(
          items: [
            for (final i in s.items)
              if (i.customCategoryName == cc.name)
                i.copyWith(
                  category: ExpenseCategory.other,
                  clearCustomCategory: true,
                )
              else
                i,
          ],
        ),
      );
    }
    for (final b in affectedBudgets) {
      await repo.deleteCategoryBudget(b.id);
    }
    await di.sl<CustomCategoryService>().remove(cc.name);
    if (!mounted) return;

    setState(() {
      _custom = di.sl<CustomCategoryService>().getAll();
      _customAmount.remove(cc.name)?.dispose();
      _customOn.remove(cc.name);
    });
    context.read<ExpenseBloc>().add(ChangeSelectedMonth(widget.selectedMonth));
  }

  // ── Bits ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 22),
  );

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => Material(
    color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _ink,
          ),
        ),
      ),
    ),
  );
}
