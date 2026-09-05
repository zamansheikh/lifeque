import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_ui.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_placeholder.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/day_timeline_widget_ui.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/mosque_widget_ui.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/slim_bar_widget_ui.dart';
import 'package:lifeque/features/prayer_times/data/services/jamaat_defaults.dart';
import 'package:lifeque/features/prayer_times/data/services/prayer_settings_service.dart';
import 'package:lifeque/features/prayer_times/presentation/utils/bangla_date.dart';
import 'package:lifeque/features/prayer_times/presentation/utils/hijri_names.dart';
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
  static const String _timelineQualifiedName =
      'com.programmernexus.lifeque.DayTimelineWidgetProvider';
  static const String _slimQualifiedName =
      'com.programmernexus.lifeque.SlimBarWidgetProvider';
  static const Size _widgetSize = Size(380, 180);
  static const Size _timelineSize = Size(380, 132);
  static const Size _slimSize = Size(380, 64);

  /// The day track spans 04:00 → 20:00, so every prayer of a normal day
  /// lands inside it without wasting width on the empty small hours.
  static const _dayStartMinutes = 240;
  static const _daySpanMinutes = 960;

  /// The cell size each provider last reported, or [fallback] before one has.
  ///
  /// Rendering at the real cell size means the PNG lands 1:1 in the widget —
  /// no stretching from fitXY and no letterbox from fitCenter, on any device.
  Future<Size> _cellSize(String key, Size fallback) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('${key}_size');
      if (raw == null) return fallback;
      final parts = raw.split('x');
      if (parts.length != 2) return fallback;
      final w = double.tryParse(parts[0]);
      final h = double.tryParse(parts[1]);
      if (w == null || h == null || w < 60 || h < 40) return fallback;
      return Size(w, h);
    } catch (e) {
      debugPrint('🕌 Could not read cell size for $key: $e');
      return fallback;
    }
  }

  static double _dayFraction(DateTime t) =>
      (((t.hour * 60 + t.minute) - _dayStartMinutes) / _daySpanMinutes).clamp(
        0.0,
        1.0,
      );

  static const _fard = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _banglaPrayerNames = ['ফজর', 'যোহর', 'আসর', 'মাগরিব', 'এশা'];
  static const _restrictedOrder = [
    'Sunrise Period',
    'Zawal (Midday)',
    'Sunset Period',
  ];
  static const _restrictedLabels = ['Sunrise', 'Zawal', 'Sunset'];

  static String _t12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} '
        '${t.hour < 12 ? 'am' : 'pm'}';
  }

  static String _hms(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s ~/ 60) % 60)}:${two(s % 60)}';
  }

  static String _short(Duration d) {
    final m = d.isNegative ? 0 : d.inMinutes;
    return m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';
  }

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

      final date = DateTime.now();
      final calculator = SalahTimeCalculator(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        date: date,
        method: method,
        madhab: madhab,
      );

      final times = calculator.getPrayerTimesMap();
      final endTimes = calculator.getEndTimes(calculator.getStartTimes());
      final hijri = HijriCalendar.fromDate(date);
      final bangla = BanglaDate.fromDate(date);

      // The prayer the widget is about: the running waqt, else the next one.
      String? current;
      for (final p in _fard) {
        if (times[p]!.isBefore(date)) current = p;
      }
      final next = _fard.firstWhere(
        (p) => times[p]!.isAfter(date),
        orElse: () => 'Fajr',
      );
      final subject = current ?? next;
      final windowEnd =
          endTimes[subject] ?? times['Fajr']!.add(const Duration(days: 1));
      final nextTime = current == null
          ? times[next]!
          : (times[next]!.isAfter(date)
                ? times[next]!
                : times['Fajr']!.add(const Duration(days: 1)));

      // Prohibited-time state.
      final restricted = calculator.getRestrictedTimes();
      final windows = [
        for (final key in _restrictedOrder)
          (
            name: _restrictedLabels[_restrictedOrder.indexOf(key)],
            start: restricted[key]!['start'] as DateTime,
            end: restricted[key]!['end'] as DateTime,
          ),
      ];
      final activeWindow = windows
          .where((w) => date.isAfter(w.start) && date.isBefore(w.end))
          .firstOrNull;
      final nextWindow = windows
          .where((w) => w.start.isAfter(date))
          .firstOrNull;
      final avoidText = activeWindow != null
          ? '⛔ AVOID NOW · ${_short(activeWindow.end.difference(date))} left'
          : nextWindow != null
          ? 'next avoid · ${nextWindow.name} ${_t12(nextWindow.start)}'
          : 'all avoid-times passed';

      // Render each widget at the size its host actually gave it.
      final prayerSize = await _cellSize('prayer_widget_image', _widgetSize);
      final mosqueSize = await _cellSize('mosque_widget_image', _widgetSize);
      final timelineSize = await _cellSize(
        'day_timeline_widget_image',
        _timelineSize,
      );
      final slimSize = await _cellSize('slim_bar_widget_image', _slimSize);

      final sunriseStr = _t12(times['Sunrise']!).toUpperCase();
      final sunsetStr = _t12(times['Maghrib']!).toUpperCase();
      final sahriStr = _t12(times['Fajr']!).toUpperCase();
      final iftarStr = _t12(times['Maghrib']!).toUpperCase();
      final updatedAt = _t12(date).toUpperCase();

      // ── Render the current-waqt widget ──
      await HomeWidget.renderFlutterWidget(
        PrayerWidgetUI(
          size: prayerSize,
          hijriLine:
              '${hijri.hDay} ${HijriNames.month(hijri.hMonth)} '
              '${hijri.hYear}, ${DateFormat('EEEE').format(date)}',
          secondaryDateLine:
              '${DateFormat('d MMMM').format(date)} · ${bangla.formatted}',
          updatedAt: updatedAt,
          prayerName: subject,
          windowRange:
              '${_t12(times[subject]!).toUpperCase()} – '
              '${_t12(windowEnd).toUpperCase()}',
          endsLine:
              'Ends: ${_t12(windowEnd).toUpperCase()} · in '
              '${_hms(windowEnd.difference(date))}',
          nextChip: '$next ${_t12(nextTime).toUpperCase()}',
          avoidText: avoidText,
          avoidActive: activeWindow != null,
          sunrise: sunriseStr,
          sunset: sunsetStr,
          sahri: sahriStr,
          iftar: iftarStr,
        ),
        key: 'prayer_widget_image',
        logicalSize: prayerSize,
        pixelRatio: 3.0,
      );

      await HomeWidget.updateWidget(qualifiedAndroidName: _prayerQualifiedName);
      debugPrint('✅ Prayer widget updated successfully');

      // ── Render the day-timeline widget ──
      await HomeWidget.renderFlutterWidget(
        DayTimelineWidgetUI(
          size: timelineSize,
          now: _dayFraction(date),
          avoidText: avoidText,
          avoidActive: activeWindow != null,
          blocks: [
            for (final w in windows)
              TimelineBlock(
                start: _dayFraction(w.start),
                end: _dayFraction(w.end),
              ),
          ],
          ticks: [
            for (final p in _fard)
              TimelineTick(
                position: _dayFraction(times[p]!),
                label: p.substring(0, 3).toUpperCase(),
                passed: !times[p]!.isAfter(date),
                isCurrent: p == subject,
              ),
          ],
        ),
        key: 'day_timeline_widget_image',
        logicalSize: timelineSize,
        pixelRatio: 3.0,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _timelineQualifiedName,
      );
      debugPrint('✅ Day timeline widget updated successfully');

      // ── Render the slim bar widget ──
      await HomeWidget.renderFlutterWidget(
        SlimBarWidgetUI(
          size: slimSize,
          prayerName: subject,
          windowRange:
              '${_t12(times[subject]!).toUpperCase()} – '
              '${_t12(windowEnd).toUpperCase()}',
          countdown: _hms(windowEnd.difference(date)),
          countdownLabel: current == null ? 'starts in' : 'waqt ends in',
        ),
        key: 'slim_bar_widget_image',
        logicalSize: slimSize,
        pixelRatio: 3.0,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _slimQualifiedName);
      debugPrint('✅ Slim bar widget updated successfully');

      // ── Render the mosque jamaat widget ──
      await _updateMosqueWidget(
        size: mosqueSize,
        settings: settings,
        date: date,
        times: times,
        current: subject,
        dateLine:
            '${hijri.hDay} ${HijriNames.month(hijri.hMonth)} ${hijri.hYear}, '
            '${DateFormat('EEEE').format(date)} · '
            '${DateFormat('d MMMM').format(date)}',
        updatedAt: updatedAt,
        sunrise: sunriseStr,
        sunset: sunsetStr,
        sahri: sahriStr,
        iftar: iftarStr,
      );
    } catch (e, stack) {
      debugPrint('❌ Error updating home widget: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _updateMosqueWidget({
    required Size size,
    required PrayerSettingsService settings,
    required DateTime date,
    required Map<String, DateTime> times,
    required String current,
    required String dateLine,
    required String updatedAt,
    required String sunrise,
    required String sunset,
    required String sahri,
    required String iftar,
  }) async {
    try {
      final ramadan = await settings.getRamadanMode();

      final chips = <JamaatChip>[];
      for (var i = 0; i < _fard.length; i++) {
        final prayer = _fard[i];
        final saved = _parseMosqueTime(
          await settings.getMosqueTime(prayer.toLowerCase()),
        );

        // Ramadan mode derives Fajr and Maghrib jamaat from waqt + 15 min;
        // everything else falls back to the waqt itself when unset.
        final DateTime jamaat;
        if (ramadan && (prayer == 'Fajr' || prayer == 'Maghrib')) {
          jamaat = times[prayer]!.add(const Duration(minutes: 15));
        } else if (saved != null) {
          jamaat = DateTime(
            date.year,
            date.month,
            date.day,
            saved.$1,
            saved.$2,
          );
        } else {
          // Nothing saved yet (fresh install): fall back to the customary
          // offset rather than the waqt itself, which no mosque prays at.
          jamaat =
              JamaatDefaults.forPrayer(prayer, times[prayer]!) ??
              times[prayer]!;
        }

        chips.add(
          JamaatChip(
            label: _banglaPrayerNames[i],
            time: _t12(jamaat).toUpperCase(),
            isCurrent: prayer == current,
          ),
        );
      }

      await HomeWidget.renderFlutterWidget(
        MosqueWidgetUI(
          size: size,
          dateLine: dateLine,
          updatedAt: updatedAt,
          sunrise: sunrise,
          sunset: sunset,
          sahri: sahri,
          iftar: iftar,
          jamaat: chips,
        ),
        key: 'mosque_widget_image',
        logicalSize: size,
        pixelRatio: 3.0,
      );

      await HomeWidget.updateWidget(qualifiedAndroidName: _mosqueQualifiedName);
      debugPrint('✅ Mosque widget updated successfully');
    } catch (e, stack) {
      debugPrint('❌ Error updating mosque widget: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// `13:30` → `(13, 30)`.
  (int, int)? _parseMosqueTime(String? raw) {
    if (raw == null) return null;
    try {
      final parts = raw.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }
}
