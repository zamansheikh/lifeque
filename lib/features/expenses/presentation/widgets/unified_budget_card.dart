import 'package:flutter/material.dart';
import '../../data/services/custom_category_service.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../../../injection_container.dart' as di;

class UnifiedBudgetCard extends StatefulWidget {
  final MonthlyBudget? budget;
  final double actualSpent;
  final double monthlyTotal;
  final double monthlyMissed;
  final List<CategoryBudget> categoryBudgets;
  final Map<ExpenseCategory, double> categorySpending;
  final VoidCallback onSetBudget;
  final DateTime selectedMonth;
  final void Function(String id) onDeleteCategory;

  const UnifiedBudgetCard({
    super.key,
    this.budget,
    required this.actualSpent,
    this.monthlyTotal = 0.0,
    this.monthlyMissed = 0.0,
    required this.categoryBudgets,
    required this.categorySpending,
    required this.onSetBudget,
    required this.selectedMonth,
    required this.onDeleteCategory,
  });

  @override
  State<UnifiedBudgetCard> createState() => _UnifiedBudgetCardState();
}

class _UnifiedBudgetCardState extends State<UnifiedBudgetCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  int? _activeTip;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  /// Helper: resolve display properties for a CategoryBudget.
  /// Returns (icon, color, displayName) accounting for custom categories.
  ({IconData icon, Color color, String name}) _budgetDisplay(CategoryBudget b) {
    if (b.customCategoryName != null) {
      final cc = di.sl<CustomCategoryService>().findByName(
        b.customCategoryName!,
      );
      if (cc != null)
        return (icon: cc.icon, color: cc.color, name: cc.displayName);
      return (
        icon: Icons.label_rounded,
        color: const Color(0xFF7C3AED),
        name: b.customCategoryName!,
      );
    }
    return (
      icon: b.category.icon,
      color: b.category.color,
      name: b.category.displayName,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _activeTip = null;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _tapSegment(int index) {
    setState(() => _activeTip = _activeTip == index ? null : index);
  }

  String _getBudgetStatus(double percentage, bool isOverBudget) {
    if (isOverBudget) return 'Over budget!';
    if (percentage >= 0.9) return 'Almost at limit';
    if (percentage >= 0.7) return 'Spending cautiously';
    if (percentage >= 0.5) return 'Halfway through';
    return 'On track';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.budget == null) return _buildNoBudgetCard();

    final budgetAmount = widget.budget!.targetAmount;
    final remaining = budgetAmount - widget.actualSpent;
    final percentage = budgetAmount > 0
        ? (widget.actualSpent / budgetAmount)
        : 0.0;
    final isOverBudget = widget.actualSpent > budgetAmount;

    final Color cardColor1, cardColor2, accentColor;
    if (isOverBudget) {
      cardColor1 = const Color(0xFFEF4444);
      cardColor2 = const Color(0xFFDC2626);
      accentColor = const Color(0xFFEF4444);
    } else if (percentage > 0.8) {
      cardColor1 = const Color(0xFFF59E0B);
      cardColor2 = const Color(0xFFD97706);
      accentColor = const Color(0xFFF59E0B);
    } else {
      cardColor1 = const Color(0xFF10B981);
      cardColor2 = const Color(0xFF059669);
      accentColor = const Color(0xFF10B981);
    }

    // Categories with spending but no explicit budget
    final budgetedCats = widget.categoryBudgets.map((b) => b.category).toSet();
    final unbudgetedSpending = widget.categorySpending.entries
        .where((e) => !budgetedCats.contains(e.key) && e.value > 0)
        .toList();
    final hasCats =
        widget.categoryBudgets.isNotEmpty || unbudgetedSpending.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor1, cardColor2],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Monthly budget header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOverBudget
                            ? Icons.warning_rounded
                            : Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Budget',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _getBudgetStatus(percentage, isOverBudget),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton.icon(
                        onPressed: widget.onSetBudget,
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoTile(
                      icon: Icons.trending_up_rounded,
                      value: '৳${widget.actualSpent.toStringAsFixed(0)}',
                      label: 'Spent',
                    ),
                    const SizedBox(width: 8),
                    _infoTile(
                      icon: Icons.savings_rounded,
                      value: '৳${budgetAmount.toStringAsFixed(0)}',
                      label: 'Budget',
                    ),
                    const SizedBox(width: 8),
                    _infoTile(
                      icon: isOverBudget
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      value: '৳${remaining.abs().toStringAsFixed(0)}',
                      label: isOverBudget ? 'Over' : 'Left',
                    ),
                  ],
                ),
                // ── Shopping summary row ──
                if (widget.monthlyTotal > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoTile(
                        icon: Icons.receipt_long_rounded,
                        value: '৳${widget.monthlyTotal.toStringAsFixed(0)}',
                        label: 'Listed',
                      ),
                      const SizedBox(width: 8),
                      _infoTile(
                        icon: Icons.check_circle_rounded,
                        value: '৳${widget.actualSpent.toStringAsFixed(0)}',
                        label: 'Purchased',
                      ),
                      const SizedBox(width: 8),
                      _infoTile(
                        icon: Icons.remove_shopping_cart_rounded,
                        value: '৳${widget.monthlyMissed.toStringAsFixed(0)}',
                        label: 'Missed',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (hasCats) _buildSegmentedBar(budgetAmount),
                if (hasCats) const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Toggle ──
          if (hasCats)
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: _expanded
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Hide Category Budgets'
                          : 'Show Category Budgets (${widget.categoryBudgets.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 16),

          // ── Expanded compact rows ──
          if (hasCats)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < widget.categoryBudgets.length; i++) ...[
                      _buildCompactCategoryRow(widget.categoryBudgets[i]),
                      if (i < widget.categoryBudgets.length - 1 ||
                          unbudgetedSpending.isNotEmpty)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                          indent: 52,
                          endIndent: 16,
                        ),
                    ],
                    // Unbudgeted categories that have spending
                    for (int i = 0; i < unbudgetedSpending.length; i++) ...[
                      _buildUnbudgetedCategoryRow(
                        unbudgetedSpending[i].key,
                        unbudgetedSpending[i].value,
                      ),
                      if (i < unbudgetedSpending.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                          indent: 52,
                          endIndent: 16,
                        ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Segmented bar  (Flexible-based, no overflow)
  // ══════════════════════════════════════════════
  Widget _buildSegmentedBar(double totalBudget) {
    if (totalBudget <= 0 || widget.categoryBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    const gap = 3.0;
    const barH = 14.0;
    const radius = 4.0;

    double usedRatio = 0;
    final ratios = <double>[];
    for (final b in widget.categoryBudgets) {
      final r = (b.budgetAmount / totalBudget).clamp(0.0, 1.0);
      ratios.add(r);
      usedRatio += r;
    }
    final unallocRatio = (1.0 - usedRatio).clamp(0.0, 1.0);
    final hasUnalloc = unallocRatio > 0.01;

    // Flex values proportional to budget ratios
    final flexes = ratios
        .map((r) => (r * 1000).round().clamp(1, 1000))
        .toList();
    final unallocFlex = hasUnalloc
        ? (unallocRatio * 1000).round().clamp(1, 1000)
        : 0;

    final children = <Widget>[];

    for (int i = 0; i < widget.categoryBudgets.length; i++) {
      final b = widget.categoryBudgets[i];
      final spent = widget.categorySpending[b.category] ?? 0.0;
      final fillRatio = b.budgetAmount > 0
          ? (spent / b.budgetAmount).clamp(0.0, 1.0)
          : 0.0;
      final isOver = spent > b.budgetAmount;
      final segColor = isOver ? Colors.red[400]! : b.category.color;
      final isActive = _activeTip == i;

      children.add(
        Flexible(
          flex: flexes[i],
          child: GestureDetector(
            onTap: () => _tapSegment(i),
            child: Container(
              height: barH,
              margin: EdgeInsets.only(
                right: i < widget.categoryBudgets.length - 1 ? gap : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(radius),
                border: isActive
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FractionallySizedBox(
                    widthFactor: fillRatio,
                    alignment: Alignment.centerLeft,
                    child: Container(color: segColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (hasUnalloc) {
      final unallocIndex = widget.categoryBudgets.length;
      final isUnallocActive = _activeTip == unallocIndex;
      children.add(
        Flexible(
          flex: unallocFlex,
          child: GestureDetector(
            onTap: () => _tapSegment(unallocIndex),
            child: Container(
              height: barH,
              margin: const EdgeInsets.only(left: gap),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isUnallocActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  width: isUnallocActive ? 1.5 : 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget? tip;
    if (_activeTip != null && _activeTip! < widget.categoryBudgets.length) {
      final tb = widget.categoryBudgets[_activeTip!];
      final spent = widget.categorySpending[tb.category] ?? 0.0;
      final rem = tb.budgetAmount - spent;
      final isOver = spent > tb.budgetAmount;
      final pct = tb.budgetAmount > 0
          ? (spent / tb.budgetAmount).clamp(0.0, 1.0)
          : 0.0;
      final tbDisp = _budgetDisplay(tb);
      final segColor = isOver ? Colors.red[400]! : tbDisp.color;

      tip = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: segColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(tbDisp.icon, color: segColor, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tbDisp.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _activeTip = null),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: segColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(segColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tipStat('Spent', '৳${spent.toStringAsFixed(0)}', segColor),
                _tipStat(
                  'Budget',
                  '৳${tb.budgetAmount.toStringAsFixed(0)}',
                  const Color(0xFF64748B),
                ),
                _tipStat(
                  isOver ? 'Over' : 'Left',
                  '৳${rem.abs().toStringAsFixed(0)}',
                  isOver ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_activeTip != null &&
        _activeTip == widget.categoryBudgets.length &&
        hasUnalloc) {
      // Unallocated segment tooltip
      final allocatedTotal = widget.categoryBudgets.fold<double>(
        0,
        (s, b) => s + b.budgetAmount,
      );
      final unallocAmount = totalBudget - allocatedTotal;
      tip = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.money_off_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unallocated',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '৳${unallocAmount.toStringAsFixed(0)} not assigned to any category',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _activeTip = null),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: children),
        const SizedBox(height: 6),
        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: widget.categoryBudgets.map((b) {
            final spent = widget.categorySpending[b.category] ?? 0.0;
            final isOver = spent > b.budgetAmount;
            final bDisp = _budgetDisplay(b);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOver ? Colors.red[400] : bDisp.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  bDisp.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        ?tip,
      ],
    );
  }

  Widget _tipStat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );

  // ══════════════════════════════════════════════
  //  Compact category row (inside expanded panel)
  // ══════════════════════════════════════════════
  Widget _buildCompactCategoryRow(CategoryBudget budget) {
    final spent = widget.categorySpending[budget.category] ?? 0.0;
    final pct = budget.budgetAmount > 0
        ? (spent / budget.budgetAmount).clamp(0.0, 1.0)
        : 0.0;
    final isOver = spent > budget.budgetAmount;
    final remaining = budget.budgetAmount - spent;
    final bDisp = _budgetDisplay(budget);
    final barColor = isOver ? Colors.red[400]! : bDisp.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(bDisp.icon, color: barColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bDisp.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isOver
                          ? '−৳${(-remaining).toStringAsFixed(0)}'
                          : '৳${remaining.toStringAsFixed(0)} left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOver
                            ? Colors.red[600]
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: barColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '৳${spent.toStringAsFixed(0)} / ৳${budget.budgetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: Colors.grey[400],
              size: 18,
            ),
            padding: EdgeInsets.zero,
            onSelected: (v) {
              if (v == 'edit') widget.onSetBudget();
              if (v == 'delete') widget.onDeleteCategory(budget.id);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      size: 16,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(fontSize: 13, color: Colors.red[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  Unbudgeted category row (spending without budget)
  // ══════════════════════════════════════════════
  Widget _buildUnbudgetedCategoryRow(ExpenseCategory category, double spent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: category.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '৳${spent.toStringAsFixed(0)} spent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'No budget set',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: category.color,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: widget.onSetBudget,
            tooltip: 'Set budget',
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'No budget set for this month',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onSetBudget,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set Monthly Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
