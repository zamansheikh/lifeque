import 'package:flutter/material.dart';

import '../../../../core/utils/local_numbers.dart';
import '../../../../injection_container.dart' as di;
import '../../../../l10n/app_localizations.dart';
import '../../data/services/custom_category_service.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/monthly_budget.dart';
import '../utils/taka.dart';

/// The month's budget at a glance: what is left, how fast it is going, and
/// — folded away until asked for — how each category is doing.
///
/// One question first: "can I still spend?" So the hero number is what is
/// left, the bar shows how much of the month's money has gone, and a pace
/// line turns that into a daily figure while the month is still running.
class UnifiedBudgetCard extends StatefulWidget {
  final MonthlyBudget? budget;
  final double actualSpent;
  final double monthlyTotal;
  final double monthlyMissed;
  final List<CategoryBudget> categoryBudgets;
  final Map<String, double> categorySpending;
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

class _UnifiedBudgetCardState extends State<UnifiedBudgetCard> {
  bool _expanded = false;

  static const _green = (Color(0xFF10B981), Color(0xFF059669));
  static const _amber = (Color(0xFFF59E0B), Color(0xFFD97706));
  static const _red = (Color(0xFFEF4444), Color(0xFFDC2626));

  /// Category budgets worth a row — "Other" only when it has money in it.
  List<CategoryBudget> get _visible => widget.categoryBudgets
      .where(
        (b) =>
            !(b.category == ExpenseCategory.other &&
                b.customCategoryName == null &&
                b.budgetAmount <= 0),
      )
      .toList();

  String _key(CategoryBudget b) => b.customCategoryName != null
      ? 'custom:${b.customCategoryName}'
      : b.category.name;

  ({IconData icon, Color color, String name}) _display(CategoryBudget b) {
    if (b.customCategoryName != null) {
      final cc = di.sl<CustomCategoryService>().findByName(
        b.customCategoryName!,
      );
      return (
        icon: cc?.icon ?? Icons.label_rounded,
        color: cc?.color ?? const Color(0xFF7C3AED),
        name: cc?.displayName ?? b.customCategoryName!,
      );
    }
    return (
      icon: b.category.icon,
      color: b.category.color,
      name: b.category.labelFor(context),
    );
  }

  /// Spending in categories that have no budget row, keyed as the spending
  /// map keys them. Shown so money does not vanish from the picture.
  List<(String key, double spent)> get _unbudgeted {
    final budgeted = _visible.map(_key).toSet();
    return [
      for (final e in widget.categorySpending.entries)
        if (e.value > 0 && !budgeted.contains(e.key)) (e.key, e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  ({IconData icon, Color color, String name}) _displayKey(String key) {
    if (key.startsWith('custom:')) {
      final name = key.substring(7);
      final cc = di.sl<CustomCategoryService>().findByName(name);
      return (
        icon: cc?.icon ?? Icons.label_rounded,
        color: cc?.color ?? const Color(0xFF7C3AED),
        name: cc?.displayName ?? name,
      );
    }
    final cat = ExpenseCategory.fromString(key);
    return (icon: cat.icon, color: cat.color, name: cat.labelFor(context));
  }

  String _status(L l, double fraction, bool over) {
    if (over) return l.expOverBudget;
    if (fraction >= 0.9) return l.expAlmostAtLimit;
    if (fraction >= 0.7) return l.expSpendingCautiously;
    if (fraction >= 0.5) return l.expHalfway;
    return l.expOnTrack;
  }

  /// Days still to come in the shown month, today included — or null when
  /// the month is not the current one, since pace means nothing then.
  int? get _daysLeft {
    final now = DateTime.now();
    final m = widget.selectedMonth;
    if (m.year != now.year || m.month != now.month) return null;
    final last = DateTime(m.year, m.month + 1, 0).day;
    return last - now.day + 1;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final budget = widget.budget;
    if (budget == null) return _noBudget(l);

    final total = budget.targetAmount;
    final spent = widget.actualSpent;
    final left = total - spent;
    final fraction = total > 0 ? spent / total : 0.0;
    final over = spent > total;
    final (from, to) = over
        ? _red
        : fraction >= 0.9
        ? _amber
        : _green;
    final daysLeft = _daysLeft;
    final visible = _visible;
    final unbudgeted = _unbudgeted;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [from, to],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: to.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.expMonthlyBudget,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _status(l, fraction, over),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _pill(
                      icon: Icons.edit_rounded,
                      label: l.commonEdit,
                      onTap: widget.onSetBudget,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Hero: what is left ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      taka(left.abs()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        over ? l.expOver : l.expLeft,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        l.expOfBudget(taka(total)),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      l.expUsedPercent(N.of((fraction * 100).round())),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (daysLeft != null)
                      Text(
                        l.expDaysLeft(daysLeft),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                // ── Pace ──
                if (daysLeft != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          over ? Icons.warning_rounded : Icons.speed_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            over
                                ? l.expOverBy(taka(-left))
                                : l.expPerDay(taka(left / daysLeft)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // ── Three numbers ──
                Row(
                  children: [
                    _stat(Icons.trending_up_rounded, taka(spent), l.expSpent),
                    const SizedBox(width: 8),
                    _stat(Icons.savings_rounded, taka(total), l.expBudget),
                    const SizedBox(width: 8),
                    _stat(
                      over ? Icons.warning_rounded : Icons.check_circle_rounded,
                      taka(left.abs()),
                      over ? l.expOver : l.expLeft,
                    ),
                  ],
                ),
                if (widget.monthlyTotal > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _stat(
                        Icons.receipt_long_rounded,
                        taka(widget.monthlyTotal),
                        l.expPlanned,
                      ),
                      const SizedBox(width: 8),
                      _stat(
                        Icons.remove_shopping_cart_rounded,
                        taka(widget.monthlyMissed),
                        l.expNotBought,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Categories ──
          if (visible.isNotEmpty || unbudgeted.isNotEmpty)
            Material(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _expanded
                                ? l.expHideCategoryBudgets
                                : l.expShowCategoryBudgets(visible.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _expanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: Column(
                                children: [
                                  for (final b in visible) _categoryRow(l, b),
                                  if (unbudgeted.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        4,
                                        8,
                                        4,
                                        6,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              l.expUnbudgetedSpend,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.85,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (final (key, spent) in unbudgeted)
                                      _unbudgetedRow(key, spent),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryRow(L l, CategoryBudget b) {
    final d = _display(b);
    final spent = widget.categorySpending[_key(b)] ?? 0.0;
    final fraction = b.budgetAmount > 0 ? spent / b.budgetAmount : 0.0;
    final over = spent > b.budgetAmount;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: d.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, size: 18, color: d.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '${taka(spent)} / ${taka(b.budgetAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: over
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: d.color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      over ? const Color(0xFFDC2626) : d.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              if (v == 'edit') widget.onSetBudget();
              if (v == 'delete') widget.onDeleteCategory(b.id);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                height: 40,
                child: Text(l.commonEdit, style: const TextStyle(fontSize: 13)),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 40,
                child: Text(
                  l.commonDelete,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unbudgetedRow(String key, double spent) {
    final d = _displayKey(key);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(d.icon, size: 18, color: d.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            taka(spent),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _pill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.white.withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _noBudget(L l) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.expNoBudgetThisMonth,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.expBudgetIntro,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: widget.onSetBudget,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l.expSetBudget,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
