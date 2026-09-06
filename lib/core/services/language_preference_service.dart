import 'package:shared_preferences/shared_preferences.dart';

/// The languages the app offers.
///
/// Only [english] is translated so far. Bangla is listed because the choice
/// is being collected now and the strings land in the next iteration; the
/// picker says so rather than pretending the switch does something.
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

  /// Name in English, for the settings row's subtitle.
  final String label;

  /// Name in its own script, for the option itself.
  final String nativeLabel;

  /// Whether the app actually has strings for this language yet.
  bool get isTranslated => this == AppLanguage.english;

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (language) => language.code == code,
    orElse: () => AppLanguage.english,
  );
}

/// Persists the chosen app language.
///
/// Reading it back is all this does for now — nothing localises off it yet.
/// It exists so the preference survives the update that adds the Bangla
/// strings, instead of asking everyone again.
class LanguagePreferenceService {
  static const _key = 'app_language_code';

  static final LanguagePreferenceService instance =
      LanguagePreferenceService._();

  LanguagePreferenceService._();

  Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguage.fromCode(prefs.getString(_key));
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
  }
}
