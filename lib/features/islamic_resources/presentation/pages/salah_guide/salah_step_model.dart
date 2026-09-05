import 'package:flutter/material.dart';

// ─── Data model ──────────────────────────────────────────────────────────────
class SalahDua {
  final String arabic;
  final String? transliteration;
  final String? translation;

  const SalahDua({
    required this.arabic,
    this.transliteration,
    this.translation,
  });
}

class SalahStep {
  final String id;
  final String arabicName;
  final String englishName;
  final String phase; // 'before' | 'during' | 'after'
  final IconData icon;
  final String shortDesc;
  final String detailDesc;
  final List<String> keyPoints;
  final List<SalahDua>? duas;

  const SalahStep({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.phase,
    required this.icon,
    required this.shortDesc,
    required this.detailDesc,
    required this.keyPoints,
    this.duas,
  });
}

class SalahSection {
  final String title;
  final String arabicTitle;
  final List<SalahStep> steps;

  const SalahSection({
    required this.title,
    required this.arabicTitle,
    required this.steps,
  });
}

class SalahTypeData {
  final String id;
  final String title;
  final String subtitle;
  final String arabicTitle;
  final IconData icon;
  final List<SalahSection> sections;

  const SalahTypeData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.arabicTitle,
    required this.icon,
    required this.sections,
  });

  int get totalSteps =>
      sections.fold(0, (sum, section) => sum + section.steps.length);
}
