import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_ui.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_placeholder.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/mosque_widget_ui.dart';
import 'package:lifeque/features/prayer_times/data/services/prayer_settings_service.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

/// App Group id shared between the Runner app and an iOS WidgetKit extension.
///
/// iOS home-screen widgets need both a widget extension target and an App
/// Group container; the Runner project currently has neither, so every
/// `home_widget` call on iOS fails with `AppGroupId not set`. Once the
/// extension and the App Group capability are added in Xcode, set this to the
/// group id (e.g. `group.com.programmernexus.lifeque`) and iOS widget updates
/// turn on with no other code changes.
const String? kIosWidgetAppGroupId = null;

/// Whether home-screen widgets can be driven on the current platform.
bool get isHomeWidgetSupported =>
    Platform.isAndroid || (Platform.isIOS && kIosWidgetAppGroupId != null);

/// Hand the App Group id to the plugin before any other widget call.
/// No-op on Android and on iOS builds without a configured group.
Future<void> initHomeWidget() async {
  if (Platform.isIOS && kIosWidgetAppGroupId != null) {
    await HomeWidget.setAppGroupId(kIosWidgetAppGroupId!);
  }
}

class HomeWidgetService {
  static const String _prayerQualifiedName =
      'com.programmernexus.lifeque.PrayerTimesWidgetProvider';
  static const String _mosqueQualifiedName =
      'com.programmernexus.lifeque.MosqueTimesWidgetProvider';
  static const Size _widgetSize = Size(380, 180);

