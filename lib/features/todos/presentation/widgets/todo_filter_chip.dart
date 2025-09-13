import 'package:flutter/material.dart';
import '../../domain/entities/todo.dart';

class TodoFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const TodoFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
    this.color,
  });

  factory TodoFilterChip.category({
    required TodoCategory category,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return TodoFilterChip(
      label: category.displayName,
      isSelected: isSelected,
      onTap: onTap,
      icon: category.icon,
      color: category.color,
    );
  }

  factory TodoFilterChip.priority({
    required TodoPriority priority,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return TodoFilterChip(
      label: priority.displayName,
      isSelected: isSelected,
      onTap: onTap,
      icon: priority.icon,
      color: priority.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? Theme.of(context).primaryColor).withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (color ?? Theme.of(context).primaryColor)
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? (color ?? Theme.of(context).primaryColor)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? (color ?? Theme.of(context).primaryColor)
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}