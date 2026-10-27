import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/subscription.dart';

/// Currencies a subscription can be billed in, with their symbols.
const subscriptionCurrencies = {
  'BDT': '৳',
  'USD': r'$',
  'EUR': '€',
  'INR': '₹',
  'GBP': '£',
};

/// "৳৫০০" / "$9.99" — digits in the app language, cents only when there
/// are any. Reads Intl.defaultLocale, so it works in notifications too.
String formatMoney(double amount, String currency) {
  final symbol = subscriptionCurrencies[currency] ?? '$currency ';
  final whole = amount == amount.roundToDouble();
  final f = NumberFormat.decimalPatternDigits(decimalDigits: whole ? 0 : 2);
  return '$symbol${f.format(amount)}';
}

extension SubscriptionCategoryUi on SubscriptionCategory {
  IconData get icon => switch (this) {
    SubscriptionCategory.streaming => Icons.live_tv_rounded,
    SubscriptionCategory.music => Icons.music_note_rounded,
    SubscriptionCategory.cloud => Icons.cloud_rounded,
    SubscriptionCategory.software => Icons.apps_rounded,
    SubscriptionCategory.internet => Icons.wifi_rounded,
    SubscriptionCategory.education => Icons.school_rounded,
    SubscriptionCategory.fitness => Icons.fitness_center_rounded,
    SubscriptionCategory.news => Icons.newspaper_rounded,
    SubscriptionCategory.gaming => Icons.sports_esports_rounded,
    SubscriptionCategory.other => Icons.autorenew_rounded,
  };

  Color get color => switch (this) {
    SubscriptionCategory.streaming => const Color(0xFFE11D48),
    SubscriptionCategory.music => const Color(0xFF16A34A),
    SubscriptionCategory.cloud => const Color(0xFF0284C7),
    SubscriptionCategory.software => const Color(0xFF7C3AED),
    SubscriptionCategory.internet => const Color(0xFF0D9488),
    SubscriptionCategory.education => const Color(0xFFD97706),
    SubscriptionCategory.fitness => const Color(0xFFEA580C),
    SubscriptionCategory.news => const Color(0xFF475569),
    SubscriptionCategory.gaming => const Color(0xFF4F46E5),
    SubscriptionCategory.other => const Color(0xFF64748B),
  };

  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      SubscriptionCategory.streaming => l.subCatStreaming,
      SubscriptionCategory.music => l.subCatMusic,
      SubscriptionCategory.cloud => l.subCatCloud,
      SubscriptionCategory.software => l.subCatSoftware,
      SubscriptionCategory.internet => l.subCatInternet,
      SubscriptionCategory.education => l.subCatEducation,
      SubscriptionCategory.fitness => l.subCatFitness,
      SubscriptionCategory.news => l.subCatNews,
      SubscriptionCategory.gaming => l.subCatGaming,
      SubscriptionCategory.other => l.subCatOther,
    };
  }
}

extension BillingCycleUi on BillingCycle {
  /// "Monthly" — for the chooser.
  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      BillingCycle.weekly => l.subCycleWeekly,
      BillingCycle.monthly => l.subCycleMonthly,
      BillingCycle.quarterly => l.subCycleQuarterly,
      BillingCycle.halfYearly => l.subCycleHalfYearly,
      BillingCycle.yearly => l.subCycleYearly,
    };
  }

  /// "/ month" — after a price.
  String perFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      BillingCycle.weekly => l.subPerWeek,
      BillingCycle.monthly => l.subPerMonth,
      BillingCycle.quarterly => l.subPer3Months,
      BillingCycle.halfYearly => l.subPer6Months,
      BillingCycle.yearly => l.subPerYear,
    };
  }
}

/// Colour for how close a renewal is.
Color statusColor(RenewalStatus status) => switch (status) {
  RenewalStatus.overdue => const Color(0xFFDC2626),
  RenewalStatus.dueSoon => const Color(0xFFD97706),
  RenewalStatus.upcoming => const Color(0xFF059669),
  RenewalStatus.cancelled => const Color(0xFF94A3B8),
};

/// A few well-known services, one tap to fill the form.
class SubscriptionPreset {
  final String name;
  final SubscriptionCategory category;
  final String currency;
  const SubscriptionPreset(this.name, this.category, [this.currency = 'USD']);
}

const subscriptionPresets = [
  SubscriptionPreset('Netflix', SubscriptionCategory.streaming),
  SubscriptionPreset('YouTube Premium', SubscriptionCategory.streaming),
  SubscriptionPreset('Spotify', SubscriptionCategory.music),
  SubscriptionPreset('Google One', SubscriptionCategory.cloud),
  SubscriptionPreset('iCloud+', SubscriptionCategory.cloud),
  SubscriptionPreset('ChatGPT Plus', SubscriptionCategory.software),
  SubscriptionPreset('Microsoft 365', SubscriptionCategory.software),
  SubscriptionPreset('Amazon Prime', SubscriptionCategory.streaming),
  SubscriptionPreset('Chorki', SubscriptionCategory.streaming, 'BDT'),
  SubscriptionPreset('Hoichoi', SubscriptionCategory.streaming, 'BDT'),
];
