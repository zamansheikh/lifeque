import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../../../core/utils/local_clock.dart';
import '../../../core/utils/local_numbers.dart';
import '../../../core/utils/app_strings.dart';
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

  /// The English keys are what the calculator returns; the widget shows them
  /// in whichever language the app is set to.
  static String _prayerName(String key) {
    final index = _fard.indexOf(key);
    if (index < 0) return key;
    return isBanglaUi ? _banglaPrayerNames[index] : _fard[index];
  }

  static const _restrictedOrder = [
    'Sunrise Period',
    'Zawal (Midday)',
    'Sunset Period',
  ];
  static List<String> get _restrictedLabels => [
    appStrings.prayerSunrise,
    appStrings.widgetZawal,
    appStrings.widgetSunset,
  ];

  /// Times on a widget read like times everywhere else in the app: 12-hour,
  /// in the reader's own digits, with the Bangla part-of-day where that is the
  /// language.
  static String _t12(DateTime t) => Clock.h12(t);

  static String _hms(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s ~/ 60) % 60)}:${two(s % 60)}';
  }

  static String _short(Duration d) {
    final m = d.isNegative ? 0 : d.inMinutes;
    return m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';
  }

  /// Hands the native providers the words for their "not loaded yet" state.
  ///
  /// Those live in an Android layout, so by default they would follow the
  /// *system* language — a phone set to English would show English placeholders
  /// even with the app in Bangla. Pushing them across the same SharedPreferences
  /// the widget data already travels through keeps them on the app's language.
  Future<void> _savePlaceholderText() async {
    final l = appStrings;
    await Future.wait([
      HomeWidget.saveWidgetData(
        'placeholder_prayer_title',
        l.widgetPrayerTimes,
      ),
      HomeWidget.saveWidgetData(
        'placeholder_prayer_body',
        l.widgetLoadingPrayer,
      ),
      HomeWidget.saveWidgetData(
        'placeholder_mosque_title',
        l.widgetMosqueJamaat,
      ),
      HomeWidget.saveWidgetData(
        'placeholder_mosque_body',
        l.widgetLoadingJamaat,
      ),
      HomeWidget.saveWidgetData('placeholder_day_title', l.widgetDayMap),
      HomeWidget.saveWidgetData('placeholder_day_body', l.widgetLoadingDayMap),
      HomeWidget.saveWidgetData('placeholder_slim_title', l.widgetNextPrayer),
      HomeWidget.saveWidgetData('placeholder_slim_body', l.widgetLoadingPrayer),
    ]);
  }

  /// Wraps a widget face so its Bangla renders in the bundled Noto Serif
  /// Bengali.
  ///
  /// These are drawn by `renderFlutterWidget`, outside the app's `MaterialApp`,
  /// so the theme's font never reaches them — the Bangla fell back to whatever
  /// the device happened to have, with metrics that do not sit with the Latin
  /// beside it. Set once at the root: every `Text` below merges with this
  /// unless it names a family of its own.
  static Widget _withFonts(Widget face) => DefaultTextStyle.merge(
    style: const TextStyle(fontFamilyFallback: ['NotoSerifBengali']),
    child: face,
  );

  Future<void> updateWidget() async {
    if (!isHomeWidgetSupported) {
      debugPrint('🕌 Home widgets not supported on this platform — skipping');
      return;
    }
    try {
      await _savePlaceholderText();
      final bundle = await _buildAll(measured: true);

      if (bundle == null) {
        // No saved location yet — nothing truthful to draw.
        //
        // Rendered at each widget's *measured* cell size, the same as the real
        // ones. Rendering every placeholder at the nominal 380×180 left the
        // PNG letterboxed inside its ImageView on any other cell shape, which
        // is what made it look like a widget inside a widget. All four get one
        // now, so none is left showing the bare XML fallback.
        debugPrint('🕌 Location not set — rendering placeholder widgets');
        const placeholders = [
          ('prayer_widget_image', _widgetSize, _prayerQualifiedName),
          ('mosque_widget_image', _widgetSize, _mosqueQualifiedName),
          ('day_timeline_widget_image', _timelineSize, _timelineQualifiedName),
          ('slim_bar_widget_image', _slimSize, _slimQualifiedName),
        ];

        for (final (key, fallback, provider) in placeholders) {
          final size = await _cellSize(key, fallback);
          await HomeWidget.renderFlutterWidget(
            _withFonts(PrayerWidgetPlaceholder(size: size)),
            key: key,
            logicalSize: size,
            pixelRatio: 3.0,
          );
          await HomeWidget.updateWidget(qualifiedAndroidName: provider);
        }

        debugPrint('✅ Placeholder widgets rendered');
        return;
      }

      await HomeWidget.renderFlutterWidget(
        _withFonts(bundle.prayer),
        key: 'prayer_widget_image',
        logicalSize: bundle.prayerSize,
        pixelRatio: 3.0,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _prayerQualifiedName);
      debugPrint('✅ Prayer widget updated successfully');

      await HomeWidget.renderFlutterWidget(
        _withFonts(bundle.timeline),
        key: 'day_timeline_widget_image',
        logicalSize: bundle.timelineSize,
        pixelRatio: 3.0,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _timelineQualifiedName,
      );
      debugPrint('✅ Day timeline widget updated successfully');

      await HomeWidget.renderFlutterWidget(
        _withFonts(bundle.slim),
        key: 'slim_bar_widget_image',
        logicalSize: bundle.slimSize,
        pixelRatio: 3.0,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _slimQualifiedName);
      debugPrint('✅ Slim bar widget updated successfully');

      await HomeWidget.renderFlutterWidget(
        _withFonts(bundle.mosque),
        key: 'mosque_widget_image',
        logicalSize: bundle.mosqueSize,
        pixelRatio: 3.0,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _mosqueQualifiedName);
      debugPrint('✅ Mosque widget updated successfully');
    } catch (e, stack) {
      debugPrint('❌ Error updating home widget: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// The same four widgets the launcher gets, ready to be shown inside the
  /// app.
  ///
  /// The "add a widget" sheet used to offer four coloured rectangles with an
  /// icon in them, which told you nothing about what you were about to put on
  /// your home screen. These are the real things, drawn from the real prayer
  /// times, so the preview and the widget cannot drift apart.
  ///
  /// Null when there is no saved location — there is nothing honest to draw.
  Future<WidgetPreviews?> buildPreviews() async {
    try {
      final bundle = await _buildAll(measured: false);
      if (bundle == null) return null;
      return WidgetPreviews(
        currentWaqt: bundle.prayer,
        currentWaqtSize: bundle.prayerSize,
        mosqueJamaat: bundle.mosque,
        mosqueJamaatSize: bundle.mosqueSize,
        dayMap: bundle.timeline,
        dayMapSize: bundle.timelineSize,
        slimBar: bundle.slim,
        slimBarSize: bundle.slimSize,
      );
    } catch (e) {
      debugPrint('🕌 Could not build widget previews: $e');
      return null;
    }
  }

  /// Assembles all four widget UIs from the saved location and settings.
  ///
  /// [measured] renders at the cell size each launcher actually handed the
  /// provider, so the PNG lands 1:1 in the widget. The in-app preview passes
  /// false and gets the nominal design sizes instead, which look the same on
  /// every device — and which avoid a plugin call that throws on iOS.
  Future<_WidgetBundle?> _buildAll({required bool measured}) async {
    final settings = PrayerSettingsService.instance;
    await settings.init();

    final locationData = await settings.getSavedLocation();
    debugPrint(
      '🕌 Background Service: Saved Location: ${locationData?.locationName}, '
      'Lat: ${locationData?.latitude}',
    );
    if (locationData == null) return null;

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
    final nextWindow = windows.where((w) => w.start.isAfter(date)).firstOrNull;
    final avoidText = activeWindow != null
        ? appStrings.widgetAvoidNow(_short(activeWindow.end.difference(date)))
        : nextWindow != null
        ? appStrings.widgetNextAvoid(nextWindow.name, _t12(nextWindow.start))
        : appStrings.widgetAvoidPassed;

    final prayerSize = measured
        ? await _cellSize('prayer_widget_image', _widgetSize)
        : _widgetSize;
    final mosqueSize = measured
        ? await _cellSize('mosque_widget_image', _widgetSize)
        : _widgetSize;
    final timelineSize = measured
        ? await _cellSize('day_timeline_widget_image', _timelineSize)
        : _timelineSize;
    final slimSize = measured
        ? await _cellSize('slim_bar_widget_image', _slimSize)
        : _slimSize;

    final sunriseStr = _t12(times['Sunrise']!).toUpperCase();
    final sunsetStr = _t12(times['Maghrib']!).toUpperCase();
    final sahriStr = _t12(times['Fajr']!).toUpperCase();
    final iftarStr = _t12(times['Maghrib']!).toUpperCase();
    final updatedAt = _t12(date).toUpperCase();

    final prayer = PrayerWidgetUI(
      size: prayerSize,
      hijriLine:
          '${N.plain(hijri.hDay)} ${HijriNames.monthNow(hijri.hMonth)} '
          '${N.plain(hijri.hYear)}, ${DateFormat('EEEE').format(date)}',
      secondaryDateLine:
          '${DateFormat('d MMMM').format(date)} · ${bangla.formatted}',
      updatedAt: updatedAt,
      prayerName: _prayerName(subject),
      windowRange:
          '${_t12(times[subject]!).toUpperCase()} – '
          '${_t12(windowEnd).toUpperCase()}',
      endsLine: appStrings.widgetEndsIn(
        _t12(windowEnd).toUpperCase(),
        _hms(windowEnd.difference(date)),
      ),
      nextChip: '${_prayerName(next)} ${_t12(nextTime).toUpperCase()}',
      avoidText: avoidText,
      avoidActive: activeWindow != null,
      sunrise: sunriseStr,
      sunset: sunsetStr,
      sahri: sahriStr,
      iftar: iftarStr,
    );

    final timeline = DayTimelineWidgetUI(
      size: timelineSize,
      now: _dayFraction(date),
      avoidText: avoidText,
      avoidActive: activeWindow != null,
      blocks: [
        for (final w in windows)
          TimelineBlock(start: _dayFraction(w.start), end: _dayFraction(w.end)),
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
    );

    final slim = SlimBarWidgetUI(
      size: slimSize,
      prayerName: subject,
      windowRange:
          '${_t12(times[subject]!).toUpperCase()} – '
          '${_t12(windowEnd).toUpperCase()}',
      countdown: _hms(windowEnd.difference(date)),
      countdownLabel: current == null ? 'starts in' : 'waqt ends in',
    );

    final mosque = await _buildMosque(
      size: mosqueSize,
      settings: settings,
      date: date,
      times: times,
      current: subject,
      dateLine:
          '${N.plain(hijri.hDay)} ${HijriNames.monthNow(hijri.hMonth)} '
          '${N.plain(hijri.hYear)}, '
          '${DateFormat('EEEE').format(date)} · '
          '${DateFormat('d MMMM').format(date)}',
      updatedAt: updatedAt,
      sunrise: sunriseStr,
      sunset: sunsetStr,
      sahri: sahriStr,
      iftar: iftarStr,
    );

    return _WidgetBundle(
      prayer: prayer,
      prayerSize: prayerSize,
      timeline: timeline,
      timelineSize: timelineSize,
      slim: slim,
      slimSize: slimSize,
      mosque: mosque,
      mosqueSize: mosqueSize,
    );
  }

  Future<MosqueWidgetUI> _buildMosque({
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
        jamaat = DateTime(date.year, date.month, date.day, saved.$1, saved.$2);
      } else {
        // Nothing saved yet (fresh install): fall back to the customary
        // offset rather than the waqt itself, which no mosque prays at.
        jamaat =
            JamaatDefaults.forPrayer(prayer, times[prayer]!) ?? times[prayer]!;
      }

      chips.add(
        JamaatChip(
          label: _banglaPrayerNames[i],
          time: _t12(jamaat).toUpperCase(),
          isCurrent: prayer == current,
        ),
      );
    }

    return MosqueWidgetUI(
      size: size,
      dateLine: dateLine,
      updatedAt: updatedAt,
      sunrise: sunrise,
      sunset: sunset,
      sahri: sahri,
      iftar: iftar,
      jamaat: chips,
    );
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

/// The four assembled widget UIs and the size each was laid out for.
class _WidgetBundle {
  final Widget prayer;
  final Size prayerSize;
  final Widget timeline;
  final Size timelineSize;
  final Widget slim;
  final Size slimSize;
  final Widget mosque;
  final Size mosqueSize;

  const _WidgetBundle({
    required this.prayer,
    required this.prayerSize,
    required this.timeline,
    required this.timelineSize,
    required this.slim,
    required this.slimSize,
    required this.mosque,
    required this.mosqueSize,
  });
}

/// Live previews of the home-screen widgets, for showing inside the app.
///
/// Each comes with the size it was laid out at so the caller can scale it
/// down without guessing its aspect ratio.
class WidgetPreviews {
  final Widget currentWaqt;
  final Size currentWaqtSize;
  final Widget mosqueJamaat;
  final Size mosqueJamaatSize;
  final Widget dayMap;
  final Size dayMapSize;
  final Widget slimBar;
  final Size slimBarSize;

  const WidgetPreviews({
    required this.currentWaqt,
    required this.currentWaqtSize,
    required this.mosqueJamaat,
    required this.mosqueJamaatSize,
    required this.dayMap,
    required this.dayMapSize,
    required this.slimBar,
    required this.slimBarSize,
  });
}
