import 'package:flutter/material.dart';

/// Palette for the redesigned prayer screen.
///
/// A daylight-first scheme: deep forest ink on a pale mint canvas, with a warm
/// dawn gradient behind the countdown gauge. Values come straight from the
/// design canvas so cards, chips and text match it exactly.
class PrayerPalette {
  PrayerPalette._();

  /// Primary text + the filled arc / NOW badge.
  static const ink = Color(0xFF123B2C);

  /// Interactive green — links, bells, jamaat chips, checkmarks.
  static const accent = Color(0xFF0F8A5F);

  /// Page background behind the cards.
  static const canvas = Color(0xFFF4FAF5);

  // Dawn gradient behind the gauge (top → bottom).
  static const skyTop = Color(0xFFFBF3CF);
  static const skyMid = Color(0xFFE9F4DC);
  static const skyBottom = Color(0xFFD5EDDD);

  // Ramadan strip.
  static const ramadanFrom = Color(0xFF123B2C);
  static const ramadanTo = Color(0xFF0F5132);
  static const gold = Color(0xFFF5D27A);

  // Prohibited-times card.
  static const danger = Color(0xFFB4453A);
  static const dangerChipBg = Color(0xFFF8EDEB);
  static const dangerChipActive = Color(0xFF7A443C);
  static const dangerChipText = Color(0xFF7A3A30);
  static const dangerChipLabel = Color(0xFF8A5418);

  /// [ink] at a given opacity — the design expresses most secondary text as
  /// `rgba(18,59,44,.xx)` rather than as separate colours.
  static Color inkA(double alpha) => ink.withValues(alpha: alpha);

  /// [accent] at a given opacity.
  static Color accentA(double alpha) => accent.withValues(alpha: alpha);

  // Friday (Jumu'ah) rows in the calendar.
  static const fridayBg = Color(0xFFFBF6E3);
  static const fridayText = Color(0xFF8A6A14);
  static const goldDeep = Color(0xFFC79A2A);
  static const goldRule = Color(0xFFD4AF37);

  // 30-day completion heatmap, lightest → densest.
  static const heat0 = Color(0xFFE3EFE7);
  static const heat3 = Color(0xFFA9D8C2);
  static const heat4 = Color(0xFF63B995);
  static const heat5 = accent;

  static Color heatFor(int prayed) => switch (prayed) {
        >= 5 => heat5,
        4 => heat4,
        3 => heat3,
        _ => heat0,
      };

  // Home-screen widget surfaces (dark, sit on the launcher wallpaper).
  static const widgetGreenFrom = Color(0xFF1E7A50);
  static const widgetGreenMid = Color(0xFF146C43);
  static const widgetGreenTo = Color(0xFF0E4A30);
  static const widgetNavyFrom = Color(0xFF16324A);
  static const widgetNavyMid = Color(0xFF122A3E);
  static const widgetNavyTo = Color(0xFF0C1E2E);
  static const widgetInkFrom = ink;
  static const widgetInkMid = Color(0xFF0E4A30);
  static const widgetInkTo = Color(0xFF062316);

  static const alert = Color(0xFFEF4444);
  static const alertLight = Color(0xFFFCA5A5);

  /// Amiri — the bundled Naskh face. Arabic set in the app's Latin font falls
  /// back to a system face that renders the ligatures poorly, so every Arabic
  /// string goes through here.
  static const arabicFont = 'Amiri';

  static TextStyle arabic({
    required double fontSize,
    Color color = ink,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) =>
      TextStyle(
        fontFamily: arabicFont,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );

  static const cardRadius = 20.0;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];
}
