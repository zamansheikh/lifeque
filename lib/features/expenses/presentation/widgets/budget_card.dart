import 'package:flutter/material.dart';
import '../../domain/entities/monthly_budget.dart';

class BudgetCard extends StatelessWidget {
  final MonthlyBudget? budget;
  final double actualSpent;
  final VoidCallback onSetBudget;
  final DateTime selectedMonth;

  const BudgetCard({
    super.key,
    this.budget,
    required this.actualSpent,
    required this.onSetBudget,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBudget = budget != null;

    if (!hasBudget) {
      return _buildNoBudgetCard(context, theme);
    }

    final budgetAmount = budget!.targetAmount;
    final remaining = budgetAmount - actualSpent;
    final percentage = budgetAmount > 0 ? (actualSpent / budgetAmount) : 0.0;
    final isOverBudget = actualSpent > budgetAmount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOverBudget
                ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                : [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: isOverBudget ? Colors.red : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOverBudget ? Colors.red[700] : Colors.green[700],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSetBudget,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(fontSize: 12, color: theme.primaryColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentage > 1.0 ? 1.0 : percentage).clamp(
                  0.0,
                  1.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? Colors.red
                        : (percentage > 0.8 ? Colors.orange : Colors.green),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Amount details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${actualSpent.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget ? Colors.red : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${budgetAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverBudget ? 'Over' : 'Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isOverBudget
                            ? '\$${(-remaining).toStringAsFixed(2)}'
                            : '\$${remaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status message
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOverBudget
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverBudget ? Icons.warning : Icons.info,
                    size: 16,
                    color: isOverBudget ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOverBudget
                          ? 'You\'ve exceeded your budget by \$${(-remaining).toStringAsFixed(2)}'
                          : remaining > 0
                          ? 'You have \$${remaining.toStringAsFixed(2)} left to spend'
                          : 'Budget exactly met! Great job!',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverBudget
                            ? Colors.red[700]
                            : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBudgetCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.withOpacity(0.1),
              Colors.grey.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No Budget Set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a monthly budget to track your spending',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onSetBudget,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Set Budget',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
