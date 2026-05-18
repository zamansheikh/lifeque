import 'package:flutter/material.dart';

/// Central palette for the Islamic-themed prayer experience.
///
/// Built around three core colour families:
///   • **Emerald greens** — the canonical Islamic green, used for primary
///     surfaces and "active/positive" states.
///   • **Antique golds** — for highlights, focus rings, accents on dark
///     surfaces; lends a calligraphic/luxurious feel.
///   • **Deep midnight / teal** — for night-time skies and quiet surfaces.
///
/// Plus a warm parchment cream for off-white text/cards so nothing feels
/// clinical.
class IslamicColors {
  IslamicColors._();

  // Greens
  static const emerald = Color(0xFF0F5132);
  static const emeraldMid = Color(0xFF146C43);
  static const emeraldLight = Color(0xFF20A56D);
  static const mint = Color(0xFFB8E5C9);

  // Golds
  static const gold = Color(0xFFD4AF37);
  static const goldDeep = Color(0xFFB8901E);
  static const goldLight = Color(0xFFF5D27A);
  static const goldGlow = Color(0xFFFFE082);

  // Blues / midnight
  static const midnight = Color(0xFF0A1428);
  static const midnightDeep = Color(0xFF050A14);
  static const teal = Color(0xFF0E5E5C);
  static const tealDeep = Color(0xFF073E3D);
  static const tealLight = Color(0xFF3CA5A1);

  // Warm tones
  static const cream = Color(0xFFFAF6EC);
  static const sandstone = Color(0xFFD4A574);
  static const burgundy = Color(0xFF6E1B1B);
  static const sunset = Color(0xFFD97548);

  // Semantic
  static const warning = Color(0xFFEF4444);
  static const warningLight = Color(0xFFFCA5A5);
}
