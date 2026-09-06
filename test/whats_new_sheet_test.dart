import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/whats_new/domain/release_notes.dart';
import 'package:lifeque/features/whats_new/presentation/whats_new_sheet.dart';
import 'package:lifeque/l10n/app_localizations.dart';

/// Mirrors what the app does at startup: the widget locale and
/// `Intl.defaultLocale` are set together, because numbers come from `intl`
/// while the words come from `Localizations`.
Widget host(Locale locale, ReleaseNote note) {
  Intl.defaultLocale = locale.languageCode;
  return _host(locale, note);
}

Widget _host(Locale locale, ReleaseNote note) => MaterialApp(
  locale: locale,
  supportedLocales: L.supportedLocales,
  localizationsDelegates: const [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: WhatsNewSheet(note: note)),
);

void main() {
  final note = kReleaseNotes.first;

  testWidgets('renders in Bangla, with Bangla digits in the version', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Locale('bn'), note));
    await tester.pumpAndSettle();

    expect(find.text('নতুন যা আছে'), findsOneWidget);
    expect(find.text(note.headlineBn), findsOneWidget);
    // 2.0.0 → ২.০.০
    expect(find.text('সংস্করণ ২.০.০'), findsOneWidget);
    expect(find.text('বুঝেছি'), findsOneWidget);
    expect(find.text(note.lines.first.bn), findsOneWidget);
    // and nothing leaks through in the other language
    expect(find.text(note.headlineEn), findsNothing);
  });

  testWidgets('renders in English', (tester) async {
    await tester.pumpWidget(host(const Locale('en'), note));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
    expect(find.text(note.headlineEn), findsOneWidget);
    expect(find.text('Version 2.0.0'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text(note.headlineBn), findsNothing);
  });

  testWidgets('shows every line of the release note', (tester) async {
    await tester.pumpWidget(host(const Locale('en'), note));
    await tester.pumpAndSettle();

    for (final line in note.lines) {
      // The list scrolls, so drag each one into view before asserting.
      await tester.scrollUntilVisible(find.text(line.en), 120);
      expect(find.text(line.en), findsOneWidget);
    }
  });
}
