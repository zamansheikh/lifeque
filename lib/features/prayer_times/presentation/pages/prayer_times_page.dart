import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/presentation/widgets/add_widget_sheet.dart';
import 'package:lifeque/features/home_widget/services/home_widget_service.dart';
import 'package:lifeque/features/home_widget/services/widget_suggestion_service.dart';

import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/alarm_sound_utils.dart';
import '../../../islamic_resources/presentation/pages/islamic_resources_page.dart'
    hide IslamicColors;
import '../../data/services/prayer_completion_service.dart';
import '../../data/services/jamaat_defaults.dart';
import '../../data/services/prayer_settings_service.dart';
import '../utils/bangla_date.dart';
import '../utils/islamic_colors.dart';
import '../utils/prayer_palette.dart';
import '../widgets/mosque_time_edit_sheet.dart';
import '../widgets/nafal_times_card.dart';
import '../widgets/prayer_alarm_sheet.dart';
import '../widgets/prayer_snack.dart';
import '../widgets/prayer_focus_card.dart' show QuickAlarmChoice;
import '../widgets/prayer_sky_header.dart';
import '../widgets/prohibited_times_card.dart';
import '../widgets/ramadan_strip_card.dart';
import '../widgets/restricted_times_card.dart';
import '../widgets/salat_times_card.dart';

