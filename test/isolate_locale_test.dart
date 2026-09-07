import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/services/language_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // A fresh isolate: nothing has told intl what language we are.
    Intl.defaultLocale = null;
    SharedPreferences.setMockInitialValues({'app_language_code': 'bn'});
  });

  test('intl latches the locale on the first format — the trap', () {
    expect(Intl.defaultLocale, isNull);
    DateFormat('h:mm'); // any constructor will do
    expect(
      Intl.defaultLocale,
      isNotNull,
      reason: 'getCurrentLocale() is `defaultLocale ??= systemLocale`',
    );
  });

  test('prepareIsolate wins even after the latch has fired', () async {
    DateFormat('h:mm'); // latched to the phone locale, as the widget path did
    await LanguagePreferenceService.prepareIsolate();

    expect(Intl.defaultLocale, 'bn');
    // Bangla digits prove the *formatter* follows, not just the flag.
    expect(DateFormat('h:mm').format(DateTime(2026, 9, 7, 11, 51)), '১১:৫১');
  });

  test('prepareIsolate is safe to call again in the running app', () async {
    await LanguagePreferenceService.prepareIsolate();
    await LanguagePreferenceService.prepareIsolate();
    expect(Intl.defaultLocale, 'bn');
  });
}
