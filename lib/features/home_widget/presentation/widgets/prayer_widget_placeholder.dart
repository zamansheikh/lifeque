import 'package:flutter/material.dart';

/// Shown in place of a widget while no location has been saved.
///
/// It takes a [size] and fills it, exactly like the real widget UIs do. It
/// used to hard-code 380×180 and be rendered at the nominal size rather than
/// the cell the launcher actually handed over, so on any other cell shape the
/// PNG was letterboxed inside the ImageView and the launcher's own surface
/// showed around it — a widget sitting inside a widget.
class PrayerWidgetPlaceholder extends StatelessWidget {
  final Size size;

  const PrayerWidgetPlaceholder({super.key, this.size = const Size(380, 180)});

  /// Below this the tall layout has no room, so it lays out along one line
  /// instead — the slim bar's cell is only about 64 logical pixels high.
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
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D4F4F), Color(0xFF0A6B5C), Color(0xFF0E7E6B)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.center,
          // Scales rather than overflows: a cell can be shorter than the
          // content wants, and a RenderFlex overflow would be baked into the
          // PNG for everyone to see.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: compact ? _compactBody() : _fullBody(),
          ),
        ),
      ),
    );
  }

  Widget _compactBody() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mosque,
          size: 20,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 10),
        const Text(
          'Set your location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Tap to open',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _fullBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mosque,
          size: 36,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 10),
        const Text(
          'Prayer Times',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap to open the app and set your location',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
              SizedBox(width: 4),
              Text(
                'Set location',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
