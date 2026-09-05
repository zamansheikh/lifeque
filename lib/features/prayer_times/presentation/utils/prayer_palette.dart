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
