import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/tasks/presentation/widgets/birthday_wish/birthday_wish_card.dart';
import 'package:lifeque/features/tasks/presentation/widgets/birthday_wish/wish_messages.dart';
import 'package:lifeque/l10n/app_localizations.dart';

/// Every card style at export size, with the longest stock message and a
/// sender line — proves nothing overflows and leaves PNGs to look at.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'bn';
  });

  test('English ordinals', () {
    Intl.defaultLocale = 'en';
    expect(ordinalAge(1), '1st');
    expect(ordinalAge(2), '2nd');
    expect(ordinalAge(3), '3rd');
    expect(ordinalAge(11), '11th');
    expect(ordinalAge(12), '12th');
    expect(ordinalAge(13), '13th');
    expect(ordinalAge(21), '21st');
    expect(ordinalAge(22), '22nd');
    expect(ordinalAge(112), '112th');
    Intl.defaultLocale = 'bn';
    expect(ordinalAge(25), '২৫তম');
  });

  for (final style in WishCardStyle.values) {
    testWidgets('${style.name} card renders at 1080² without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      late L l;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('bn'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Builder(
            builder: (context) {
              l = L.of(context);
              return Scaffold(
                body: RepaintBoundary(
                  key: key,
                  child: BirthdayWishCard(
                    style: style,
                    name: 'আব্দুল্লাহ আল মামুন',
                    age: 25,
                    message: WishTone.warm.message(l, 'আব্দুল্লাহ আল মামুন'),
                    from: 'নাহিয়ান',
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('build/share_previews')
          ..createSync(recursive: true);
        File(
          '${out.path}/wish_${style.name}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
