import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_ui.dart';
import 'package:lifeque/features/prayer_times/data/services/prayer_settings_service.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.lifeque.prayer_widget';

  Future<void> updateWidget() async {
    try {
      // Use PrayerSettingsService to read the same keys the app writes to
      final settings = PrayerSettingsService.instance;
      await settings.init();

      final locationData = await settings.getSavedLocation();
      if (locationData == null) {
        debugPrint('🕌 Location not set, cannot update widget');
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

      // Render Widget
      await HomeWidget.saveWidgetData<String>(
        'location_name',
        locationData.locationName,
      );

      await HomeWidget.renderFlutterWidget(
        PrayerWidgetUI(
          hijriDate: hijriString,
          gregorianDate: gregorianString,
          currentPrayerName: currentPrayerName,
          timeRange: timeRange,
          prayerTimes: prayerTimes,
          nextPrayer: nextPrayer,
          locationName: locationData.locationName,
        ),
        key: 'prayer_widget_image',
        logicalSize: const Size(380, 180),
      );

      await HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.programmernexus.lifeque.PrayerTimesWidgetProvider',
      );

      debugPrint('✅ Home widget updated successfully');
    } catch (e, stack) {
      debugPrint('❌ Error updating home widget: $e');
      debugPrint('Stack: $stack');
    }
  }
}