  Future<void> updateWidget() async {
    if (!isHomeWidgetSupported) {
      debugPrint('🕌 Home widgets not supported on this platform — skipping');
      return;
    }
    try {
      final settings = PrayerSettingsService.instance;
      await settings.init();

      final locationData = await settings.getSavedLocation();
      debugPrint(
        '🕌 Background Service: Saved Location: ${locationData?.locationName}, Lat: ${locationData?.latitude}',
      );

      if (locationData == null) {
        // Render placeholder widget when location is not set
        debugPrint('🕌 Location not set — rendering placeholder widget');
        await HomeWidget.renderFlutterWidget(
          const PrayerWidgetPlaceholder(),
          key: 'prayer_widget_image',
          logicalSize: _widgetSize,
          pixelRatio: 3.0,
        );
        await HomeWidget.updateWidget(
          qualifiedAndroidName: _prayerQualifiedName,
        );

        // Also render placeholder for mosque widget
        await HomeWidget.renderFlutterWidget(
          const PrayerWidgetPlaceholder(),
          key: 'mosque_widget_image',
          logicalSize: _widgetSize,
          pixelRatio: 3.0,
        );
        await HomeWidget.updateWidget(
          qualifiedAndroidName: _mosqueQualifiedName,
        );

        debugPrint('✅ Placeholder widgets rendered');
        return;
      }

      final method = await settings.getCalculationMethod();
      final madhab = await settings.getMadhab();

      // Calculate Prayer Times
      final date = DateTime.now();
      final calculator = SalahTimeCalculator(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        date: date,
        method: method,
        madhab: madhab,
      );

      final prayerTimes = calculator.getPrayerTimes();
      final currentPrayer = calculator.getCurrentPrayer() ?? Prayer.none;
      final nextPrayer = calculator.getNextPrayer() ?? Prayer.none;

      // Format Data
      final hijriDate = HijriCalendar.fromDate(date);
      final hijriString =
          '${hijriDate.hDay} ${hijriDate.longMonthName}, ${DateFormat('EEEE').format(date)}';
      final gregorianString = DateFormat('d MMMM').format(date);

      final currentPrayerName = currentPrayer.displayName;

      // Time Range
      String timeRange = '';
      if (currentPrayer != Prayer.none) {
        final currentStart = prayerTimes.timeForPrayer(currentPrayer);
        final nextStart = prayerTimes.timeForPrayer(nextPrayer);

        if (currentStart != null && nextStart != null) {
          timeRange =
              '${DateFormat('h:mm a').format(currentStart)} - ${DateFormat('h:mm a').format(nextStart)}';
        } else if (currentPrayer == Prayer.isha) {
          final ishaStart = prayerTimes.isha;
          timeRange = DateFormat('h:mm a').format(ishaStart);
        }
      }

      // ── End Time ──
      final startTimes = calculator.getStartTimes();
      final endTimes = calculator.getEndTimes(startTimes);
      String? endTimeStr;
      if (currentPrayer != Prayer.none) {
        final endTime = endTimes[currentPrayerName];
        if (endTime != null) {
          endTimeStr = DateFormat('h:mm a').format(endTime);
        }
      }

      // ── Next Prayer ──
      String? nextPrayerNameStr;
      String? nextPrayerTimeStr;
      if (nextPrayer != Prayer.none) {
        nextPrayerNameStr = nextPrayer.displayName;
        final nextTime = prayerTimes.timeForPrayer(nextPrayer);
        if (nextTime != null) {
          nextPrayerTimeStr = DateFormat('h:mm a').format(nextTime);
        }
      }

      // ── Prohibited Time ──
      String? activeProhibited;
      final restrictedTimes = calculator.getRestrictedTimes();
      final now = DateTime.now();
      for (final entry in restrictedTimes.entries) {
        final start = entry.value['start'] as DateTime;
        final end = entry.value['end'] as DateTime;
        if (now.isAfter(start) && now.isBefore(end)) {
          activeProhibited =
              '${entry.key}: ${DateFormat('h:mm').format(start)} - ${DateFormat('h:mm a').format(end)}';
          break;
        }
      }

      // ── Render Prayer Times Widget ──
      await HomeWidget.renderFlutterWidget(
        PrayerWidgetUI(
          hijriDate: hijriString,
          gregorianDate: gregorianString,
          currentPrayerName: currentPrayerName,
          timeRange: timeRange,
          prayerTimes: prayerTimes,
          nextPrayer: nextPrayer,
          locationName: locationData.locationName,
          endTimeStr: endTimeStr,
          nextPrayerName: nextPrayerNameStr,
          nextPrayerTimeStr: nextPrayerTimeStr,
          activeProhibited: activeProhibited,
        ),
        key: 'prayer_widget_image',
        logicalSize: _widgetSize,
        pixelRatio: 3.0,
      );

      await HomeWidget.updateWidget(qualifiedAndroidName: _prayerQualifiedName);
      debugPrint('✅ Prayer widget updated successfully');

      // ── Render Mosque Times Widget ──
      await _updateMosqueWidget(
        settings: settings,
        calculator: calculator,
        hijriString: hijriString,
        gregorianString: gregorianString,
        currentPrayerName: currentPrayerName,
        prayerTimes: prayerTimes,
        activeProhibited: activeProhibited,
      );
    } catch (e, stack) {
      debugPrint('❌ Error updating home widget: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _updateMosqueWidget({
    required PrayerSettingsService settings,
    required SalahTimeCalculator calculator,
    required String hijriString,
    required String gregorianString,
    required String currentPrayerName,
    required PrayerTimes prayerTimes,
    String? activeProhibited,
  }) async {
    try {
      // Load mosque times from settings
      final fajrStr = await settings.getMosqueTime('fajr');
      final dhuhrStr = await settings.getMosqueTime('dhuhr');
      final asrStr = await settings.getMosqueTime('asr');
      final ishaStr = await settings.getMosqueTime('isha');

      // Format mosque times for display
      final isRamadan = await settings.getRamadanMode();

      // Format mosque times
      String fajrDisplay;
      if (isRamadan) {
        final fTime = prayerTimes.fajr.add(const Duration(minutes: 15));
        fajrDisplay = DateFormat('h:mm a').format(fTime);
      } else {
        fajrDisplay = _formatMosqueTime(fajrStr) ?? '5:00 AM';
      }

      String maghribDisplay;
      if (isRamadan) {
        final mTime = prayerTimes.maghrib.add(const Duration(minutes: 15));
        maghribDisplay = DateFormat('h:mm a').format(mTime);
      } else {
        maghribDisplay = DateFormat('h:mm a').format(prayerTimes.maghrib);
      }

      final Map<String, String> mosqueTimes = {
        'Fajr': fajrDisplay,
        'Dhuhr': _formatMosqueTime(dhuhrStr) ?? '1:30 PM',
        'Asr': _formatMosqueTime(asrStr) ?? '4:30 PM',
        'Maghrib': maghribDisplay,
        'Isha': _formatMosqueTime(ishaStr) ?? '8:00 PM',
      };

      await HomeWidget.renderFlutterWidget(
        MosqueWidgetUI(
          hijriDate: hijriString,
          gregorianDate: gregorianString,
          locationName: '',
          mosqueTimes: mosqueTimes,
          currentPrayer: currentPrayerName,
          sunrise: prayerTimes.sunrise,
          sunset: prayerTimes.maghrib,
          sahri: prayerTimes.fajr,
          iftar: prayerTimes.maghrib,
          activeProhibited: activeProhibited,
        ),
        key: 'mosque_widget_image',
        logicalSize: _widgetSize,
        pixelRatio: 3.0,
      );

      await HomeWidget.updateWidget(qualifiedAndroidName: _mosqueQualifiedName);
      debugPrint('✅ Mosque widget updated successfully');
    } catch (e, stack) {
      debugPrint('❌ Error updating mosque widget: $e');
      debugPrint('Stack: $stack');
    }
  }

  String? _formatMosqueTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return null;
    }
  }
}
