import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../services/language_preference_service.dart';

/// The string bundle for the app's current language, without a [BuildContext].
///
/// Home-screen widgets are rendered through `renderFlutterWidget`, which has no
/// `MaterialApp` above it and therefore no `Localizations` — and notifications
/// are built off the widget tree entirely. Both follow `Intl.defaultLocale`,
/// which the language service sets as soon as the preference is read.
L get appStrings => lookupL(
  Locale((Intl.defaultLocale ?? AppLanguage.fallback.code).split('_').first),
);

/// True when the app is currently reading in Bangla.
bool get isBanglaUi =>
    (Intl.defaultLocale ?? AppLanguage.fallback.code).startsWith('bn');
