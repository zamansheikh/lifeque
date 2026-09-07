import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/local_numbers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../prayer_times/presentation/widgets/share_art.dart';
import 'wish_art.dart';

/// The looks a wish card can take. Each is a backdrop plus a palette; the
/// layout is shared so any message fits any style.
/// Floral first: it is the one people reach for, so it is the one that opens.
enum WishCardStyle { floral, night, confetti, balloons, elegant }

extension WishCardStyleLabel on WishCardStyle {
  String label(L l) => switch (this) {
    WishCardStyle.night => l.wishStyleNight,
    WishCardStyle.confetti => l.wishStyleConfetti,
    WishCardStyle.balloons => l.wishStyleBalloons,
    WishCardStyle.floral => l.wishStyleFloral,
    WishCardStyle.elegant => l.wishStyleElegant,
  };
}

/// "25th" / "২৫তম" — the ordinal used in "25th birthday".
String ordinalAge(int age) {
  if (isBanglaUi) return '${N.of(age)}তম';
  final mod100 = age % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${age}th';
  return switch (age % 10) {
    1 => '${age}st',
    2 => '${age}nd',
    3 => '${age}rd',
    _ => '${age}th',
  };
}

/// A 1080×1080 birthday card: greeting, the person's name, their age if
/// wanted, the message, and who it is from.
///
/// Square because that is the one shape every chat app and feed shows whole.
class BirthdayWishCard extends StatelessWidget {
  final WishCardStyle style;
  final String name;
  final int? age;
  final String message;
  final String from;

  const BirthdayWishCard({
    super.key,
    required this.style,
    required this.name,
    required this.message,
    this.age,
    this.from = '',
  });

  static const _night = Color(0xFF05130E);
  static const _deep = Color(0xFF0E3A29);
  static const _gold = Color(0xFFF5D27A);
  static const _goldInk = Color(0xFFB8901E);
  static const _ink = Color(0xFF1E293B);

  _Palette get _palette => switch (style) {
    WishCardStyle.night => const _Palette(
      title: _gold,
      name: Colors.white,
      text: Color(0xE6FFFFFF),
      accent: _gold,
      chipFill: Color(0x2EF5D27A),
      watermark: Color(0x99FFFFFF),
    ),
    WishCardStyle.confetti => const _Palette(
      title: Color(0xFFDB2777),
      name: _ink,
      text: Color(0xFF334155),
      accent: Color(0xFFDB2777),
      chipFill: Color(0x1ADB2777),
      watermark: Color(0x99334155),
    ),
    WishCardStyle.balloons => const _Palette(
      title: Color(0xFF2563EB),
      name: _ink,
      text: Color(0xFF334155),
      accent: Color(0xFF2563EB),
      chipFill: Color(0x1A2563EB),
      watermark: Color(0x99334155),
    ),
    WishCardStyle.floral => const _Palette(
      title: Color(0xFFBE185D),
      name: Color(0xFF4A1D2E),
      text: Color(0xFF6B2A44),
      accent: Color(0xFFBE185D),
      chipFill: Color(0x1ABE185D),
      watermark: Color(0x996B2A44),
    ),
    WishCardStyle.elegant => const _Palette(
      title: _goldInk,
      name: _ink,
      text: Color(0xFF475569),
      accent: _goldInk,
      chipFill: Color(0x1AB8901E),
      watermark: Color(0x99475569),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = _palette;
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SizedBox(
        width: 1080,
        height: 1080,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _backdrop(),
            Padding(
              padding: const EdgeInsets.fromLTRB(96, 96, 96, 72),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.chipFill,
                      border: Border.all(color: p.accent, width: 2.5),
                    ),
                    child: Icon(Icons.cake_rounded, size: 50, color: p.accent),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l.wishCardTitle,
                    style: TextStyle(
                      color: p.title,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      maxLines: 1,
                      style: TextStyle(
                        color: p.name,
                        fontSize: 92,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.chipFill,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: p.accent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        l.wishNthBirthday(ordinalAge(age!)),
                        style: TextStyle(
                          color: p.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  _rule(p),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.text,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                  if (from.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      l.wishFromLine(from.trim()),
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          cacheWidth: 90,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LifeQue',
                        style: TextStyle(
                          color: p.watermark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backdrop() => switch (style) {
    WishCardStyle.night => const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_night, _deep, Color(0xFF0A2519)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
        CustomPaint(painter: StarfieldPainter(fadeBy: 0.9)),
        Positioned(
          top: 70,
          right: 80,
          child: SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(painter: CrescentPainter(color: _gold)),
          ),
        ),
      ],
    ),
    WishCardStyle.confetti => const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Color(0xFFFFFBF0)),
        CustomPaint(painter: ConfettiPainter()),
      ],
    ),
    WishCardStyle.balloons => const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDCEEFF), Color(0xFFFFFFFF)],
            ),
          ),
        ),
        CustomPaint(painter: BalloonsPainter()),
      ],
    ),
    WishCardStyle.floral => const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE4EC), Color(0xFFFFF8FA), Color(0xFFFFE9F0)],
            ),
          ),
        ),
        CustomPaint(painter: FloralPainter()),
      ],
    ),
    WishCardStyle.elegant => const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.white),
        CustomPaint(painter: GoldFramePainter(color: _goldInk)),
      ],
    ),
  };

  Widget _rule(_Palette p) => Row(
    children: [
      Expanded(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                p.accent.withValues(alpha: 0),
                p.accent.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('✦', style: TextStyle(color: p.accent, fontSize: 24)),
      ),
      Expanded(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                p.accent.withValues(alpha: 0.6),
                p.accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Palette {
  final Color title;
  final Color name;
  final Color text;
  final Color accent;
  final Color chipFill;
  final Color watermark;

  const _Palette({
    required this.title,
    required this.name,
    required this.text,
    required this.accent,
    required this.chipFill,
    required this.watermark,
  });
}
