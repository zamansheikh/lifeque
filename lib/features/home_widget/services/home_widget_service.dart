import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../../../core/utils/local_clock.dart';
import '../../../core/utils/local_numbers.dart';
import '../../../core/utils/app_strings.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/prayer_widget_ui.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/widget_placeholder.dart';
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

/// Parses the `465x350,615x350` list the Android providers publish.
///
/// Keeps the tag string exactly as written: the provider builds its lookup key
/// from the same integers, so re-formatting a double here ("465.0x350.0")
/// would silently miss every bitmap.
List<({String tag, Size size})> parseWidgetSizes(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final seen = <String>{};
  final out = <({String tag, Size size})>[];
  for (final part in raw.split(',')) {
    final tag = part.trim();
    final m = RegExp(r'^(\d+)x(\d+)$').firstMatch(tag);
    if (m == null) continue;
    final w = double.parse(m[1]!);
    final h = double.parse(m[2]!);
    if (w < 60 || h < 40) continue;
    if (seen.add(tag)) out.add((tag: tag, size: Size(w, h)));
  }
  return out;
}

/// The tag a [Size] would be reported under.
String widgetSizeTag(Size size) =>
    '${size.width.round()}x${size.height.round()}';

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
  /// Every distinct cell size the launcher has reported for [key], each with
  /// the exact tag the provider will look the bitmap up by.
  ///
  /// Falls back to the single legacy size — or the nominal design size — so a
  /// widget added before any size was reported still gets an image.
  Future<List<({String tag, Size size})>> _cellSizes(
    String key,
    Size fallback,
  ) async {
    try {
      final parsed = parseWidgetSizes(
        await HomeWidget.getWidgetData<String>('${key}_sizes'),
      );
      if (parsed.isNotEmpty) return parsed;
    } catch (e) {
      debugPrint('🕌 Could not read cell sizes for $key: $e');
    }
    final single = await _cellSize(key, fallback);
    return [(tag: widgetSizeTag(single), size: single)];
  }

  /// Renders [build] once per reported size and once under the plain [key],
  /// then tells the provider to redraw.
  ///
  /// The plain key is what an instance reads before it has told us its size,
  /// so it is always written too — at the first size, which on most phones is
  /// the only one.
  Future<void> _renderAll({
    required String key,
    required Size fallback,
    required String provider,
    required Widget Function(Size) build,
  }) async {
    final sizes = await _cellSizes(key, fallback);
    for (final (:tag, :size) in sizes) {
      await HomeWidget.renderFlutterWidget(
        _withFonts(build(size)),
        key: '${key}_$tag',
        logicalSize: size,
        pixelRatio: 3.0,
      );
    }
    final first = sizes.first.size;
    await HomeWidget.renderFlutterWidget(
      _withFonts(build(first)),
      key: key,
      logicalSize: first,
      pixelRatio: 3.0,
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: provider);
  }

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

  static const _shortPrayerNames = ['ফজ', 'জোহ', 'আস', 'মাগ', 'এশা'];

  /// The three-letter tick under the day map: FAJ / ফজ.
  static String _shortPrayerName(String key) {
    final index = _fard.indexOf(key);
    if (index < 0) return key;
    return isBanglaUi
        ? _shortPrayerNames[index]
        : _fard[index].substring(0, 3).toUpperCase();
  }

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

  /// `০২:০৪:৫০` — the countdown in the reader's own digits, like every
  /// other number on the widget.
  static String _hms(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => N.padded2(v);
    return '${two(s ~/ 3600)}:${two((s ~/ 60) % 60)}:${two(s % 60)}';
  }

  /// `2h 14m` / `২ ঘ ১৪ মি`
  static String _short(Duration d) {
    final m = d.isNegative ? 0 : d.inMinutes;
    return m >= 60
        ? appStrings.durationHm(N.of(m ~/ 60), N.of(m % 60))
        : appStrings.durationM(N.of(m));
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
      // The native side pushes the launcher-picker preview and needs to know
      // when the language changed so it pushes a fresh one.
      HomeWidget.saveWidgetData('widget_language', isBanglaUi ? 'bn' : 'en'),
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
        // Each placeholder carries the gradient and radius of the widget it
        // stands in for, and is rendered at that widget's *measured* cell, so
        // it fills the surface exactly. The native fallback in the layouts is
        // only a stopgap for the instant before this lands: RemoteViews cannot
        // load our font, so its Bangla would be in a system face.
        debugPrint('🕌 Location not set — rendering placeholder widgets');
        const placeholders = [
          (
            'prayer_widget_image',
            _widgetSize,
            _prayerQualifiedName,
            [Color(0xFF1E7A50), Color(0xFF146C43), Color(0xFF0E4A30)],
            20.0,
          ),
          (
            'mosque_widget_image',
            _widgetSize,
            _mosqueQualifiedName,
            [Color(0xFF16324A), Color(0xFF122A3E), Color(0xFF0C1E2E)],
            20.0,
          ),
          (
            'day_timeline_widget_image',
            _timelineSize,
            _timelineQualifiedName,
            [Color(0xFF123B2C), Color(0xFF0E4A30), Color(0xFF062316)],
            20.0,
          ),
          (
            'slim_bar_widget_image',
            _slimSize,
            _slimQualifiedName,
            [Color(0xFF1E7A50), Color(0xFF0E4A30)],
            16.0,
          ),
        ];

        for (final (key, fallback, provider, gradient, radius)
            in placeholders) {
          await _renderAll(
            key: key,
            fallback: fallback,
            provider: provider,
            build: (size) => WidgetPlaceholder(
              size: size,
              gradient: gradient,
              radius: radius,
            ),
          );
        }
        debugPrint('✅ Placeholder widgets rendered');
        return;
      }

      await _renderAll(
        key: 'prayer_widget_image',
        fallback: _widgetSize,
        provider: _prayerQualifiedName,
        build: bundle.prayer,
      );
      await _renderAll(
        key: 'day_timeline_widget_image',
        fallback: _timelineSize,
        provider: _timelineQualifiedName,
        build: bundle.timeline,
      );
      await _renderAll(
        key: 'slim_bar_widget_image',
        fallback: _slimSize,
        provider: _slimQualifiedName,
        build: bundle.slim,
      );
      await _renderAll(
        key: 'mosque_widget_image',
        fallback: _widgetSize,
        provider: _mosqueQualifiedName,
        build: bundle.mosque,
      );
      debugPrint('✅ All widgets rendered at every reported size');
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
        currentWaqt: bundle.prayer(bundle.prayerSize),
        currentWaqtSize: bundle.prayerSize,
        mosqueJamaat: bundle.mosque(bundle.mosqueSize),
        mosqueJamaatSize: bundle.mosqueSize,
        dayMap: bundle.timeline(bundle.timelineSize),
        dayMapSize: bundle.timelineSize,
        slimBar: bundle.slim(bundle.slimSize),
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
    // Between sunrise and Dhuhr nothing is running, and the widget counts
    // down to Dhuhr rather than showing a dead Fajr at 00:00:00.
    final nextFajr = times['Fajr']!.add(const Duration(days: 1));
    final current = calculator.currentFard(date);
    final next = _fard.firstWhere(
      (p) => times[p]!.isAfter(date),
      orElse: () => 'Fajr',
    );
    final subject = current ?? next;
    final windowEnd = endTimes[subject] ?? nextFajr;
    // With no running waqt the countdown is to the next start, not its end,
    // and the name says "Next:" so the widget cannot pass for a waqt in
    // progress — the same rule as the in-app gauge.
    final countdownTarget = current == null ? times[subject]! : windowEnd;
    final subjectLabel = current == null
        ? appStrings.gaugeNext(_prayerName(subject))
        : _prayerName(subject);
    final nextTime = current == null
        ? times[next]!
        : (times[next]!.isAfter(date) ? times[next]! : nextFajr);

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

    Widget prayer(Size size) => PrayerWidgetUI(
      size: size,
      hijriLine:
          '${N.plain(hijri.hDay)} ${HijriNames.monthNow(hijri.hMonth)} '
          '${N.plain(hijri.hYear)}, ${DateFormat('EEEE').format(date)}',
      secondaryDateLine:
          '${DateFormat('d MMMM').format(date)} · ${bangla.formatted}',
      updatedAt: updatedAt,
      prayerName: subjectLabel,
      windowRange:
          '${_t12(times[subject]!).toUpperCase()} – '
          '${_t12(windowEnd).toUpperCase()}',
      endsLine: current == null
          ? appStrings.widgetStartsIn(
              _t12(times[subject]!).toUpperCase(),
              _hms(countdownTarget.difference(date)),
            )
          : appStrings.widgetEndsIn(
              _t12(windowEnd).toUpperCase(),
              _hms(countdownTarget.difference(date)),
            ),
      nextChip: '${_prayerName(next)} ${_t12(nextTime).toUpperCase()}',
      avoidText: avoidText,
      avoidActive: activeWindow != null,
      sunrise: sunriseStr,
      sunset: sunsetStr,
      sahri: sahriStr,
      iftar: iftarStr,
    );

    Widget timeline(Size size) => DayTimelineWidgetUI(
      size: size,
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
            label: _shortPrayerName(p),
            passed: !times[p]!.isAfter(date),
            isCurrent: p == current,
          ),
      ],
    );

    Widget slim(Size size) => SlimBarWidgetUI(
      size: size,
      prayerName: subjectLabel,
      windowRange:
          '${_t12(times[subject]!).toUpperCase()} – '
          '${_t12(windowEnd).toUpperCase()}',
      countdown: _hms(countdownTarget.difference(date)),
      countdownLabel: current == null
          ? appStrings.gaugeStartsIn
          : appStrings.gaugeWaqtEndsIn,
    );

    // Jamaat times come from settings, so they are read once here rather
    // than inside the per-size builder.
    final jamaat = await _jamaatChips(
      settings: settings,
      date: date,
      times: times,
      current: current,
      next: next,
    );
    Widget mosque(Size size) => MosqueWidgetUI(
      size: size,
      jamaat: jamaat,
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

  Future<List<JamaatChip>> _jamaatChips({
    required PrayerSettingsService settings,
    required DateTime date,
    required Map<String, DateTime> times,
    required String? current,
    required String next,
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
          // Filled only while that waqt is running. Between waqts the next
          // one is outlined instead — a filled Dhuhr at ten in the morning
          // read as "Dhuhr now", and someone could pray on that.
          isCurrent: prayer == current,
          isNext: current == null && prayer == next,
        ),
      );
    }

    return chips;
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
/// The four widget faces, as functions of a cell size.
///
/// Builders rather than built widgets because one launcher can hold two of
/// the same widget at different sizes, and each needs its own bitmap. The
/// `*Size` beside each is the size to use when nothing more specific is
/// known: the in-app preview, and the un-suffixed image a fresh instance
/// reads before it has reported its dimensions.
class _WidgetBundle {
  final Widget Function(Size) prayer;
  final Size prayerSize;
  final Widget Function(Size) timeline;
  final Size timelineSize;
  final Widget Function(Size) slim;
  final Size slimSize;
  final Widget Function(Size) mosque;
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
