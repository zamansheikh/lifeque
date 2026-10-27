import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// The icons a habit can wear; a habit stores the index.
const habitIcons = <IconData>[
  Icons.water_drop_rounded,
  Icons.wb_sunny_rounded,
  Icons.menu_book_rounded,
  Icons.fitness_center_rounded,
  Icons.auto_stories_rounded,
  Icons.nightlight_round,
  Icons.directions_walk_rounded,
  Icons.king_bed_rounded,
  Icons.mosque_rounded,
  Icons.self_improvement_rounded,
  Icons.restaurant_rounded,
  Icons.favorite_rounded,
];

/// The colours a habit can wear; a habit stores the index.
const habitColors = <Color>[
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
  Color(0xFF059669),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF4F46E5),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
];

IconData habitIcon(int i) => habitIcons[i.clamp(0, habitIcons.length - 1)];
Color habitColor(int i) => habitColors[i.clamp(0, habitColors.length - 1)];

/// A ready-made habit: name, icon index, colour index.
typedef HabitIdea = (String Function(L) name, int icon, int color);

final habitIdeas = <HabitIdea>[
  ((l) => l.habitPresetWater, 0, 0),
  ((l) => l.habitPresetMorningAdhkar, 1, 1),
  ((l) => l.habitPresetQuran, 2, 2),
  ((l) => l.habitPresetExercise, 3, 3),
  ((l) => l.habitPresetRead, 4, 4),
  ((l) => l.habitPresetTahajjud, 5, 5),
  ((l) => l.habitPresetWalk, 6, 6),
  ((l) => l.habitPresetSleepAdhkar, 7, 7),
];
