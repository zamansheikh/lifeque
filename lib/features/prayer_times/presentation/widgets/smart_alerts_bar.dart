import 'package:flutter/material.dart';

/// Conditional one-line strip pinned just above the bottom of the page.
/// Only shows when there's something worth telling the user about — a
/// restricted period right now, a current streak, or Ramadan mode being on.
class SmartAlertsBar extends StatelessWidget {
  final String? makruhName;
  final Duration? makruhRemaining;
  final int streakDays;
  final bool ramadanMode;

  const SmartAlertsBar({
    super.key,
    required this.makruhName,
    required this.makruhRemaining,
    required this.streakDays,
    required this.ramadanMode,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = <Widget>[];

    if (makruhName != null && makruhRemaining != null) {
      pieces.add(
        _Pill(
          icon: Icons.do_not_disturb_on_rounded,
          bg: const Color(0xFFEF4444),
          fg: Colors.white,
          text: 'Avoid · $makruhName · ${_fmt(makruhRemaining!)} left',
          pulse: true,
        ),
      );
    }

    if (streakDays > 0) {
      pieces.add(
        _Pill(
          icon: Icons.local_fire_department_rounded,
          bg: const Color(0xFFFBBF24),
          fg: const Color(0xFF1F2937),
          text: '$streakDays-day streak',
        ),
      );
    }

    if (ramadanMode) {
      pieces.add(
        _Pill(
          icon: Icons.nightlight_round,
          bg: const Color(0xFF7C3AED),
          fg: Colors.white,
          text: 'Ramadan mode',
        ),
      );
    }

    if (pieces.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            for (int i = 0; i < pieces.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              pieces[i],
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}

class _Pill extends StatefulWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String text;
  final bool pulse;

  const _Pill({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.text,
    this.pulse = false,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.bg.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.fg, size: 14),
          const SizedBox(width: 6),
          Text(
            widget.text,
            style: TextStyle(
              color: widget.fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (_ctrl == null) return base;
    return FadeTransition(
      opacity: Tween(begin: 0.75, end: 1.0).animate(_ctrl!),
      child: base,
    );
  }
}
