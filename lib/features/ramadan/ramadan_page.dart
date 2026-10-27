import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/utils/local_clock.dart';
import '../../core/utils/local_numbers.dart';
import '../../core/utils/salah_time_calculator.dart';
import '../../l10n/app_localizations.dart';
import '../prayer_times/data/services/prayer_settings_service.dart';
import 'ramadan_store.dart';
import '../../core/utils/hijri_date.dart';

const _night = Color(0xFF312E81);
const _gold = Color(0xFFF59E0B);

/// Which Ramadan the log opens on: the running one, else the last one.
int defaultRamadanYear(DateTime now) {
  final h = HijriDate.of(now);
  return h.hMonth >= 9 ? h.hYear : h.hYear - 1;
}

/// Sehri and iftar today, a log of every fast and taraweeh night, and the
/// duas for both ends of the day.
class RamadanPage extends StatefulWidget {
  /// For tests: the store to use, and a fixed clock.
  final RamadanStore? store;
  final DateTime Function()? clock;
  const RamadanPage({super.key, this.store, this.clock});

  @override
  State<RamadanPage> createState() => _RamadanPageState();
}

class _RamadanPageState extends State<RamadanPage> {
  late final RamadanStore _store = widget.store ?? RamadanStore.instance;
  DateTime _now() => (widget.clock ?? DateTime.now)();

