import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lifeque/core/services/in_app_update_service.dart';
import 'package:lifeque/l10n/app_localizations.dart';

void main() {
  final info = AppUpdateInfo(
    updateAvailability: UpdateAvailability.updateAvailable,
    immediateUpdateAllowed: true,
    immediateAllowedPreconditions: null,
    flexibleUpdateAllowed: true,
    flexibleAllowedPreconditions: null,
    availableVersionCode: 31,
    installStatus: InstallStatus.unknown,
    packageName: 'com.programmernexus.lifeque',
    clientVersionStalenessDays: null,
    updatePriority: 0,
  );

  testWidgets('the update offer renders in Bangla', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(body: UpdateSheet(info: info)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('নতুন সংস্করণ এসেছে'), findsOneWidget);
    expect(find.text('এখনই আপডেট করুন'), findsOneWidget);
    expect(find.text('পরে'), findsOneWidget);
  });
}
