/// Shared building blocks for the app's detail screens.
///
/// Task, reminder, birthday, to-do and medicine details each grew their own
/// header gradient, their own card padding and their own row helper, so five
/// pages showing the same shape of information looked like five apps. These
/// are the pieces they now share: one hero, one section card, one row, one
/// stat tile, one countdown.
library;

import 'package:flutter/material.dart';

/// The accent-tinted header at the top of a detail page.
///
/// Answers the three questions worth answering above the fold: what it is,
/// what state it is in, and when it happens.
class DetailHero extends StatelessWidget {
  final IconData icon;
  final Color accent;

  /// Short state word — "Overdue", "Completed", "In 3 days".
  final String status;

  final String title;

  /// The one line of timing that matters most, if there is one.
  final String? subtitle;

  final String? description;

  /// Struck through when the thing is done.
  final bool isDone;

  /// Usually a [DetailCheckCircle].
  final Widget? action;

  const DetailHero({
    super.key,
    required this.icon,
    required this.accent,
    required this.status,
    required this.title,
    this.subtitle,
    this.description,
    this.isDone = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final notes = description?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.4,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? Colors.grey.shade500
                            : Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 12), action!],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The circular done/not-done toggle that sits in a [DetailHero].
class DetailCheckCircle extends StatelessWidget {
  final bool checked;
  final Color accent;
  final VoidCallback onTap;

  const DetailCheckCircle({
    super.key,
    required this.checked,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: checked ? 'Mark as not done' : 'Mark as done',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? const Color(0xFF10B981) : Colors.white,
            border: Border.all(
              color: checked ? const Color(0xFF10B981) : accent,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 20,
            color: checked ? Colors.white : accent.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// A white card with a small heading. Everything below the hero is one.
class DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget? trailing;
  final List<Widget> children;

  const DetailSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Label on the left, value on the right. The workhorse of every section.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A number worth reading at a glance. Meant for a `Row` of `Expanded`s.
class DetailStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const DetailStat({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dated step in a two-or-three point timeline.
class DetailTimelineTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  /// Draws the connector down to the next tile.
  final bool hasNext;

  const DetailTimelineTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.hasNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (hasNext)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: hasNext ? 18 : 0, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time remaining, in at most three units.
///
/// Replaces the two pages that each built their own row of large digit tiles.
class DetailCountdown extends StatelessWidget {
  final Duration remaining;
  final Color color;

  /// What the number means — "Until it goes off", "Until the birthday".
  final String caption;

  /// Shown instead of the digits once the moment has passed.
  final String passedLabel;

  const DetailCountdown({
    super.key,
    required this.remaining,
    required this.color,
    required this.caption,
    this.passedLabel = 'This has passed',
  });

  @override
  Widget build(BuildContext context) {
    if (remaining.isNegative) {
      return Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            passedLabel,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      );
    }

    // Three units at most, and never a leading zero unit — "4h 09m 12s" beats
    // "00d 04h 09m 12s".
    final units = <(String, String)>[
      if (remaining.inDays > 0) ('${remaining.inDays}', 'days'),
      if (remaining.inHours > 0) ('${remaining.inHours % 24}', 'hrs'),
      ('${remaining.inMinutes % 60}', 'min'),
      if (remaining.inHours < 1) ('${remaining.inSeconds % 60}', 'sec'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < units.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _unit(units[i].$1, units[i].$2)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _unit(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value.padLeft(2, '0'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// A slim labelled progress bar.
class DetailProgress extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const DetailProgress({
    super.key,
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
