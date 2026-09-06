import 'package:flutter/widgets.dart';

import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/medicine.dart';

/// Display forms for the medicine enums and figures.
///
/// The entity keeps English `typeDisplayName` / `mealTimingDisplayName` for
/// logs; these are what the screen and the notifications should use.
String medicineTypeLabel(BuildContext context, MedicineType type) {
  final l = L.of(context);
  return switch (type) {
    MedicineType.tablet => l.medTablet,
    MedicineType.capsule => l.medCapsule,
    MedicineType.syrup => l.medSyrup,
    MedicineType.injection => l.medInjection,
    MedicineType.drops => l.medDrops,
    MedicineType.cream => l.medCream,
    MedicineType.spray => l.medSpray,
    MedicineType.other => l.medOther,
  };
}

String mealTimingLabel(BuildContext context, MealTiming timing) {
  final l = L.of(context);
  return switch (timing) {
    MealTiming.beforeMeal => l.medBeforeMeal,
    MealTiming.afterMeal => l.medAfterMeal,
    MealTiming.withMeal => l.medWithMeal,
    MealTiming.onEmptyStomach => l.medEmptyStomach,
    MealTiming.anytime => l.medAnytime,
  };
}

/// "৫০০ mg" — the dose without the trailing `.0` that a double leaves behind.
///
/// Units stay as stored: mg and ml are written the same in both languages, and
/// the word units are translated by the form that offers them.
String doseLabel(num dosage, String unit) {
  final rounded = dosage == dosage.roundToDouble()
      ? N.plain(dosage.round())
      : N.of(dosage);
  return '$rounded $unit';
}
