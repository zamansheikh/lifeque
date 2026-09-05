import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// Toast styling for the prayer section.
///
/// Material's default snackbar is a dark slab with square-ish corners that
/// reads as a different app next to these cards, so every prayer-side message
/// goes through here: a floating pill on the section's deep green, with an
/// icon that carries the meaning at a glance.
/// Icon tints are picked to read on the dark ink pill, so they are the light
/// counterparts of the on-canvas palette — `accent` and `danger` are both too
/// dark to see against it.
enum PrayerSnackKind {
  /// Something was turned on or completed.
  success(Icons.check_circle_rounded, Color(0xFF5FD3A0)),

  /// Something was turned off or cleared.
  muted(Icons.notifications_off_rounded, Color(0xB3FFFFFF)),

  /// An alarm or time was scheduled.
  scheduled(Icons.alarm_on_rounded, PrayerPalette.gold),

  /// Something failed.
  error(Icons.error_outline_rounded, PrayerPalette.alertLight);

  final IconData icon;
  final Color accent;

  const PrayerSnackKind(this.icon, this.accent);
}

class PrayerSnack {
  PrayerSnack._();

  static void show(
    BuildContext context,
    String message, {
    PrayerSnackKind kind = PrayerSnackKind.success,
    Duration duration = const Duration(milliseconds: 1600),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // Replace rather than queue — tapping several bells in a row shouldn't
    // leave a backlog of toasts animating one after another.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: PrayerPalette.ink,
        elevation: 6,
        // Clears the floating bottom nav so it doesn't bury it.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(kind.icon, size: 18, color: kind.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
