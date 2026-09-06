import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/expense_session.dart';
import '../../domain/entities/expense_item.dart';
import '../bloc/expense_bloc.dart';

class ExpenseSessionDetailPage extends StatelessWidget {
  final ExpenseSession session;

  const ExpenseSessionDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // The list handed over by the route is a snapshot taken when the row was
    // tapped. Ticking an item off goes through the bloc, so read the live copy
    // back out of it — otherwise the tap saved fine but nothing on this screen
    // moved, which read as "the checkbox is broken".
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final live = state is ExpenseLoaded
            ? (state.sessions.where((s) => s.id == session.id).firstOrNull ??
                  state.searchResults
                      .where((s) => s.id == session.id)
                      .firstOrNull ??
                  session)
            : session;
        return _buildPage(context, live);
      },
    );
  }

  Widget _buildPage(BuildContext context, ExpenseSession session) {
    final theme = Theme.of(context);
    final totalCount = session.items.length;
    final purchasedCount = session.purchasedCount;
    final progress = totalCount > 0 ? purchasedCount / totalCount : 0.0;
    final done = totalCount > 0 && purchasedCount == totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          session.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
              onPressed: () => context.push('/expenses/edit', extra: session),
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Edit',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overview ──
          // The app bar already carries the list name, so this card leads with
          // what it can't show: the date, how far through the list you are, and
          // one money row instead of the old count row plus amount row that
          // said "purchased" and "missed" twice over.
          Card(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            surfaceTintColor: Colors.transparent,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(session.date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$purchasedCount of $totalCount bought',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: done ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? const Color(0xFF10B981) : theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat(
                        'Spent',
                        session.purchasedAmount,
                        purchasedCount,
                        const Color(0xFF059669),
                        Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 10),
                      _stat(
                        'Not bought',
                        session.missedAmount,
                        session.missedCount,
                        const Color(0xFFD97706),
                        Icons.remove_circle_outline_rounded,
                      ),
                      const SizedBox(width: 10),
                      _stat(
                        'List total',
                        session.totalAmount,
                        totalCount,
                        const Color(0xFF2563EB),
                        Icons.receipt_long_rounded,
                      ),
                    ],
                  ),
                  if (session.notes != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_rounded,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              session.notes!,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Items List
          Card(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            surfaceTintColor: Colors.transparent,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                      Text(
                        totalCount == purchasedCount
                            ? 'All bought'
                            : '${totalCount - purchasedCount} left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: done ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...session.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildItemCard(item, session.id, context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// One overview tile: the money first, then what it covers, so the amount
  /// and the item count no longer need two separate rows.
  Widget _stat(
    String label,
    double amount,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '৳${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    ExpenseItem item,
    String sessionId,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Toggle item purchased status
        context.read<ExpenseBloc>().add(
          ToggleItemPurchasedEvent(sessionId, item.id),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isPurchased
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isPurchased
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isPurchased ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.isPurchased ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: item.isPurchased
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: item.isPurchased
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isPurchased
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                  if (item.isPurchased && item.purchasedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bought ${_formatDateTime(item.purchasedAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.green[600]),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: item.isPurchased ? Colors.green : Colors.grey[700],
                  ),
                ),
                if (!item.isPurchased)
                  Text(
                    'Tap when bought',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // d/m/y reads as m/d/y to half the world, so spell the month out.
  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${_formatDate(dateTime)}, ${dateTime.hour}:$minute';
  }
}
