import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/islamic_colors.dart';
import '../utils/sky_theme.dart';

/// Light-weight tuple describing one of the three daily makruh windows.
/// Carried into [PrayerFocusCard] so the card can render an inline avoid-
/// prayer strip without re-implementing the calculator logic.
class RestrictedWindow {
  final String name; // "Sunrise Period" / "Zawal (Midday)" / "Sunset Period"
  final DateTime start;
  final DateTime end;
  final Duration? remaining; // non-null only when this is the active window

  const RestrictedWindow({
    required this.name,
    required this.start,
    required this.end,
    this.remaining,
  });
}

/// Glass card that gathers EVERYTHING about the currently-focused prayer in
/// one place — Waqt time, Mosque/jamaat time, the window, prayed state, and
/// quick-set alarm chips. This is what kills the need for separate tabs.
class PrayerFocusCard extends StatelessWidget {
  final String prayer;
  final DateTime waqtTime;
  final DateTime? mosqueTime;
  final DateTime? windowEnd;
  final bool isMosqueAutoFromRamadan;
  final bool isCurrentPrayer;
  final bool isPrayed;
  final bool canMarkPrayed;
  final QuickAlarmChoice? activeAlarm;
  final VoidCallback onEditMosque;
  final VoidCallback onTogglePrayed;
  final void Function(QuickAlarmChoice) onQuickAlarm;
  final VoidCallback onCustomAlarm;
  // Restricted (makruh) windows for today + the one that's active right now
  // (if any). Rendered as a compact in-card strip so users don't need a
  // separate widget to plan around the avoid-prayer periods.
  final List<RestrictedWindow> restrictedWindows;
  final RestrictedWindow? activeRestricted;
  final VoidCallback onRestrictedTap;

  const PrayerFocusCard({
    super.key,
    required this.prayer,
    required this.waqtTime,
    required this.mosqueTime,
    required this.windowEnd,
    required this.isMosqueAutoFromRamadan,
    required this.isCurrentPrayer,
    required this.isPrayed,
    required this.canMarkPrayed,
    required this.activeAlarm,
    required this.onEditMosque,
    required this.onTogglePrayed,
    required this.onQuickAlarm,
    required this.onCustomAlarm,
    required this.restrictedWindows,
    required this.activeRestricted,
    required this.onRestrictedTap,
  });

  @override
  Widget build(BuildContext context) {
    final sky = SkyTheme.forPrayer(prayer);
    final mosqueDelta = (mosqueTime != null)
        ? mosqueTime!.difference(waqtTime).inMinutes
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header — name + active dot + window remaining
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: sky.gradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(sky.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    prayer.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  if (isCurrentPrayer) ...[
                    const SizedBox(width: 8),
                    const _LiveDot(),
                  ],
                  const Spacer(),
                  if (windowEnd != null)
                    Text(
                      _windowLabel(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // The dual-time row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _WaqtTile(
                        startTime: waqtTime,
                        endTime: windowEnd,
                      ),
                    ),
                    Container(
                      width: 1,
                      color: IslamicColors.goldLight.withValues(alpha: 0.35),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _MosqueTile(
                        time: mosqueTime,
                        delta: mosqueDelta,
                        isAuto: isMosqueAutoFromRamadan,
                        onEdit: onEditMosque,
                      ),
                    ),
                  ],
                ),
              ),

              // Window progress bar — shows how much of the prayer window
              // remains. Gold fill from start → end.
              if (windowEnd != null) ...[
                const SizedBox(height: 14),
                _WindowProgress(
                  start: waqtTime,
                  end: windowEnd!,
                  now: DateTime.now(),
                ),
              ],

              // Inline "avoid prayer" strip — replaces the separate
              // RestrictedTimesPill widget. Lists Sunrise / Zawal / Sunset
              // compactly so users plan around them without leaving the
              // prayer card. Tap → opens the detailed sheet.
              if (restrictedWindows.isNotEmpty) ...[
                const SizedBox(height: 12),
                _RestrictedStrip(
                  windows: restrictedWindows,
                  active: activeRestricted,
                  onTap: onRestrictedTap,
                ),
              ],

              const SizedBox(height: 18),

              // Two-row action stack — the previous single-row layout was
              // squeezing the Pray pill into the leading edge of the chips
              // (visible clipping in narrow viewports). Splitting gives both
              // groups enough room to breathe.
              Row(
                children: [
                  _PrayedPill(
                    prayed: isPrayed,
                    enabled: canMarkPrayed,
                    onTap: onTogglePrayed,
                  ),
                  const Spacer(),
                  _AlarmStatusBadge(activeAlarm: activeAlarm),
                ],
              ),
              const SizedBox(height: 10),
              _ChipRow(
                activeAlarm: activeAlarm,
                onQuickAlarm: onQuickAlarm,
                onCustomAlarm: onCustomAlarm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _windowLabel() {
    if (windowEnd == null) return '';
    final now = DateTime.now();
    if (now.isBefore(waqtTime)) {
      return 'window opens ${DateFormat('h:mm a').format(waqtTime)}';
    }
    if (now.isAfter(windowEnd!)) {
      return 'window closed';
    }
    final left = windowEnd!.difference(now);
    final h = left.inHours;
    final m = left.inMinutes.remainder(60);
    return h > 0 ? '$h h $m m left' : '$m m left';
  }
}

