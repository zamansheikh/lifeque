import 'package:flutter/material.dart';

import '../../../prayer_times/presentation/utils/prayer_palette.dart';
import '../../services/home_widget_service.dart';
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

  /// The real widgets, built from the real prayer times, so what you see here
  /// is what lands on the home screen.
  late final Future<WidgetPreviews?> _previews = HomeWidgetService()
      .buildPreviews();

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
    // Four full previews are taller than a phone, so the sheet scrolls and
    // stops short of the top rather than fighting the status bar.
    final maxHeight = MediaQuery.of(context).size.height * 0.86;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
              'This is exactly how each one will look.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PrayerPalette.inkA(0.6),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: FutureBuilder<WidgetPreviews?>(
                future: _previews,
                builder: (context, snapshot) {
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    children: [
                      if (!loading && snapshot.data == null) _noLocationNote(),
                      for (final option in PinnableWidget.values) ...[
                        _option(option, snapshot.data, loading),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ),
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
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _noLocationNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PrayerPalette.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            size: 16,
            color: PrayerPalette.ink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set your location first and these will fill in with your own '
              'prayer times.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: PrayerPalette.inkA(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(
    PinnableWidget option,
    WidgetPreviews? previews,
    bool loading,
  ) {
    final isBusy = _busy == option;

    return Container(
      decoration: BoxDecoration(
        color: PrayerPalette.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PrayerPalette.inkA(0.08)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _preview(option, previews, loading),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          color: PrayerPalette.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        style: TextStyle(
                          color: PrayerPalette.inkA(0.55),
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    onPressed: _busy == null ? () => _pin(option) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: PrayerPalette.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The live widget, scaled down to the sheet's width.
  ///
  /// [BoxFit.fill] inside an [AspectRatio] of the same ratio is an exact
  /// scale — the preview is the widget, just smaller, with nothing cropped or
  /// stretched.
  Widget _preview(
    PinnableWidget option,
    WidgetPreviews? previews,
    bool loading,
  ) {
    final (Widget? child, Size size) = switch (option) {
      PinnableWidget.currentWaqt => (
        previews?.currentWaqt,
        previews?.currentWaqtSize ?? const Size(380, 180),
      ),
      PinnableWidget.mosqueJamaat => (
        previews?.mosqueJamaat,
        previews?.mosqueJamaatSize ?? const Size(380, 180),
      ),
      PinnableWidget.dayMap => (
        previews?.dayMap,
        previews?.dayMapSize ?? const Size(380, 132),
      ),
      PinnableWidget.slimBar => (
        previews?.slimBar,
        previews?.slimBarSize ?? const Size(380, 64),
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: size.width / size.height,
        child: child == null
            ? _placeholder(loading)
            : FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: child,
                ),
              ),
      ),
    );
  }

  Widget _placeholder(bool loading) {
    return Container(
      color: PrayerPalette.inkA(0.06),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PrayerPalette.accent,
              ),
            )
          : Icon(
              Icons.image_not_supported_outlined,
              size: 22,
              color: PrayerPalette.inkA(0.3),
            ),
    );
  }
}
