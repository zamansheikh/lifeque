import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/home_widget/services/home_widget_service.dart';

import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/alarm_sound_utils.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../islamic_resources/presentation/pages/islamic_resources_page.dart'
    hide IslamicColors;
import '../../data/services/prayer_completion_service.dart';
import '../../data/services/prayer_settings_service.dart';
import '../utils/islamic_colors.dart';
import '../utils/sky_theme.dart';
import '../widgets/mosque_time_edit_sheet.dart';
import '../widgets/prayer_countdown_hero.dart';
import '../widgets/prayer_focus_card.dart';
import '../widgets/daily_progress_strip.dart';
import '../widgets/prayer_top_bar.dart';
import '../widgets/qibla_fab.dart';
import '../widgets/restricted_times_card.dart';
import '../widgets/sky_background.dart';
import '../widgets/smart_alerts_bar.dart';
import '../widgets/sunnah_times_card.dart';
import 'prayer_alarm_page.dart';

/// "Prayer Compass" — the redesigned prayer-times experience.
///
/// One single page (no tabs). The visual layout is:
///   ┌─────────────────────────────┐
///   │  SkyBackground (full bleed) │
///   │   ┌─────────────────────┐   │
///   │   │  PrayerTopBar       │   │
///   │   ├─────────────────────┤   │
///   │   │  Countdown + Arc    │   │
///   │   │   (focused prayer)  │   │
///   │   ├─────────────────────┤   │
///   │   │  PrayerFocusCard    │   │
///   │   │   (Waqt + Mosque)   │   │
///   │   ├─────────────────────┤   │
///   │   │  SmartAlertsBar     │   │
///   │   └─────────────────────┘   │
///   │             ╭───╮           │
///   │             │qib│           │
///   │             ╰───╯           │
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

  // Scaffold key — needed to open the drawer from anywhere inside the body
  // (Scaffold.of(context) doesn't work here because the State's context sits
  // ABOVE the Scaffold it just built).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Focus + interactive state ───────────────────────────────────────────
  /// Which prayer is shown in the focus card. By default the next upcoming
  /// one on TODAY pages, or Fajr on other-day pages.
  String? _focusedPrayer;
  bool _userPickedFocus = false;
  Timer? _tickTimer;

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
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _alarmsSub?.cancel();
    _pageController.dispose();
    super.dispose();
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
      return const Scaffold(
        backgroundColor: Color(0xFF0F1A40),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    if (_calculator == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1A40),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white70, size: 56),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Unable to compute prayer times',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadFromSavedData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Drive the entire-page gradient from the focused prayer on today's
    // current-window page; for other pages, from that page's "next" prayer.
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final tempCalc = _calculatorForDate(_selectedDate);
    final times = tempCalc.getPrayerTimesMap();
    final sky = isToday
        ? SkyTheme.forNow(now: now, times: times)
        : SkyTheme.forPrayer(_chooseFallbackFocus(times));

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(currentRoute: '/prayer-times'),
      drawerScrimColor: Colors.black.withValues(alpha: 0.4),
      backgroundColor: Colors.transparent,
      floatingActionButton: QiblaFab(calculator: _calculator),
      body: SkyBackground(
        theme: sky,
        child: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _selectedDate = _dateForPage(page);
                _userPickedFocus = false;
                _focusedPrayer = null;
              });
              _recomputeCalculator();
              _loadDayState(_selectedDate);
            },
            itemBuilder: (context, page) =>
                _buildDayContent(_dateForPage(page)),
          ),
        ),
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

  String _chooseFallbackFocus(Map<String, DateTime> times) {
    return 'Fajr';
  }

  // ── Day content ─────────────────────────────────────────────────────────

  Widget _buildDayContent(DateTime date) {
    final calc = _calculatorForDate(date);
    final times = calc.getPrayerTimesMap();
    final endTimes = calc.getEndTimes(calc.getStartTimes());
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);

    // Pick the focused prayer: user-tapped, else next upcoming, else Fajr.
    final autoFocus = _autoFocusFor(times, now, isToday);
    final focus = (_userPickedFocus ? _focusedPrayer : null) ?? autoFocus;

    // Pin the "next prayer" used by the countdown — if focus is the current
    // active window (i.e. focus was Tap'd while it's already started),
    // count down to the END of that window instead.
    final focusTime = _resolveFocusTime(focus, times, now, isToday, calc);

    // Mosque time for this prayer, derived from saved override or Ramadan mode.
    final mosqueTime = _mosqueTimeFor(focus, date, times);
    final isAutoFromRamadan =
        _ramadanMode && (focus == 'Fajr' || focus == 'Maghrib');

    // Makruh check for the alerts bar.
    final restricted = isToday ? calc.getCurrentRestrictedPeriod() : null;

    // Existing alarm for this prayer (drives the active chip).
    final alarmCfg = _alarms.where((a) => a.prayerName == focus).isNotEmpty
        ? _alarms.firstWhere((a) => a.prayerName == focus)
        : null;
    final activeChip = _quickChoiceFromConfig(alarmCfg);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          PrayerTopBar(
            locationName: _locationName,
            date: date,
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            onAlarms: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrayerAlarmPage(),
              ),
            ),
            onSettings: _showSettingsBottomSheet,
            onResources: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IslamicResourcesPage(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 90),
              child: Column(
                children: [
                  PrayerCountdownHero(
                    prayerNames: const [
                      'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha',
                    ],
                    times: times,
                    arcStart: times['Fajr']!,
                    arcEnd: _calculatorForDate(
                      date.add(const Duration(days: 1)),
                    ).getPrayerTimesMap()['Fajr']!,
                    now: now,
                    focusedPrayer: focus,
                    focusedPrayerTime: focusTime,
                    prevPrayerName: _prevPrayer(times, now, isToday),
                    currentPrayer: isToday
                        ? _currentPrayerName(times, now)
                        : null,
                    isToday: isToday,
                    onPrayerTapped: (name) {
                      setState(() {
                        _focusedPrayer = name;
                        _userPickedFocus = true;
                      });
                    },
                    restrictedPeriods: [
                      for (final entry
                          in calc.getRestrictedTimes().values)
                        {
                          'start': entry['start'] as DateTime,
                          'end': entry['end'] as DateTime,
                        },
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (isToday)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DailyProgressStrip(
                        prayed: _completions,
                        streak: _streak,
                      ),
                    ),
                  if (isToday) const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PrayerFocusCard(
                      prayer: focus,
                      waqtTime: times[focus]!,
                      mosqueTime: mosqueTime,
                      windowEnd: endTimes[focus],
                      isMosqueAutoFromRamadan: isAutoFromRamadan,
                      isCurrentPrayer: isToday &&
                          _currentPrayerName(times, now) == focus,
                      isPrayed: _completions.contains(focus),
                      canMarkPrayed: isToday || date.isBefore(now),
                      activeAlarm: activeChip,
                      onEditMosque: () => _openMosqueEdit(focus, times),
                      onTogglePrayed: () => _togglePrayed(date, focus),
                      onQuickAlarm: (c) => _applyQuickAlarm(focus, c),
                      onCustomAlarm: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrayerAlarmPage(),
                        ),
                      ),
                      restrictedWindows: [
                        for (final entry
                            in calc.getRestrictedTimes().entries)
                          RestrictedWindow(
                            name: entry.key,
                            start: entry.value['start'] as DateTime,
                            end: entry.value['end'] as DateTime,
                          ),
                      ]..sort((a, b) => a.start.compareTo(b.start)),
                      activeRestricted: isToday && restricted != null
                          ? RestrictedWindow(
                              name: restricted['name'] as String,
                              start: restricted['start'] as DateTime,
                              end: restricted['end'] as DateTime,
                              remaining:
                                  restricted['remaining'] as Duration,
                            )
                          : null,
                      onRestrictedTap: () => _openRestrictedSheet(calc),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SunnahTimesCard(calculator: calc),
                  ),
                  const SizedBox(height: 18),
                  if (!isToday) _backToTodayButton(),
                ],
              ),
            ),
          ),
          SmartAlertsBar(
            makruhName: restricted?['name'] as String?,
            makruhRemaining: restricted?['remaining'] as Duration?,
            streakDays: isToday ? _streak : 0,
            ramadanMode: _ramadanMode,
          ),
        ],
      ),
    );
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

  String _autoFocusFor(
    Map<String, DateTime> times,
    DateTime now,
    bool isToday,
  ) {
    if (!isToday) return 'Fajr';
    for (final p in const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final t = times[p];
      if (t != null && t.isAfter(now)) return p;
    }
    return 'Isha';
  }

  DateTime _resolveFocusTime(
    String focus,
    Map<String, DateTime> times,
    DateTime now,
    bool isToday,
    SalahTimeCalculator calc,
  ) {
    final t = times[focus];
    if (t == null) {
      return now.add(const Duration(hours: 1));
    }
    // For days other than today, just return the start time.
    if (!isToday) return t;

    // Today: if the focus is currently the running prayer (waqt has started,
    // window hasn't ended), aim the countdown at the NEXT prayer's start so
    // it acts as a "until the window closes" cue.
    if (_currentPrayerName(times, now) == focus && t.isBefore(now)) {
      final order = const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
      final idx = order.indexOf(focus);
      if (idx >= 0 && idx + 1 < order.length) {
        final next = times[order[idx + 1]];
        if (next != null) return next;
      }
      // Isha → tomorrow's Fajr
      if (focus == 'Isha') {
        final tomorrow = _calculatorForDate(
          _selectedDate.add(const Duration(days: 1)),
        );
        return tomorrow.getPrayerTimesMap()['Fajr']!;
      }
    }
    // If the focus is in the past, return TODAY's instance (not tomorrow's).
    // The hero renders this as "PASSED · was at X · Yh Zm ago" — a useless
    // 16-hour countdown to tomorrow's same prayer is much worse UX.
    return t;
  }

  String? _prevPrayer(
    Map<String, DateTime> times,
    DateTime now,
    bool isToday,
  ) {
    if (!isToday) return null;
    String? prev;
    for (final p in const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final t = times[p];
      if (t != null && t.isBefore(now)) prev = p;
    }
    return prev;
  }

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
    if (tod == null) return null;
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $prayer marked as prayed'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Future<void> _applyQuickAlarm(String prayer, QuickAlarmChoice choice) async {
    final existing = _alarms.where((a) => a.prayerName == prayer).isNotEmpty
        ? _alarms.firstWhere((a) => a.prayerName == prayer)
        : null;
    final sameAsActive = _quickChoiceFromConfig(existing) == choice;

    if (sameAsActive) {
      await _alarmService.removeAlarm(prayer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔕 $prayer alarm off'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ $prayer · ${choice.label.toLowerCase()}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded),
                    const SizedBox(width: 8),
                    const Text(
                      'Prayer Settings',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _sectionLabel('Calculation Method'),
                    _methodDropdown(),
                    const SizedBox(height: 20),
                    _sectionLabel('Madhab (Asr)'),
                    _madhabDropdown(),
                    const SizedBox(height: 20),
                    _sectionLabel('Location'),
                    _locationCard(),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_location_rounded),
                      label: const Text('Set Location Manually'),
                      onPressed: _showManualLocationDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
  }

  Widget _sectionLabel(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          s,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );

  Widget _methodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CalculationMethod>(
          value: _selectedMethod,
          isExpanded: true,
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
            setState(() => _selectedMethod = v);
            await _settingsService.saveCalculationMethod(v);
            _recomputeCalculator();
          },
        ),
      ),
    );
  }

  Widget _madhabDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Madhab>(
          value: _selectedMadhab,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: Madhab.hanafi,
              child: Text('Hanafi (Later Asr)'),
            ),
            DropdownMenuItem(
              value: Madhab.shafi,
              child: Text('Shafi (Earlier Asr)'),
            ),
          ],
          onChanged: (v) async {
            if (v == null) return;
            setState(() => _selectedMadhab = v);
            await _settingsService.saveMadhab(v);
            _recomputeCalculator();
          },
        ),
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isLocationFromGps
                ? Icons.my_location_rounded
                : Icons.place_rounded,
            color: _isLocationFromGps ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_latitude.toStringAsFixed(3)}°, '
                  '${_longitude.toStringAsFixed(3)}°',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh GPS',
            onPressed: _isLocationUpdating ? null : _refreshLocation,
            icon: _isLocationUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
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