  late int _year = defaultRamadanYear(_now());
  Map<String, DateTime>? _today, _tomorrow;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _store.addListener(_changed);
    if (!_store.loaded) _store.load();
    _loadTimes();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _store.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTimes() async {
    try {
      final settings = PrayerSettingsService.instance;
      await settings.init();
      final loc = await settings.getSavedLocation();
      if (loc == null) return;
      final method = await settings.getCalculationMethod();
      final madhab = await settings.getMadhab();
      Map<String, DateTime> on(DateTime d) {
        final c = SalahTimeCalculator(
          latitude: loc.latitude,
          longitude: loc.longitude,
          date: d,
          method: method,
          madhab: madhab,
        );
        return {...c.getPrayerTimesMap(), 'Sahri': c.getSahriEnd()};
      }

      final now = _now();
      final today = on(now);
      final tomorrow = on(DateTime(now.year, now.month, now.day + 1));
      if (!mounted) return;
      setState(() {
        _today = today;
        _tomorrow = tomorrow;
      });
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
    } catch (e) {
      debugPrint('🌙 Could not work out sehri and iftar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final now = _now();
    final last = defaultRamadanYear(now);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(l.ramadanTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Header(now: now, today: _today, tomorrow: _tomorrow),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.ramadanFastLog,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const Key('ramadan-prev'),
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                l.ramadanYear(N.plain(_year)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                key: const Key('ramadan-next'),
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _year < last ? () => setState(() => _year++) : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _Totals(store: _store, year: _year),
          const SizedBox(height: 12),
          _DayGrid(store: _store, year: _year, now: now),
          const SizedBox(height: 10),
          _Legend(),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/qaza'),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.ramadanQazaNote,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.ramadanDuas,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _Dua(
            title: l.ramadanNiyyah,
            arabic: 'وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ',
            latin: 'Wa bisawmi ghadin nawaitu min shahri Ramadan',
            meaning: l.ramadanNiyyahMeaning,
          ),
          _Dua(
            title: l.ramadanIftarDua,
            arabic:
                'اللَّهُمَّ لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَىٰ رِزْقِكَ أَفْطَرْتُ',
            latin:
                "Allahumma laka sumtu wa bika amantu wa 'alayka tawakkaltu wa 'ala rizqika aftartu",
            meaning: l.ramadanIftarMeaning,
          ),
          _Dua(
            title: l.ramadanAfterIftar,
            arabic:
                'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
            latin:
                "Dhahaba-z-zama'u wabtallatil-'urooqu wa thabatal-ajru in sha' Allah",
            meaning: l.ramadanAfterIftarMeaning,
          ),
          const SizedBox(height: 12),
          Text(
            l.ramadanEstimate,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Today: where Ramadan stands, sehri and iftar, and a countdown to
/// whichever comes next.
class _Header extends StatelessWidget {
  final DateTime now;
  final Map<String, DateTime>? today, tomorrow;
  const _Header({required this.now, this.today, this.tomorrow});

  static String _hms(Duration d) {
    final s = d.inSeconds.clamp(0, 86400 * 2);
    return '${N.of(s ~/ 3600)}:${N.padded2(s % 3600 ~/ 60)}:${N.padded2(s % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final h = HijriDate.of(now);
    final String status;
    if (h.hMonth == 9) {
      status = l.ramadanToday(N.plain(h.hYear), h.hDay);
    } else {
      final next = h.hMonth < 9 ? h.hYear : h.hYear + 1;
      final first = ramadanDays(next).first;
      final days = first
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      status = l.ramadanStartsIn(N.plain(next), days);
    }

    final t = today;
    String? countdown;
    if (t != null) {
      final fajr = t['Sahri']!, maghrib = t['Maghrib']!;
      if (now.isBefore(fajr)) {
        countdown = l.ramadanUntilSehri(_hms(fajr.difference(now)));
      } else if (now.isBefore(maghrib)) {
        countdown = l.ramadanUntilIftar(_hms(maghrib.difference(now)));
      } else if (tomorrow != null) {
        countdown = l.ramadanUntilSehri(
          _hms(tomorrow!['Sahri']!.difference(now)),
        );
      }
    }

    Widget time(String label, DateTime? at, IconData icon) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      at == null ? '—' : Clock.h12(at),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), _night, Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: _gold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  key: const Key('ramadan-status'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (t == null)
            Text(
              l.ramadanNoLocation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            )
          else ...[
            Row(
              children: [
                time(l.ramadanSahriEnds, t['Sahri'], Icons.dark_mode_rounded),
                const SizedBox(width: 10),
                time(l.ramadanIftar, t['Maghrib'], Icons.wb_twilight_rounded),
              ],
            ),
            if (countdown != null) ...[
              const SizedBox(height: 12),
              Text(
                countdown,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final RamadanStore store;
  final int year;
  const _Totals({required this.store, required this.year});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    Widget tile(String label, int n, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              N.of(n),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile(
          l.ramadanFasted,
          store.count(year, FastStatus.fasted),
          _statusColor(FastStatus.fasted),
        ),
        const SizedBox(width: 8),
        tile(
          l.ramadanMissed,
          store.count(year, FastStatus.missed),
          _statusColor(FastStatus.missed),
        ),
        const SizedBox(width: 8),
        tile(
          l.ramadanExcused,
          store.count(year, FastStatus.excused),
          _statusColor(FastStatus.excused),
        ),
        const SizedBox(width: 8),
        tile(l.ramadanTaraweeh, store.taraweehCount(year), _night),
      ],
    );
  }
}

Color _statusColor(FastStatus s) => switch (s) {
  FastStatus.fasted => const Color(0xFF059669),
  FastStatus.missed => const Color(0xFFDC2626),
  FastStatus.excused => const Color(0xFFD97706),
};

String _statusLabel(L l, FastStatus s) => switch (s) {
  FastStatus.fasted => l.ramadanFasted,
  FastStatus.missed => l.ramadanMissed,
  FastStatus.excused => l.ramadanExcused,
};

/// Thirty days, six to a row. Days still to come can't be marked yet.
class _DayGrid extends StatelessWidget {
  final RamadanStore store;
  final int year;
  final DateTime now;
  const _DayGrid({required this.store, required this.year, required this.now});

  @override
  Widget build(BuildContext context) {
    final days = ramadanDays(year);
    final today = DateTime(now.year, now.month, now.day);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) {
        final day = i + 1;
        final date = days[i];
        final future = date.isAfter(today);
        final status = store.fastOn(year, day);
        final taraweeh = store.taraweehOn(year, day);
        final oddLastTen = day > 20 && day.isOdd;
        final c = status == null ? null : _statusColor(status);
        return Material(
          color: c?.withValues(alpha: 0.14) ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: Key('ramadan-day-$day'),
            borderRadius: BorderRadius.circular(12),
            onTap: future
                ? null
                : () => _showDaySheet(context, store, year, day, date),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: date == today
                      ? _night
                      : oddLastTen
                      ? _gold.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: date == today ? 2 : 1,
                ),
              ),
              child: Opacity(
                opacity: future ? 0.4 : 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      N.of(day),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c ?? const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(date),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (status != null)
                            Icon(
                              status == FastStatus.fasted
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              size: 12,
                              color: c,
                            ),
                          if (taraweeh)
                            const Icon(
                              Icons.nightlight_round,
                              size: 11,
                              color: _night,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _gold.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l.ramadanLastTen,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

Future<void> _showDaySheet(
  BuildContext context,
  RamadanStore store,
  int year,
  int day,
  DateTime date,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (ctx) => ListenableBuilder(
    listenable: store,
    builder: (ctx, _) {
      final l = L.of(ctx);
      final status = store.fastOn(year, day);
      Widget option(FastStatus s, IconData icon, [String? hint]) => ListTile(
        key: Key('ramadan-mark-${s.name}'),
        leading: Icon(icon, color: _statusColor(s)),
        title: Text(_statusLabel(l, s)),
        subtitle: hint == null ? null : Text(hint),
        trailing: status == s
            ? Icon(Icons.check_circle_rounded, color: _statusColor(s))
            : null,
        onTap: () async {
          await store.setFast(year, day, s);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      );
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '${l.ramadanDayN(day)} · ${DateFormat.yMMMEd().format(date)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              option(FastStatus.fasted, Icons.check_circle_outline_rounded),
              option(FastStatus.missed, Icons.cancel_outlined),
              option(
                FastStatus.excused,
                Icons.healing_rounded,
                l.ramadanExcusedHint,
              ),
              const Divider(),
              SwitchListTile(
                key: const Key('ramadan-taraweeh'),
                secondary: const Icon(Icons.nightlight_round, color: _night),
                title: Text(l.ramadanTaraweehPrayed),
                value: store.taraweehOn(year, day),
                onChanged: (v) => store.setTaraweeh(year, day, v),
              ),
              if (status != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextButton(
                    onPressed: () async {
                      await store.setFast(year, day, null);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l.ramadanClear),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  ),
);

class _Dua extends StatelessWidget {
  final String title, arabic, latin, meaning;
  const _Dua({
    required this.title,
    required this.arabic,
    required this.latin,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.menu_book_rounded, color: _night),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          arabic,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 22, height: 1.8),
        ),
        const SizedBox(height: 8),
        Text(
          latin,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Text(meaning, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}
