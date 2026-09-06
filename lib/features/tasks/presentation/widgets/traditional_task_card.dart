import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task.dart';
import 'base_task_card.dart';

/// A task in the list.
///
/// The previous card said the same thing four times over — a coloured dot, a
/// "Time Remaining" panel with two big digit tiles, a labelled progress bar and
/// a status chip — and stood about 300px tall, so barely two fitted on screen.
/// This one keeps a single answer per question: what it is (title), how long is
/// left (one chip, colour-coded), how far along (a hairline bar) and when it
/// runs (one meta line).
class TraditionalTaskCard extends BaseTaskCard {
  const TraditionalTaskCard({
    super.key,
    required super.task,
    super.onTap,
    super.onToggleComplete,
    super.onEdit,
    super.onDelete,
  });

  @override
  State<TraditionalTaskCard> createState() => _TraditionalTaskCardState();
}

class _TraditionalTaskCardState extends BaseTaskCardState<TraditionalTaskCard> {
  Task get _task => widget.task;

  @override
  Widget build(BuildContext context) {
    final done = _task.isCompleted;
    final accent = getStatusColor();
    final description = _task.description?.trim() ?? '';
    final showProgress = !done && _task.isActive && !_task.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status reads as a stripe down the edge rather than a dot
                // plus a border plus a chip.
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: done ? Colors.grey.shade300 : accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _titleRow(done),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 32, right: 34),
                            child: Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                        if (showProgress) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 32, right: 8),
                            child: _progressBar(accent),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: _metaRow(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleRow(bool done) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _checkbox(done),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              _task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: -0.2,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? Colors.grey.shade500 : Colors.grey.shade900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _remainingChip(),
      ],
    );
  }

  /// The one control on the card that isn't "open it" — kept next to the title
  /// where a checkbox is expected, not stranded at the bottom-right.
  Widget _checkbox(bool done) {
    return GestureDetector(
      onTap: widget.onToggleComplete,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 1, right: 2, bottom: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF10B981) : Colors.transparent,
            border: Border.all(
              color: done ? const Color(0xFF10B981) : Colors.grey.shade400,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  /// "2d 4h left" / "45m left" / "Overdue by 3h" / "Starts in 2d" / "Done".
  Widget _remainingChip() {
    final (label, color) = _remaining();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  (String, Color) _remaining() {
    final l = L.of(context);
    if (_task.isCompleted) return (l.taskCardDone, const Color(0xFF059669));

    final now = DateTime.now();
    if (now.isBefore(_task.startDate)) {
      // One unit here, not two: "starts in 15h" fits beside a title where
      // "starts in 15h 49m" would push it off.
      return (
        l.taskCardStartsIn(_coarse(_task.startDate.difference(now))),
        Colors.grey.shade600,
      );
    }

    final left = _task.endDate.difference(now);
    if (left.isNegative) {
      return (l.taskCardOver(_short(-left)), Colors.red.shade600);
    }
    return (l.taskCardLeft(_short(left)), _urgencyColor(left));
  }

  Color _urgencyColor(Duration left) {
    if (left.inMinutes < 5) return Colors.red.shade600;
    if (left.inHours < 1) return Colors.orange.shade700;
    if (left.inHours < 24) return Colors.amber.shade800;
    if (left.inDays < 3) return Colors.blue.shade600;
    return Colors.green.shade600;
  }

  /// A single rounded unit, for labels that share a row with the title.
  String _coarse(Duration d) {
    final l = L.of(context);
    if (d.inDays > 0) return l.taskUnitDays(d.inDays);
    if (d.inHours > 0) return l.taskUnitHours(d.inHours);
    if (d.inMinutes > 0) return l.taskUnitMinutes(d.inMinutes);
    return l.taskUnitSeconds(d.inSeconds);
  }

  /// Two units at most — "1d 6h" reads faster than four zero-padded tiles.
  String _short(Duration d) {
    final l = L.of(context);
    if (d.inDays > 0) {
      return '${l.taskUnitDays(d.inDays)} ${l.taskUnitHours(d.inHours % 24)}';
    }
    if (d.inHours > 0) {
      return '${l.taskUnitHours(d.inHours)} '
          '${l.taskUnitMinutes(d.inMinutes % 60)}';
    }
    if (d.inMinutes > 0) {
      return '${l.taskUnitMinutes(d.inMinutes)} '
          '${l.taskUnitSeconds(d.inSeconds % 60)}';
    }
    return l.taskUnitSeconds(d.inSeconds);
  }

  Widget _progressBar(Color accent) {
    final progress = _task.progressPercentage;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            N.percent((progress * 100).round()),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow() {
    final sameYear = _task.startDate.year == _task.endDate.year;
    final range = sameYear
        ? '${DateFormat('MMM d').format(_task.startDate)} – '
              '${DateFormat('MMM d').format(_task.endDate)}'
        : '${DateFormat('MMM d, y').format(_task.startDate)} – '
              '${DateFormat('MMM d, y').format(_task.endDate)}';

    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 11,
          color: Colors.grey.shade400,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            range,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_task.isNotificationEnabled) ...[
          const SizedBox(width: 10),
          Icon(
            Icons.notifications_active_rounded,
            size: 12,
            color: Colors.blue.shade300,
          ),
        ],
        if (_task.isPinnedToNotification) ...[
          const SizedBox(width: 6),
          Icon(Icons.push_pin_rounded, size: 12, color: Colors.orange.shade300),
        ],
        const Spacer(),
        _overflow(),
      ],
    );
  }

  Widget _overflow() {
    return SizedBox(
      width: 28,
      height: 24,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'More',
        onSelected: (value) {
          if (value == 'edit') widget.onEdit?.call();
          if (value == 'delete') widget.onDelete?.call();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, size: 16),
                const SizedBox(width: 10),
                Text(L.of(context).commonEdit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  L.of(context).commonDelete,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Color getStatusColor() {
    if (_task.isCompleted) return const Color(0xFF10B981);
    if (_task.isOverdue) return Colors.red.shade500;
    if (_task.isActive) return Colors.blue.shade500;
    return Colors.orange.shade400;
  }

  @override
  String getStatusText() {
    if (_task.isCompleted) return 'Completed';
    if (_task.isOverdue) return 'Overdue';
    if (_task.isActive) return 'In Progress';
    return 'Pending';
  }

  // The base class predates this layout; everything it wants is inlined above.
  @override
  Widget buildContent() => const SizedBox.shrink();

  @override
  Widget buildProgressBar() => _progressBar(getStatusColor());

  @override
  Widget buildBottomInfo() => _metaRow();
}
