import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_ui.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_placeholder.dart';
import 'package:lifeque/features/prayer_times/data/services/prayer_settings_service.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class HomeWidgetService {
  static const String _qualifiedName =
      'com.programmernexus.lifeque.PrayerTimesWidgetProvider';
  static const Size _widgetSize = Size(380, 180);

  Future<void> updateWidget() async {
    try {
      final settings = PrayerSettingsService.instance;
      await settings.init();

      final locationData = await settings.getSavedLocation();

      if (locationData == null) {
        // Render placeholder widget when location is not set
        debugPrint('🕌 Location not set — rendering placeholder widget');
        await HomeWidget.renderFlutterWidget(
          const PrayerWidgetPlaceholder(),
          key: 'prayer_widget_image',
          logicalSize: _widgetSize,
        );
        await HomeWidget.updateWidget(qualifiedAndroidName: _qualifiedName);
        debugPrint('✅ Placeholder widget rendered');
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
        logicalSize: _widgetSize,
      );

      await HomeWidget.updateWidget(qualifiedAndroidName: _qualifiedName);
      debugPrint('✅ Home widget updated successfully');
    } catch (e, stack) {
      debugPrint('❌ Error updating home widget: $e');
      debugPrint('Stack: $stack');
    }
  }
}
