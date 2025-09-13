import 'package:flutter/material.dart';

class MonthlySummaryCard extends StatelessWidget {
  final double monthlyTotal;
  final double monthlyPurchased;
  final double monthlyMissed;
  final DateTime selectedMonth;

  const MonthlySummaryCard({
    super.key,
    required this.monthlyTotal,
    required this.monthlyPurchased,
    required this.monthlyMissed,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final total = monthlyTotal;
    final purchased = monthlyPurchased;
    final missed = monthlyMissed;
    final saved = missed; // missed is money saved
    final progress = total > 0 ? (purchased / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMonthYear(selectedMonth),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Purchased ${total > 0 ? ((purchased / total) * 100).toStringAsFixed(0) : '0'}% of total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${purchased.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'of \$${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 8),

          // Stats row with better spacing
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  Icons.check_circle,
                  'Purchased',
                  purchased,
                  Colors.white,
                  isMoney: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStat(
                  Icons.cancel,
                  'Missed',
                  missed,
                  Colors.white70,
                  isMoney: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStat(
                  Icons.savings,
                  'Saved',
                  saved,
                  Colors.white70,
                  isMoney: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String label,
    double value,
    Color color, {
    bool isMoney = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            isMoney ? '\$${value.toStringAsFixed(0)}' : value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
