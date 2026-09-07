import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages the app is available in.
enum AppLanguage {
  english(code: 'en', label: 'English', nativeLabel: 'English'),
  bangla(code: 'bn', label: 'Bangla', nativeLabel: 'বাংলা');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });

  /// IETF tag, and what gets persisted.
  final String code;

  /// Name in English, for a settings row's subtitle.
  final String label;

  /// Name in its own script, for the option itself.
  final String nativeLabel;

  Locale get locale => Locale(code);

  /// What the app speaks before anyone has chosen — and the fallback for a
  /// stored code we no longer recognise.
  static const AppLanguage fallback = AppLanguage.bangla;

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (language) => language.code == code,
    orElse: () => fallback,
  );
}

/// Holds and persists the chosen app language.
///
/// The value is a [ValueNotifier] so `MaterialApp`'s locale can follow it —
/// switching language has to repaint the app that is already on screen, not
/// just the next launch.
class LanguagePreferenceService {
  static const _key = 'app_language_code';

  static final LanguagePreferenceService instance =
      LanguagePreferenceService._();

  LanguagePreferenceService._();

  final ValueNotifier<AppLanguage> language = ValueNotifier(
    AppLanguage.fallback,
  );

  /// Everything an isolate must do before it formats a single date or number.
  ///
  /// Reads the stored language, sets `Intl.defaultLocale`, and loads the date
  /// symbols — in that order. The order is not cosmetic: `intl` implements
  /// `getCurrentLocale()` as `defaultLocale ??= systemLocale`, a *latching*
  /// write that every `DateFormat` and `NumberFormat` constructor triggers.
  /// So in an isolate that has not been told the app's language, the first
  /// format call quietly pins the locale to the phone's `en_US` for the rest
  /// of that isolate's life. That is how a Bangla widget re-rendered from the
  /// refresh button, or from the 15-minute background job, came back half in
  /// English: strings read before the first format were Bangla, everything
  /// after it was not.
  ///
  /// Called from `main()` and from each background entry point. Cheap and
  /// idempotent, so calling it again in the app is harmless.
  static Future<void> prepareIsolate() async {
    await instance.load();
    await initializeDateFormatting();
  }

  /// Reads the stored choice. Called once during startup, before `runApp`, so
  /// the first frame is already in the right language.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = AppLanguage.fromCode(prefs.getString(_key));
    // Set here as well as in the widget tree: notifications and other work
    // off the main isolate format dates and numbers without ever building a
    // widget, and would otherwise fall back to English.
    Intl.defaultLocale = language.value.code;
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (language.value != value) language.value = value;
    Intl.defaultLocale = value.code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.code);
  }

  AppLanguage get current => language.value;
}