/// "Prayer Compass" — the prayer-times screen.
///
/// One scrolling page (no tabs):
///   ┌─────────────────────────────┐
///   │  Dawn header (gradient)     │
///   │   location · cycling date   │
///   │   semicircular waqt gauge   │
///   │   hill silhouette           │
///   ├─────────────────────────────┤
///   │  Salat Times card           │
///   │  Ramadan strip (optional)   │
///   │  Prohibited Times card      │
///   │  Nafal Prayer Time card     │
///   └─────────────────────────────┘
///
/// Horizontal swipe across the body changes the displayed day.
class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  // ── Core prayer state ────────────────────────────────────────────────────
  SalahTimeCalculator? _calculator;
  CalculationMethod _selectedMethod = CalculationMethod.karachi;
  Madhab _selectedMadhab = Madhab.hanafi;
  DateTime _selectedDate = DateTime.now();

  // ── Location ────────────────────────────────────────────────────────────
  double _latitude = 23.8103;
  double _longitude = 90.4125;
  String _locationName = 'Dhaka, Bangladesh';
  bool _isLocationFromGps = false;
  bool _isLocationUpdating = false;

  bool _isLoading = true;
  String? _error;

  // ── Services ────────────────────────────────────────────────────────────
  final PrayerSettingsService _settingsService = PrayerSettingsService.instance;
  final PrayerCompletionService _completionService =
      PrayerCompletionService.instance;
  final PrayerAlarmService _alarmService = PrayerAlarmService();

  // ── Page-swipe state ────────────────────────────────────────────────────
  static const int _todayPage = 10000;
  late final PageController _pageController =
      PageController(initialPage: _todayPage);

  // ── Interactive state ───────────────────────────────────────────────────
  Timer? _tickTimer;

  /// True once the body has scrolled off the top — drives the status-bar scrim.
  final ValueNotifier<bool> _scrolled = ValueNotifier(false);

  Set<String> _completions = {};
  int _streak = 0;
  List<PrayerAlarmConfig> _alarms = const [];
  StreamSubscription<List<PrayerAlarmConfig>>? _alarmsSub;

  Map<String, TimeOfDay?> _mosqueTimes = {};
  bool _ramadanMode = false;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _loadMosqueState();
    _initAlarmStream();
    _loadDayState(_selectedDate);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _maybeSuggestWidget();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _alarmsSub?.cancel();
    _pageController.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  /// Once prayer times are actually set up, offer to put them on the home
  /// screen — the way a weather or calendar app does. Shown at most once;
  /// [WidgetSuggestionService] holds the "asked already" state.
  Future<void> _maybeSuggestWidget() async {
    // Let the screen settle first so the sheet doesn't fight the first frame.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final location = await _settingsService.getSavedLocation();
    final should = await WidgetSuggestionService.instance
        .shouldSuggest(hasLocation: location != null);
    if (!should || !mounted) return;
    await AddWidgetSheet.show(context, isSuggestion: true);
  }

  // ── Loaders ─────────────────────────────────────────────────────────────

  Future<void> _loadSavedSettings() async {
    await _loadFromSavedData();
    _updateLocationInBackground();
  }

  Future<void> _loadFromSavedData() async {
    try {
      _selectedMethod = await _settingsService.getCalculationMethod();
      _selectedMadhab = await _settingsService.getMadhab();
      final savedLocation = await _settingsService.getSavedLocation();
      if (savedLocation != null) {
        setState(() {
          _latitude = savedLocation.latitude;
          _longitude = savedLocation.longitude;
          _locationName = savedLocation.locationName;
          _isLocationFromGps = savedLocation.isFromGps;
          _error = null;
          _isLoading = false;
        });
        _recomputeCalculator();
      } else {
        setState(() => _isLoading = true);
        await _requestLocationPermission();
        if (!_isLocationFromGps) {
          setState(() {
            _error =
                'Using default location (Dhaka). Tap the location pin to set yours.';
            _isLoading = false;
          });
        }
        _recomputeCalculator();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading prayer settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMosqueState() async {
    final ramadan = await _settingsService.getRamadanMode();
    final map = <String, TimeOfDay?>{};
    for (final p in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final raw = await _settingsService.getMosqueTime(p);
      map[_capitalize(p)] = _parseTime(raw);
    }
    if (!mounted) return;
    setState(() {
      _ramadanMode = ramadan;
      _mosqueTimes = map;
    });
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null) return null;
    try {
      final parts = s.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _initAlarmStream() {
    _alarms = _alarmService.alarms;
    _alarmsSub = _alarmService.alarmsStream.listen((list) {
      if (mounted) setState(() => _alarms = list);
    });
  }

  Future<void> _loadDayState(DateTime date) async {
    final isToday = _isSameDay(date, DateTime.now());
    final completions = await _completionService.getCompletions(date);
    final streak = isToday ? await _completionService.getCurrentStreak() : 0;
    if (!mounted) return;
    setState(() {
      _completions = completions;
      _streak = streak;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Location: kept from previous implementation ─────────────────────────

  Future<void> _updateLocationInBackground() async {
    try {
      setState(() => _isLocationUpdating = true);
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _isLocationUpdating = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLocationUpdating = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final distance = Geolocator.distanceBetween(
        _latitude,
        _longitude,
        position.latitude,
        position.longitude,
      );
      if (distance > 100) {
        await _settingsService.saveLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: 'Current Location',
          isFromGps: true,
        );
        if (!mounted) return;
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationName = 'Current Location';
          _isLocationFromGps = true;
          _error = null;
        });
        _recomputeCalculator();
      }
    } catch (_) {
      // Silent — keep saved/default location.
    } finally {
      if (mounted) setState(() => _isLocationUpdating = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _settingsService.saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: 'Current Location',
        isFromGps: true,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName = 'Current Location';
        _isLocationFromGps = true;
        _error = null;
      });
    } catch (_) {/* swallow */}
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLocationUpdating = true);
    await _requestLocationPermission();
    if (!mounted) return;
    setState(() => _isLocationUpdating = false);
    if (_isLocationFromGps) _recomputeCalculator();
  }

  void _recomputeCalculator() {
    try {
      _calculator = SalahTimeCalculator(
        latitude: _latitude,
        longitude: _longitude,
        date: _selectedDate,
        method: _selectedMethod,
        madhab: _selectedMadhab,
      );
      setState(() {
        _isLoading = false;
        _error = null;
      });
      HomeWidgetService().updateWidget();
    } catch (e) {
      setState(() {
        _error = 'Error calculating prayer times: $e';
        _isLoading = false;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PrayerPalette.accent),
      );
    }
    if (_calculator == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: PrayerPalette.inkA(0.5), size: 56),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to compute prayer times',
              textAlign: TextAlign.center,
              style: TextStyle(color: PrayerPalette.inkA(0.7)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFromSavedData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                // Vertical only — the PageView's own horizontal notifications
                // pass through here too. Depth is 1, not 0: the day ListView
                // sits inside the PageView's viewport.
                if (n.metrics.axis == Axis.vertical) {
                  _scrolled.value = n.metrics.pixels > 4;
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _selectedDate = _dateForPage(page));
                  _recomputeCalculator();
                  _loadDayState(_selectedDate);
                },
                itemBuilder: (context, page) =>
                    _buildDayContent(_dateForPage(page)),
              ),
            ),
            // The header gradient runs edge-to-edge behind the status bar, so
            // at rest there is nothing to draw here. Once the page scrolls,
            // cards would otherwise slide under the clock — fade in a scrim.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _scrolled,
                builder: (context, scrolled, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: MediaQuery.of(context).padding.top,
                  color: scrolled
                      ? PrayerPalette.canvas
                      : Colors.transparent,
                ),
              ),
          ),
        ],
      ),
    );
  }

  DateTime _dateForPage(int page) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return base.add(Duration(days: page - _todayPage));
  }

  SalahTimeCalculator _calculatorForDate(DateTime d) => SalahTimeCalculator(
        latitude: _latitude,
        longitude: _longitude,
        date: d,
        method: _selectedMethod,
        madhab: _selectedMadhab,
      );

  // ── Day content ─────────────────────────────────────────────────────────

  static const List<String> _fardPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  Widget _buildDayContent(DateTime date) {
    final calc = _calculatorForDate(date);
    final times = calc.getPrayerTimesMap();
    final endTimes = calc.getEndTimes(calc.getStartTimes());
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final current = isToday ? _currentPrayerName(times, now) : null;

    final gauge = _gaugeFor(times, endTimes, now, isToday);
    final restrictedNow = isToday ? calc.getCurrentRestrictedPeriod() : null;

    return RefreshIndicator(
      color: PrayerPalette.accent,
      backgroundColor: Colors.white,
      onRefresh: () => _refreshDay(date),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        // AlwaysScrollable so the pull gesture works even when the content
        // is short enough not to scroll.
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
        PrayerSkyHeader(
          locationName: _locationName,
          dateLines: _dateLines(date),
          gaugeName: gauge.name,
          gaugeLabel: gauge.label,
          gaugeCountdown: gauge.countdown,
          progress: gauge.progress,
          onLocationTap: _showSettingsBottomSheet,
          onMenu: () => Scaffold.of(context).openDrawer(),
        ),
        Transform.translate(
          offset: const Offset(0, -14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SalatTimesCard(
              rows: _salatRows(date, times, current),
              summary: _salatSummary(isToday),
              canMarkPrayed: isToday || date.isBefore(now),
              onSetAlarm: _openAlarmSheet,
              onTogglePrayed: (prayer) => _togglePrayed(date, prayer),
              onToggleAlarm: _toggleQuickAlarm,
              onEditJamaat: (prayer) => _openMosqueEdit(prayer, times),
            ),
          ),
        ),
        if (_ramadanMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _ramadanStrip(times, now),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: ProhibitedTimesCard(
            subtitle: _prohibitedSubtitle(calc, now, isToday, restrictedNow),
            chips: _prohibitedChips(calc, now, isToday),
            onSeeReference: () => _openRestrictedSheet(calc),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: NafalTimesCard(
            rows: _nafalRows(calc, date, times),
            footnote: 'Last ⅓ of night begins: '
                '${_fmt12(calc.getSunnahTimes().lastThirdOfTheNight)}',
            onSeeReference: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IslamicResourcesPage(),
              ),
            ),
          ),
        ),
          if (!isToday) _backToTodayButton(),
        ],
      ),
    );
  }

  /// Pull-to-refresh: re-read location and settings, recompute, and reload
  /// this day's completions and mosque times.
  Future<void> _refreshDay(DateTime date) async {
    await _loadFromSavedData();
    await _loadMosqueState();
    await _loadDayState(date);
    if (!mounted) return;
    setState(() {});
  }

  // ── Formatting helpers ──────────────────────────────────────────────────

  /// `4:28 am`
  String _fmt12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
  }

  /// `4:28` — no meridiem, for the Ramadan strip's split layout.
  String _fmtBare(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  String _meridiem(DateTime t) => t.hour < 12 ? 'am' : 'pm';

  /// `01:23:45`
  String _fmtHms(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s ~/ 60) % 60)}:${two(s % 60)}';
  }

  /// `2h 14m` / `43m`
  String _fmtShort(Duration d) {
    final m = d.isNegative ? 0 : d.inMinutes;
    return m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';
  }

  // ── Cycling date line ───────────────────────────────────────────────────

  /// The same date in all three calendars, in carousel order.
  List<String> _dateLines(DateTime date) {
    final dowEn = DateFormat('EEEE').format(date);
    final hijri = HijriCalendar.fromDate(date);
    return [
      '$dowEn, ${hijri.hDay} ${_hijriMonthName(hijri.hMonth)} ${hijri.hYear}',
      '$dowEn, ${DateFormat('MMMM d, y').format(date)}',
      '${BanglaDate.weekdayName(date)}, '
          '${BanglaDate.fromDate(date).formatted}',
    ];
  }

  static String _hijriMonthName(int m) => const [
        'Muharram',
        'Safar',
        'Rabiʿ I',
        'Rabiʿ II',
        'Jumada I',
        'Jumada II',
        'Rajab',
        'Shaʿban',
        'Ramadan',
        'Shawwal',
        'Dhul Qaʿdah',
        'Dhul Hijjah',
      ][(m - 1).clamp(0, 11)];

  // ── Gauge ───────────────────────────────────────────────────────────────

  _GaugeData _gaugeFor(
    Map<String, DateTime> times,
    Map<String, DateTime> endTimes,
    DateTime now,
    bool isToday,
  ) {
    final current = isToday ? _currentPrayerName(times, now) : null;

    if (current != null) {
      // Inside a waqt: count down to its end, fill as it elapses.
      final start = times[current]!;
      final end = endTimes[current] ?? start.add(const Duration(hours: 1));
      final span = end.difference(start).inMilliseconds;
      final gone = now.difference(start).inMilliseconds;
      return _GaugeData(
        name: current,
        label: 'Waqt ends in',
        countdown: _fmtHms(end.difference(now)),
        progress: span <= 0 ? 0 : (gone / span).clamp(0.0, 1.0),
      );
    }

    // Before Fajr (or on another day): count down to the next start over a
    // nominal three-hour approach window.
    final next = _fardPrayers
        .where((p) => times[p] != null && times[p]!.isAfter(now))
        .firstOrNull;
    final target = next != null
        ? times[next]!
        : times['Fajr']!.add(const Duration(days: 1));
    final windowStart = target.subtract(const Duration(hours: 3));
    final span = target.difference(windowStart).inMilliseconds;
    final gone = now.difference(windowStart).inMilliseconds;
    return _GaugeData(
      name: next ?? 'Fajr',
      label: isToday ? 'Starts in' : 'Starts at ${_fmt12(target)}',
      countdown: isToday ? _fmtHms(target.difference(now)) : '--:--:--',
      progress: span <= 0 ? 0 : (gone / span).clamp(0.0, 1.0),
    );
  }

  // ── Salat rows ──────────────────────────────────────────────────────────

  List<SalatRow> _salatRows(
    DateTime date,
    Map<String, DateTime> times,
    String? current,
  ) {
    return [
      for (final prayer in _fardPrayers)
        SalatRow(
          name: prayer,
          time: _fmt12(times[prayer]!),
          jamaat: () {
            final m = _mosqueTimeFor(prayer, date, times);
            return m == null ? null : _fmt12(m);
          }(),
          isCurrent: prayer == current,
          isPrayed: _completions.contains(prayer),
          alarmOn: _alarms.any((a) => a.prayerName == prayer && a.isEnabled),
        ),
    ];
  }

  String _salatSummary(bool isToday) {
    final done = _fardPrayers.where(_completions.contains).length;
    if (!isToday) return '$done/5 prayed';
    return '$done/5 prayed today · 🔥 $_streak-day streak';
  }

  /// The bell toggles a plain on-time alarm; anything more specific lives in
  /// the alarm page.
  Future<void> _toggleQuickAlarm(String prayer) async {
    final existing =
        _alarms.where((a) => a.prayerName == prayer).firstOrNull;
    if (existing != null && existing.isEnabled) {
      await _alarmService.removeAlarm(prayer);
      if (!mounted) return;
      PrayerSnack.show(
        context,
        '$prayer alarm turned off',
        kind: PrayerSnackKind.muted,
      );
      return;
    }
    await _applyQuickAlarm(prayer, QuickAlarmChoice.atTime);
  }

  /// Everything alarm-related lives in this one sheet — timing, adhan sound
  /// and ring length. It talks to PrayerAlarmService directly.
  void _openAlarmSheet() {
    PrayerAlarmSheet.show(context, prayers: _fardPrayers);
  }

  // ── Ramadan strip ───────────────────────────────────────────────────────

  Widget _ramadanStrip(Map<String, DateTime> times, DateTime now) {
    final fajr = times['Fajr']!;
    final maghrib = times['Maghrib']!;
    final hijri = HijriCalendar.fromDate(now);
    final heading = hijri.hMonth == 9
        ? 'RAMADAN · DAY ${hijri.hDay}'
        : 'RAMADAN MODE';
    final iftarTarget = now.isBefore(maghrib)
        ? maghrib
        : maghrib.add(const Duration(days: 1));

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: RamadanStripCard(
        heading: heading,
        sahriTime: _fmtBare(fajr),
        sahriMeridiem: _meridiem(fajr),
        iftarTime: _fmtBare(maghrib),
        iftarMeridiem: _meridiem(maghrib),
        untilIftar: _fmtHms(iftarTarget.difference(now)),
      ),
    );
  }

  // ── Prohibited times ────────────────────────────────────────────────────

  /// Windows in the order the design shows them: morning, noon, evening.
  static const List<String> _restrictedOrder = [
    'Sunrise Period',
    'Zawal (Midday)',
    'Sunset Period',
  ];
  static const List<String> _restrictedLabels = ['Morning', 'Noon', 'Evening'];

  List<ProhibitedChip> _prohibitedChips(
    SalahTimeCalculator calc,
    DateTime now,
    bool isToday,
  ) {
    final all = calc.getRestrictedTimes();
    return [
      for (var i = 0; i < _restrictedOrder.length; i++)
        () {
          final w = all[_restrictedOrder[i]]!;
          final start = w['start'] as DateTime;
          final end = w['end'] as DateTime;
          return ProhibitedChip(
            label: _restrictedLabels[i],
            range: '${_fmtBare(start)} – ${_fmt12(end)}',
            isActive: isToday && now.isAfter(start) && now.isBefore(end),
          );
        }(),
    ];
  }

  String _prohibitedSubtitle(
    SalahTimeCalculator calc,
    DateTime now,
    bool isToday,
    Map<String, dynamic>? activeNow,
  ) {
    if (isToday && activeNow != null) {
      final remaining = activeNow['remaining'] as Duration;
      return '⛔ Active now · ${_fmtShort(remaining)} left — salat is '
          'prohibited during these times.';
    }
    if (!isToday) {
      return 'Salat is prohibited during these times.';
    }
    final upcoming = _restrictedOrder
        .map((k) => calc.getRestrictedTimes()[k]!)
        .where((w) => (w['start'] as DateTime).isAfter(now))
        .firstOrNull;
    if (upcoming == null) {
      return 'Salat is prohibited during these times · '
          'all have passed today.';
    }
    final start = upcoming['start'] as DateTime;
    final idx = _restrictedOrder.indexWhere(
      (k) => calc.getRestrictedTimes()[k]!['start'] == start,
    );
    final name = idx >= 0 ? _restrictedLabels[idx] : 'next';
    return 'Salat is prohibited during these times · '
        'next: $name ${_fmt12(start)}';
  }

  // ── Nafal times ─────────────────────────────────────────────────────────

  List<NafalRow> _nafalRows(
    SalahTimeCalculator calc,
    DateTime date,
    Map<String, DateTime> times,
  ) {
    final restricted = calc.getRestrictedTimes();
    final sunriseEnd = restricted['Sunrise Period']!['end'] as DateTime;
    final zawalStart = restricted['Zawal (Midday)']!['start'] as DateTime;
    final tomorrowFajr = _calculatorForDate(
      date.add(const Duration(days: 1)),
    ).getPrayerTimesMap()['Fajr']!;

    return [
      NafalRow(
        glyph: Icons.wb_sunny_outlined,
        name: 'Ishraq / Duha',
        range: '${_fmtBare(sunriseEnd)} – ${_fmt12(zawalStart)}',
      ),
      NafalRow(
        glyph: Icons.contrast_rounded,
        name: 'Zawal Start',
        range: _fmt12(zawalStart),
      ),
      NafalRow(
        glyph: Icons.cloud_outlined,
        name: 'Awabin',
        range: 'After Maghrib – ${_fmt12(times['Isha']!)}',
      ),
      NafalRow(
        glyph: Icons.nightlight_outlined,
        name: 'Tahajjud',
        range: 'After Isha – ${_fmt12(tomorrowFajr)}',
      ),
    ];
  }

  Widget _backToTodayButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () => _pageController.animateToPage(
          _todayPage,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(Icons.today_rounded, size: 16),
        label: const Text('Back to today'),
      ),
    );
  }

  // ── Focus + prayer math ─────────────────────────────────────────────────

  String? _currentPrayerName(Map<String, DateTime> times, DateTime now) {
    String? current;
    for (final p in const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final t = times[p];
      if (t != null && t.isBefore(now)) {
        current = p;
      } else {
        break;
      }
    }
    return current;
  }

  // ── Mosque/Waqt integration ─────────────────────────────────────────────

  DateTime? _mosqueTimeFor(
    String prayer,
    DateTime date,
    Map<String, DateTime> times,
  ) {
    // Ramadan mode: Fajr & Maghrib derive from Waqt + 15m.
    if (_ramadanMode && (prayer == 'Fajr' || prayer == 'Maghrib')) {
      final waqt = times[prayer];
      if (waqt != null) return waqt.add(const Duration(minutes: 15));
    }
    final tod = _mosqueTimes[prayer];
    if (tod == null) {
      // Show the customary default until the user sets their mosque's time,
      // so the list and the home-screen widget agree from first launch.
      final waqt = times[prayer];
      return waqt == null ? null : JamaatDefaults.forPrayer(prayer, waqt);
    }
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  /// True while a prayer is still showing the default rather than a time the
  /// user has confirmed — drives the hint in the edit sheet.
  bool _isJamaatDefault(String prayer) =>
      _mosqueTimes[prayer] == null &&
      !(_ramadanMode && (prayer == 'Fajr' || prayer == 'Maghrib'));

  /// Opens the restricted-times info as a centered modal dialog (was a
  /// bottom sheet — user prefers a dialog). Designed in the same Islamic
  /// palette so it sits naturally on top of the prayer page.
  void _openRestrictedSheet(SalahTimeCalculator calc) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Restricted Times',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                        color: IslamicColors.goldLight.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              20, 20, 20, 16,
                            ),
                            child: RestrictedTimesCard(calculator: calc),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: IslamicColors.emerald
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              minimumSize:
                                  const Size(double.infinity, 52),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(24),
                                ),
                              ),
                              foregroundColor: IslamicColors.emerald,
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        // Soft scale-fade entrance so the dialog feels considered.
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + 0.06 * anim.value,
            child: child,
          ),
        );
      },
    );
  }

  void _openMosqueEdit(String prayer, Map<String, DateTime> times) {
    final waqtDt = times[prayer];
    final waqt = waqtDt != null ? TimeOfDay.fromDateTime(waqtDt) : null;
    final lockedByRamadan = prayer == 'Fajr' || prayer == 'Maghrib';
    MosqueTimeEditSheet.show(
      context: context,
      prayer: prayer,
      currentMosqueTime: _mosqueTimes[prayer],
      waqtTime: waqt,
      isLockedByRamadan: lockedByRamadan,
      isDefault: _isJamaatDefault(prayer),
      onSaved: (time) async {
        await _settingsService.saveMosqueTime(
          prayer.toLowerCase(),
          '${time.hour}:${time.minute}',
        );
        if (!mounted) return;
        setState(() => _mosqueTimes[prayer] = time);
        HomeWidgetService().updateWidget();
      },
      onRamadanModeChanged: (v) async {
        await _settingsService.saveRamadanMode(v);
        if (!mounted) return;
        setState(() => _ramadanMode = v);
        HomeWidgetService().updateWidget();
      },
    );
  }

  // ── Prayer completion + alarms ──────────────────────────────────────────

  Future<void> _togglePrayed(DateTime date, String prayer) async {
    final on = await _completionService.toggle(date, prayer);
    await _loadDayState(date);
    if (!mounted) return;
    if (on) {
      PrayerSnack.show(context, '$prayer marked as prayed');
    }
  }

  QuickAlarmChoice? _quickChoiceFromConfig(PrayerAlarmConfig? c) {
    if (c == null || !c.isEnabled) return null;
    if (c.type != PrayerAlarmType.afterPrayerStart) return null;
    for (final choice in QuickAlarmChoice.values) {
      if (choice.minutesAfterStart == c.minutesAfterStart) return choice;
    }
    return null;
  }

  Future<void> _applyQuickAlarm(
    String prayer,
    QuickAlarmChoice choice, {
    bool announce = true,
  }) async {
    final existing = _alarms.where((a) => a.prayerName == prayer).isNotEmpty
        ? _alarms.firstWhere((a) => a.prayerName == prayer)
        : null;
    final sameAsActive = _quickChoiceFromConfig(existing) == choice;

    if (sameAsActive) {
      await _alarmService.removeAlarm(prayer);
      if (!mounted) return;
      PrayerSnack.show(
        context,
        '$prayer alarm turned off',
        kind: PrayerSnackKind.muted,
      );
      return;
    }

    final config = PrayerAlarmConfig(
      prayerName: prayer,
      type: PrayerAlarmType.afterPrayerStart,
      minutesAfterStart: choice.minutesAfterStart,
      isEnabled: true,
      soundPath: existing?.soundPath ??
          AlarmSoundUtils.availableAlarmSounds[0]['path']!,
      alarmDurationMinutes: existing?.alarmDurationMinutes ?? 2,
    );
    if (existing != null) {
      await _alarmService.updateAlarm(config);
    } else {
      await _alarmService.addAlarm(config);
    }
    if (!announce || !mounted) return;
    PrayerSnack.show(
      context,
      '$prayer · ${choice.label.toLowerCase()}',
      kind: PrayerSnackKind.scheduled,
    );
  }

  // ── Settings sheet ──────────────────────────────────────────────────────

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _settingsSheet(),
    );
  }

  Widget _settingsSheet() {
    // StatefulBuilder is needed because the modal sheet lives in its own
    // overlay route — calling setState on the page rebuilds the page (good
    // for the calculator-driven hero) but does NOT rebuild this sheet's
    // subtree. We use the sheet-local `setSheetState` to force the sheet
    // to re-read _selectedMethod / _selectedMadhab / location after each
    // dropdown change.
    return StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: IslamicColors.cream,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(
              color: IslamicColors.goldLight.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: IslamicColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Emerald header band — matches the dynamic-sky vibe and
              // gives the sheet a clear, branded top.
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      IslamicColors.emerald,
                      IslamicColors.emeraldMid,
                      IslamicColors.tealDeep,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: IslamicColors.emerald.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: IslamicColors.goldLight
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: IslamicColors.goldLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Prayer Settings',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Calculation · Madhab · Location',
                            style: TextStyle(
                              fontSize: 11,
                              color: IslamicColors.goldLight,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _sectionLabel(
                      'Calculation Method',
                      Icons.calculate_rounded,
                    ),
                    _methodDropdown(setSheetState),
                    const SizedBox(height: 20),
                    _sectionLabel(
                      'Madhab — for Asr',
                      Icons.menu_book_rounded,
                    ),
                    _madhabDropdown(setSheetState),
                    const SizedBox(height: 20),
                    _sectionLabel(
                      'Location',
                      Icons.place_rounded,
                    ),
                    _locationCard(setSheetState),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.edit_location_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Set Location Manually',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        await _showManualLocationDialog();
                        setSheetState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IslamicColors.emerald,
                        side: BorderSide(
                          color: IslamicColors.emerald.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        backgroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
      },
    );
  }

  Widget _sectionLabel(String s, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 0, 10),
        child: Row(
          children: [
            Icon(icon, size: 14, color: IslamicColors.emerald),
            const SizedBox(width: 6),
            Text(
              s.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: IslamicColors.emerald,
              ),
            ),
          ],
        ),
      );

  Widget _methodDropdown(StateSetter setSheetState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: IslamicColors.emerald.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CalculationMethod>(
          value: _selectedMethod,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: IslamicColors.emerald,
          ),
          dropdownColor: IslamicColors.cream,
          style: const TextStyle(
            color: Color(0xFF1B2A1F),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            CalculationMethod.karachi,
            CalculationMethod.muslim_world_league,
            CalculationMethod.egyptian,
            CalculationMethod.umm_al_qura,
            CalculationMethod.dubai,
            CalculationMethod.kuwait,
            CalculationMethod.qatar,
            CalculationMethod.singapore,
            CalculationMethod.turkey,
            CalculationMethod.tehran,
          ]
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m.displayName),
                  ))
              .toList(),
          onChanged: (v) async {
            if (v == null) return;
            // Page state rebuilds the calculator-driven hero; sheet state
            // rebuilds THIS sheet so the dropdown shows the new value.
            setState(() => _selectedMethod = v);
            setSheetState(() {});
            await _settingsService.saveCalculationMethod(v);
            _recomputeCalculator();
          },
        ),
      ),
    );
  }

  Widget _madhabDropdown(StateSetter setSheetState) {
    return Row(
      children: [
        Expanded(
          child: _madhabTile(
            label: 'Hanafi',
            sub: 'Later Asr',
            value: Madhab.hanafi,
            setSheetState: setSheetState,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _madhabTile(
            label: 'Shafi',
            sub: 'Earlier Asr',
            value: Madhab.shafi,
            setSheetState: setSheetState,
          ),
        ),
      ],
    );
  }

  Widget _madhabTile({
    required String label,
    required String sub,
    required Madhab value,
    required StateSetter setSheetState,
  }) {
    final selected = _selectedMadhab == value;
    return InkWell(
      onTap: () async {
        setState(() => _selectedMadhab = value);
        setSheetState(() {});
        await _settingsService.saveMadhab(value);
        _recomputeCalculator();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? IslamicColors.emerald : Colors.white,
          border: Border.all(
            color: selected
                ? IslamicColors.goldLight
                : IslamicColors.emerald.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: IslamicColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selected
                  ? IslamicColors.goldLight
                  : IslamicColors.emerald.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? Colors.white
                          : IslamicColors.emerald,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(StateSetter setSheetState) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IslamicColors.emerald.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLocationFromGps
                    ? const [
                        IslamicColors.emeraldMid,
                        IslamicColors.emeraldLight,
                      ]
                    : const [
                        IslamicColors.goldDeep,
                        IslamicColors.goldLight,
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isLocationFromGps
                  ? Icons.my_location_rounded
                  : Icons.place_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1B2A1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_latitude.toStringAsFixed(3)}°, '
                  '${_longitude.toStringAsFixed(3)}°  ·  '
                  '${_isLocationFromGps ? "GPS" : "Saved"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: IslamicColors.emerald.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            child: IconButton(
              tooltip: 'Refresh GPS',
              onPressed: _isLocationUpdating
                  ? null
                  : () async {
                      setSheetState(() {}); // show spinner immediately
                      await _refreshLocation();
                      setSheetState(() {}); // refresh card after GPS lookup
                    },
              icon: _isLocationUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: IslamicColors.emerald,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: IslamicColors.emerald,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualLocationDialog() async {
    final latC = TextEditingController(text: _latitude.toString());
    final lngC = TextEditingController(text: _longitude.toString());
    final nameC = TextEditingController(text: _locationName);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Location Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latC,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngC,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latC.text);
              final lng = double.tryParse(lngC.text);
              final name = nameC.text.trim();
              if (lat != null && lng != null && name.isNotEmpty) {
                Navigator.pop(context, {
                  'latitude': lat,
                  'longitude': lng,
                  'name': name,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _settingsService.saveLocation(
        latitude: result['latitude'],
        longitude: result['longitude'],
        locationName: result['name'],
        isFromGps: false,
      );
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationName = result['name'];
        _isLocationFromGps = false;
        _error = null;
      });
      _recomputeCalculator();
    }
  }
}

/// What the header gauge should display for the current moment.
class _GaugeData {
  final String name;
  final String label;
  final String countdown;
  final double progress;

  const _GaugeData({
    required this.name,
    required this.label,
    required this.countdown,
    required this.progress,
  });
}
