import 'package:flutter/material.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/expense_session.dart';
import '../../../../l10n/app_localizations.dart';

class ExpenseSessionCard extends StatefulWidget {
  final ExpenseSession session;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String itemId)? onToggleItem;

  const ExpenseSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleItem,
  });

  @override
  State<ExpenseSessionCard> createState() => _ExpenseSessionCardState();
}

class _ExpenseSessionCardState extends State<ExpenseSessionCard>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.session.items.length;
    final purchasedItems = widget.session.items
        .where((item) => item.isPurchased)
        .length;
    final completion = totalItems > 0 ? purchasedItems / totalItems : 0.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapCancel: () => _scaleController.reverse(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: completion == 1.0
                            ? const [Color(0xFF10B981), Color(0xFF059669)]
                            : const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      completion == 1.0
                          ? Icons.check_circle_rounded
                          : Icons.shopping_bag,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalItems ${totalItems == 1 ? 'item' : 'items'} · '
                          '$purchasedItems bought · '
                          '${_formatDateTime(widget.session.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amounts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${widget.session.purchasedAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'of ৳${widget.session.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          widget.onEdit?.call();
                          break;
                        case 'delete':
                          widget.onDelete?.call();
                          break;
                      }
                    },
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        height: 38,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              L.of(context).commonEdit,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        height: 38,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_rounded,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              L.of(context).commonDelete,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Progress bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 5,
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completion == 1.0
                        ? const Color(0xFF10B981)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ),

              // ── Items preview ──
              if (widget.session.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: _buildItemsPreview(maxItems: 2),
                  secondChild: _buildItemsPreview(maxItems: 6),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
                if (widget.session.items.length > 2)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isExpanded
                                  ? 'Less'
                                  : '${widget.session.items.length - 2} more',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 15,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsPreview({required int maxItems}) {
    final items = widget.session.items.take(maxItems).toList();
    return Column(
      children: items
          .map((item) => _buildItemRow(item, context))
          .toList(growable: false),
    );
  }

  Widget _buildItemRow(ExpenseItem item, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onToggleItem?.call(item.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: item.isPurchased
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: item.isPurchased
                        ? const Color(0xFF10B981)
                        : Colors.grey[350]!,
                    width: 1.5,
                  ),
                ),
                child: item.isPurchased
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: item.isPurchased
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.isPurchased
                        ? Colors.grey[500]
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '৳${item.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: item.isPurchased
                      ? const Color(0xFF10B981)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
