import 'package:flutter/material.dart';

import '../../../prayer_times/presentation/utils/prayer_palette.dart';
import '../../services/widget_suggestion_service.dart';

/// Offers the home-screen widgets, either as a one-time suggestion after
/// prayer setup or on demand from the More tab.
class AddWidgetSheet {
  static Future<void> show(
    BuildContext context, {
    /// True when this is the automatic post-setup prompt rather than the
    /// user deliberately opening it — only that version records a dismissal.
    bool isSuggestion = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _Sheet(isSuggestion: isSuggestion),
    );
  }
}

class _Sheet extends StatefulWidget {
  final bool isSuggestion;

  const _Sheet({required this.isSuggestion});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _service = WidgetSuggestionService.instance;
  PinnableWidget? _busy;

  Future<void> _pin(PinnableWidget widget) async {
    setState(() => _busy = widget);
    try {
      await _service.pin(widget);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add the widget: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PrayerPalette.inkA(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PrayerPalette.accentA(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.widgets_rounded,
                color: PrayerPalette.accent,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isSuggestion
                  ? 'Keep prayer times on your home screen'
                  : 'Add a home-screen widget',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'See the next waqt without opening the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PrayerPalette.inkA(0.6),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in PinnableWidget.values) ...[
              _option(option),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () async {
                if (widget.isSuggestion) await _service.dismiss();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(
                widget.isSuggestion ? 'Not now' : 'Close',
                style: TextStyle(
                  color: PrayerPalette.inkA(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(PinnableWidget option) {
    final isBusy = _busy == option;
    return InkWell(
      onTap: _busy == null ? () => _pin(option) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: PrayerPalette.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PrayerPalette.inkA(0.08)),
        ),
        child: Row(
          children: [
            _preview(option),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: PrayerPalette.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    option.description,
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.55),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PrayerPalette.accent,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PrayerPalette.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A tiny stand-in for each widget's shape, so the options are
  /// distinguishable at a glance without shipping screenshots.
  Widget _preview(PinnableWidget option) {
    final (colors, isSlim) = switch (option) {
      PinnableWidget.currentWaqt => (
          [const Color(0xFF1E7A50), const Color(0xFF0E4A30)],
          false,
        ),
      PinnableWidget.mosqueJamaat => (
          [const Color(0xFF16324A), const Color(0xFF0C1E2E)],
          false,
        ),
      PinnableWidget.dayMap => (
          [const Color(0xFF123B2C), const Color(0xFF062316)],
          false,
        ),
      PinnableWidget.slimBar => (
          [const Color(0xFF1E7A50), const Color(0xFF0E4A30)],
          true,
        ),
    };

    return Container(
      width: 46,
      height: isSlim ? 20 : 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Icon(
          switch (option) {
            PinnableWidget.currentWaqt => Icons.mosque,
            PinnableWidget.mosqueJamaat => Icons.schedule_rounded,
            PinnableWidget.dayMap => Icons.timeline_rounded,
            PinnableWidget.slimBar => Icons.remove_rounded,
          },
          size: 13,
          color: PrayerPalette.gold,
        ),
      ),
    );
  }
}
