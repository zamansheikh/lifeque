import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeableTaskCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final bool canComplete;

  const SwipeableTaskCard({
    super.key,
    required this.child,
    this.onComplete,
    this.onDelete,
    this.canComplete = true,
  });

  @override
  State<SwipeableTaskCard> createState() => _SwipeableTaskCardState();
}

class _SwipeableTaskCardState extends State<SwipeableTaskCard>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  late AnimationController _moveController;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    // Drag started
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final oldDragExtent = _dragExtent;
    setState(() {
      _dragExtent += delta;
      // Limit drag extent
      _dragExtent = _dragExtent.clamp(-300.0, 300.0);
    });

    // Haptic feedback at thresholds
    if (oldDragExtent.abs() < 100 && _dragExtent.abs() >= 100) {
      HapticFeedback.mediumImpact();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    // Swipe right (complete)
    if (_dragExtent > 150 && widget.canComplete && widget.onComplete != null) {
      HapticFeedback.heavyImpact();
      widget.onComplete!();
      _resetPosition();
    }
    // Swipe left (delete)
    else if (_dragExtent < -150 && widget.onDelete != null) {
      HapticFeedback.heavyImpact();
      _showDeleteConfirmation();
    }
    // Reset position
    else {
      _resetPosition();
    }
  }

  void _resetPosition() {
    _moveController.value = 0;
    setState(() {
      _dragExtent = 0;
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetPosition();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete!();
              _resetPosition();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Background layer
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: _dragExtent > 0
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
              ),
              child: Row(
                mainAxisAlignment: _dragExtent > 0
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  if (_dragExtent > 0) ...[
                    const SizedBox(width: 20),
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: _dragExtent > 100 ? 32 : 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dragExtent > 150 ? 'Release to Complete' : 'Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _dragExtent > 100 ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (_dragExtent < 0) ...[
                    Text(
                      _dragExtent < -150 ? 'Release to Delete' : 'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _dragExtent.abs() > 100 ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.delete_rounded,
                      color: Colors.white,
                      size: _dragExtent.abs() > 100 ? 32 : 24,
                    ),
                    const SizedBox(width: 20),
                  ],
                ],
              ),
            ),
          ),
          // Card layer
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
