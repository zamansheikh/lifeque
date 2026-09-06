import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

abstract class BaseTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BaseTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });
}

abstract class BaseTaskCardState<T extends BaseTaskCard> extends State<T> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.task.isActive && !widget.task.isCompleted) _scheduleTick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// How often the card's countdown needs redrawing.
  ///
  /// Every card used to rebuild once a second no matter what, so a list of ten
  /// tasks due next month repainted ten times a second to move nothing. Only a
  /// deadline inside the hour actually shows seconds.
  Duration get _tickInterval {
    final left = widget.task.endDate.difference(DateTime.now());
    if (left.isNegative) return const Duration(minutes: 1);
    if (left.inMinutes < 60) return const Duration(seconds: 1);
    if (left.inHours < 24) return const Duration(seconds: 30);
    return const Duration(minutes: 1);
  }

  /// One-shot timer that re-arms itself, so the interval tightens on its own
  /// as the deadline closes in.
  void _scheduleTick() {
    _timer?.cancel();
    _timer = Timer(_tickInterval, () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  // Common UI elements
  Widget buildContainer({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: getStatusColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }

  Widget buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Status indicator dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: getStatusColor(),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: getStatusColor().withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: widget.task.isCompleted
                  ? Colors.grey.shade500
                  : colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
        ),
        buildActionButtons(),
      ],
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification indicator
        if (widget.task.isNotificationEnabled) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 14,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Pin indicator
        if (widget.task.isPinnedToNotification) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.push_pin_rounded,
              size: 14,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
        ],

        // More options button
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<String>(
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.more_vert_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Abstract methods to be implemented by specific card types
  Color getStatusColor();
  String getStatusText();
  Widget buildContent();
  Widget buildProgressBar();
  Widget buildBottomInfo();
}
