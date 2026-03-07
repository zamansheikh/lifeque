import 'package:flutter/material.dart';

// ─── Data model ──────────────────────────────────────────────────────────────
class SalahStep {
  final String id;
  final String arabicName;
  final String englishName;
  final String phase; // 'before' | 'during' | 'after'
  final IconData icon;
  final String shortDesc;
  final String detailDesc;
  final List<String> keyPoints;
  final String? arabicDua;
  final String? transliteration;
  final String? translation;

  const SalahStep({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.phase,
    required this.icon,
    required this.shortDesc,
    required this.detailDesc,
    required this.keyPoints,
    this.arabicDua,
    this.transliteration,
    this.translation,
  });
}

class SalahTypeData {
  final String id;
  final String title;
  final String subtitle;
  final String arabicTitle;
  final IconData icon;
  final List<SalahStep> steps;

  const SalahTypeData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.arabicTitle,
    required this.icon,
    required this.steps,
  });
}
