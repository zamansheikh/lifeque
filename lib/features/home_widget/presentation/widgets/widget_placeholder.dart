import 'package:flutter/material.dart';

import '../../../../core/utils/app_strings.dart';

/// Stands in for a widget while no location has been saved.
///
/// Carries the gradient and corner radius of the widget it replaces, rather
/// than a look of its own. An earlier version painted one teal card for all
/// four, so wherever it did not fill the cell exactly you saw a teal card
/// sitting inside a green one.
///
/// It exists at all — rather than leaning on the placeholder in each Android
/// layout — because RemoteViews are inflated by the launcher and will not load
/// a Typeface out of our APK. `android:fontFamily="@font/…"` is quietly ignored
/// there, so the native fallback can only ever render Bangla in a system face.
/// Drawn here, it gets the same Noto Serif Bengali as everything else.
class WidgetPlaceholder extends StatelessWidget {
  const WidgetPlaceholder({
    super.key,
    required this.size,
    required this.gradient,
    this.radius = 20,
  });

  final Size size;
  final List<Color> gradient;
  final double radius;

  /// Below this there is no room to stack, so it lays out along one line — the
  /// slim bar's cell is only about 64 logical pixels high.
  static const double _compactBelow = 110;

  @override
  Widget build(BuildContext context) {
    final compact = size.height < _compactBelow;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
              stops: gradient.length == 3 ? const [0.0, 0.5, 1.0] : null,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.center,
          // Scales rather than overflows: a cell can be shorter than the
          // content wants, and a RenderFlex overflow would be baked into the
          // PNG for everyone to see.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: compact ? _compact() : _full(),
          ),
        ),
      ),
    );
  }

  Widget _compact() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.mosque, size: 20, color: Colors.white.withValues(alpha: 0.6)),
      const SizedBox(width: 10),
      Text(
        appStrings.widgetSetLocation,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _full() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.mosque, size: 30, color: Colors.white.withValues(alpha: 0.55)),
      const SizedBox(height: 8),
      Text(
        appStrings.widgetPrayerTimes,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        appStrings.widgetTapToSetLocation,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              appStrings.widgetSetLocationShort,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
