import 'package:flutter/material.dart';

/// A piece of guide content in every language the app ships.
///
/// The salah guide is prose, not UI chrome: paragraphs of fiqh that a scholar
/// needs to be able to read side by side and correct. Keeping both languages
/// on the same line does that, and makes it impossible for a translation to
/// drift away from the English it belongs to — which a parallel data file or a
/// wall of ARB keys would both allow.
class LText {
  final String en;
  final String bn;

  const LText(this.en, this.bn);

  /// Falls back to English wherever a Bangla rendering is not written yet.
  String of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'bn' && bn.isNotEmpty
      ? bn
      : en;
}

// ─── Data model ──────────────────────────────────────────────────────────────
class SalahDua {
  /// Never translated — this is the du'a itself.
  final String arabic;

  /// How to say it, written in the reader's own script.
  final LText? transliteration;

  final LText? translation;

  const SalahDua({
    required this.arabic,
    this.transliteration,
    this.translation,
  });
}

class SalahStep {
  final String id;

  /// Arabic name of the step. Content, so never translated.
  final String arabicName;

  final LText name;
  final String phase; // 'before' | 'during' | 'after'
  final IconData icon;
  final LText shortDesc;
  final LText detailDesc;
  final List<LText> keyPoints;
  final List<SalahDua>? duas;

  const SalahStep({
    required this.id,
    required this.arabicName,
    required this.name,
    required this.phase,
    required this.icon,
    required this.shortDesc,
    required this.detailDesc,
    required this.keyPoints,
    this.duas,
  });
}

class SalahSection {
  final LText title;
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
  final LText title;
  final LText subtitle;
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