/// Shows BOTH the start (waqt) and end of the prayer window. The end time
/// answers "by when must I have prayed?" — previously hidden behind a
/// passing label, now front-and-centre.
class _WaqtTile extends StatelessWidget {
  final DateTime startTime;
  final DateTime? endTime;
  const _WaqtTile({required this.startTime, required this.endTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              'WAQT',
              style: TextStyle(
                color: IslamicColors.goldLight,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: IslamicColors.goldLight,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              DateFormat('h:mm').format(startTime),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('a').format(startTime).toLowerCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (endTime != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_forward_rounded,
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                'ends ${DateFormat('h:mm a').format(endTime!).toLowerCase()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Thin gold progress strip showing what fraction of the prayer window is
/// still available. Past = fades to muted, ahead = bright gold.
class _WindowProgress extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final DateTime now;

  const _WindowProgress({
    required this.start,
    required this.end,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    double frac;
    String label;
    if (total <= 0) {
      frac = 0;
      label = '';
    } else if (now.isBefore(start)) {
      frac = 0;
      label = 'opens in ${_fmt(start.difference(now))}';
    } else if (now.isAfter(end)) {
      frac = 1;
      label = 'window closed';
    } else {
      frac = (elapsed / total).clamp(0.0, 1.0);
      label = '${_fmt(end.difference(now))} of window left';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 5,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        IslamicColors.goldDeep,
                        IslamicColors.goldLight,
                        IslamicColors.goldGlow,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: IslamicColors.goldGlow.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds}s';
  }
}

class _MosqueTile extends StatelessWidget {
  final DateTime? time;
  final int? delta;
  final bool isAuto;
  final VoidCallback onEdit;

  const _MosqueTile({
    required this.time,
    required this.delta,
    required this.isAuto,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isAuto ? null : onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.mosque_rounded,
                  size: 11, color: IslamicColors.mint),
              const SizedBox(width: 4),
              Text(
                'MOSQUE',
                style: TextStyle(
                  color: IslamicColors.mint,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              if (!isAuto)
                Icon(Icons.edit_outlined,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 4),
          if (time == null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: IslamicColors.mint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: IslamicColors.mint.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded,
                      size: 14, color: IslamicColors.mint),
                  SizedBox(width: 4),
                  Text(
                    'Set jamaat',
                    style: TextStyle(
                      color: IslamicColors.mint,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  DateFormat('h:mm').format(time!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('a').format(time!).toLowerCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            isAuto
                ? '✦ Auto · Waqt + 15m'
                : delta == null
                    ? 'tap to set'
                    : (delta == 0
                        ? 'same as Waqt'
                        : (delta! > 0
                            ? '+${delta!}m after Waqt'
                            : '${delta!}m before Waqt')),
            style: TextStyle(
              color: isAuto
                  ? IslamicColors.goldLight.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayedPill extends StatelessWidget {
  final bool prayed;
  final bool enabled;
  final VoidCallback onTap;
  const _PrayedPill({
    required this.prayed,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    return Material(
      color: prayed
          ? IslamicColors.emeraldLight
          : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: prayed
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          IslamicColors.emeraldLight.withValues(alpha: 0.55),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                prayed ? Icons.check_circle_rounded : Icons.mosque_outlined,
                size: 14,
                color: disabled
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                prayed ? 'Prayed' : 'Mark prayed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final QuickAlarmChoice? activeAlarm;
  final void Function(QuickAlarmChoice) onQuickAlarm;
  final VoidCallback onCustomAlarm;
  const _ChipRow({
    required this.activeAlarm,
    required this.onQuickAlarm,
    required this.onCustomAlarm,
  });

  @override
  Widget build(BuildContext context) {
    // The four chips now sit on their own row (no Pray pill to share with),
    // each cell flex-equal so the row always fills the card with no
    // horizontal scroll required even on narrow screens.
    return Row(
      children: [
        Expanded(
          child: _AlarmChip(
            label: '−5m',
            active: activeAlarm == QuickAlarmChoice.fiveBefore,
            onTap: () => onQuickAlarm(QuickAlarmChoice.fiveBefore),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _AlarmChip(
            label: 'On time',
            active: activeAlarm == QuickAlarmChoice.atTime,
            onTap: () => onQuickAlarm(QuickAlarmChoice.atTime),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _AlarmChip(
            label: '+10m',
            active: activeAlarm == QuickAlarmChoice.tenAfter,
            onTap: () => onQuickAlarm(QuickAlarmChoice.tenAfter),
          ),
        ),
        const SizedBox(width: 6),
        _AlarmChip(
          label: 'Custom',
          active: false,
          icon: Icons.tune_rounded,
          onTap: onCustomAlarm,
        ),
      ],
    );
  }
}

/// Tiny status badge that lives on the action row's trailing edge so the
/// user can see at a glance whether *any* alarm is set for this prayer.
class _AlarmStatusBadge extends StatelessWidget {
  final QuickAlarmChoice? activeAlarm;
  const _AlarmStatusBadge({required this.activeAlarm});

  @override
  Widget build(BuildContext context) {
    final on = activeAlarm != null;
    final color = on
        ? IslamicColors.goldLight
        : Colors.white.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          on ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          on ? activeAlarm!.label : 'Alarm off',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AlarmChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback onTap;
  const _AlarmChip({
    required this.label,
    required this.active,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? IslamicColors.goldLight
          : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: active
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: IslamicColors.goldGlow.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 12,
                    color: active
                        ? IslamicColors.midnight
                        : Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active
                      ? IslamicColors.midnight
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_ctrl),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE082),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFE082).withValues(alpha: 0.85),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three common alarm offsets, surfaced as one-tap chips. Mirrors the type
/// used by [PrayerAlarmConfig.afterPrayerStart].
enum QuickAlarmChoice {
  fiveBefore(-5, 'Alarm 5 min before'),
  atTime(0, 'Alarm at time'),
  tenAfter(10, 'Alarm 10 min after');

  final int minutesAfterStart;
  final String label;
  const QuickAlarmChoice(this.minutesAfterStart, this.label);
}

/// Compact in-card "avoid prayer" strip.
///
/// Shows ONE summary line at a time so it never overflows on narrow phones:
///   • **Active**  — `⛔ AVOID NOW · Zawal · 4m left` (red glow)
///   • **Passive** — `⛔ Avoid · next Sunrise 5:13 am` (subtle red border)
///   • **None left today** — `✓ All avoid-times have passed`
///
/// Tap → opens the detailed dialog with all three windows + explanation.
class _RestrictedStrip extends StatelessWidget {
  final List<RestrictedWindow> windows;
  final RestrictedWindow? active;
  final VoidCallback onTap;

  const _RestrictedStrip({
    required this.windows,
    required this.active,
    required this.onTap,
  });

  RestrictedWindow? _nextUpcoming() {
    final now = DateTime.now();
    for (final w in windows) {
      if (w.start.isAfter(now)) return w;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = active != null;
    final next = _nextUpcoming();
    final allPassed = !isActive && next == null;

    final bg = isActive
        ? IslamicColors.warning.withValues(alpha: 0.32)
        : allPassed
            ? IslamicColors.emerald.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08);
    final border = isActive
        ? IslamicColors.warningLight
        : allPassed
            ? IslamicColors.emeraldLight.withValues(alpha: 0.4)
            : IslamicColors.warning.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isActive ? 1.5 : 1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: IslamicColors.warning.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.do_not_disturb_on_rounded
                    : allPassed
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_outlined,
                size: 16,
                color: allPassed
                    ? IslamicColors.mint
                    : Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isActive
                    ? _activeSummary()
                    : allPassed
                        ? _passedSummary()
                        : _passiveSummary(next!),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passiveSummary(RestrictedWindow next) {
    return Row(
      children: [
        const Text(
          'AVOID',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'next · ${_short(next.name)} '
            '${DateFormat('h:mm a').format(next.start).toLowerCase()}',
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeSummary() {
    final a = active!;
    return Row(
      children: [
        const Text(
          'AVOID NOW',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _short(a.name),
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_fmt(a.remaining ?? Duration.zero)} left',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _passedSummary() {
    return Text(
      'All avoid-times have passed today',
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static String _short(String name) {
    if (name.contains('Sunrise')) return 'Sunrise';
    if (name.contains('Zawal')) return 'Zawal';
    if (name.contains('Sunset')) return 'Sunset';
    return name;
  }

  static String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}
