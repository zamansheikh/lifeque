import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/local_clock.dart';
import '../../core/utils/local_numbers.dart';
import '../../l10n/app_localizations.dart';
import '../prayer_times/data/services/prayer_completion_service.dart';
import '../prayer_times/presentation/utils/prayer_l10n.dart';
import '../prayer_times/presentation/utils/prayer_palette.dart';
import 'qaza_store.dart';

/// Missed prayers and fasts, and making them up one at a time.
class QazaPage extends StatefulWidget {
  final QazaStore? store;
  const QazaPage({super.key, this.store});

  @override
  State<QazaPage> createState() => _QazaPageState();
}

class _QazaPageState extends State<QazaPage> {
  late final QazaStore _store = widget.store ?? QazaStore.instance;

  /// Unticked fard prayers since the last time they were added, at most the
  /// last 30 days. Null until worked out.
  Map<String, int>? _unticked;
  static const _historyKey = 'qaza_history_added_until';

  @override
  void initState() {
    super.initState();
    _store.load();
    _loadUnticked();
  }

  Future<void> _loadUnticked() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    var from = yesterday.subtract(const Duration(days: 29));
    final addedUntil = prefs.getString(_historyKey);
    if (addedUntil != null) {
      final after = DateTime.parse(addedUntil).add(const Duration(days: 1));
      if (after.isAfter(from)) from = after;
    }
    final counts = from.isAfter(yesterday)
        ? <String, int>{}
        : await PrayerCompletionService.instance.untickedBetween(
            from,
            yesterday,
          );
    if (mounted) setState(() => _unticked = counts);
  }

  Future<void> _addUnticked() async {
    final counts = _unticked;
    if (counts == null) return;
    await _store.addAll(counts);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(
      _historyKey,
      DateTime(now.year, now.month, now.day - 1).toIso8601String(),
    );
    if (mounted) setState(() => _unticked = {});
  }

  String _label(String what) {
    final l = L.of(context);
    return switch (what) {
      'Witr' => l.qazaWitr,
      QazaStore.fast => l.qazaFasts,
      _ => prayerLabel(context, what),
    };
  }

  Future<void> _makeUp(String what) async {
    HapticFeedback.lightImpact();
    if (!await _store.makeUp(what) || !mounted) return;
    final l = L.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.qazaMadeOne(_label(what))),
          action: SnackBarAction(label: l.qazaUndo, onPressed: _store.undo),
        ),
      );
  }

  Future<void> _addBulk() async {
    final l = L.of(context);
    final controller = TextEditingController();
    var unit = 0; // days, months, years
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.qazaAddBulkTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.qazaAddBulkBody),
              const SizedBox(height: 12),
              TextField(
                key: const Key('qaza-bulk-amount'),
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(l.qazaUnitDays)),
                  ButtonSegment(value: 1, label: Text(l.qazaUnitMonths)),
                  ButtonSegment(value: 2, label: Text(l.qazaUnitYears)),
                ],
                selected: {unit},
                onSelectionChanged: (s) => setState(() => unit = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(N.ascii(controller.text).trim());
                if (n == null || n <= 0) return;
                Navigator.pop(ctx, switch (unit) {
                  0 => n,
                  1 => n * 30,
                  _ => n * 365,
                });
              },
              child: Text(l.qazaAdd),
            ),
          ],
        ),
      ),
    );
    if (days != null) await _store.addDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: PrayerPalette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          l.qazaTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: PrayerPalette.ink,
          ),
        ),
        actions: [
          TextButton.icon(
            key: const Key('qaza-bulk'),
            onPressed: _addBulk,
            icon: const Icon(Icons.playlist_add_rounded),
            label: Text(l.qazaAddBulk),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_store.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final unticked = _unticked?.values.fold<int>(0, (s, n) => s + n);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _summary(),
              if (unticked != null && unticked > 0) ...[
                const SizedBox(height: 12),
                _historyCard(unticked),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l.qazaExplain,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: PrayerPalette.inkA(0.6),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final p in qazaPrayers) _row(p),
              const SizedBox(height: 6),
              _row(QazaStore.fast, fast: true),
              if (_store.log.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l.qazaHistory,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: PrayerPalette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                for (final e in _store.log.take(8))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle_rounded,
                      color: PrayerPalette.accent,
                      size: 20,
                    ),
                    title: Text(_label(e.what)),
                    trailing: Text(
                      '${DateFormat('d MMM').format(e.at)}, ${Clock.h12(e.at)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: PrayerPalette.inkA(0.55),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _summary() {
    final l = L.of(context);
    final owed = _store.prayersOwed;
    final made = _store.prayersMade;
    final total = owed + made;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [PrayerPalette.ramadanFrom, PrayerPalette.ramadanTo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            owed == 0 ? l.qazaNoneOwed : l.qazaOwedTotal(owed),
            key: const Key('qaza-owed'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${l.qazaMadeSoFar(made)} · ${l.qazaToday(_store.madeOn(DateTime.now()))}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: made / total,
                minHeight: 8,
                color: PrayerPalette.gold,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyCard(int count) {
    final l = L.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PrayerPalette.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFFB8901E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.qazaFromHistory(count),
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
          TextButton(
            key: const Key('qaza-from-history'),
            onPressed: _addUnticked,
            child: Text(l.qazaFromHistoryAdd),
          ),
        ],
      ),
    );
  }

  Widget _row(String what, {bool fast = false}) {
    final l = L.of(context);
    final owed = _store.owed[what]!;
    final made = _store.made[what]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: PrayerPalette.heroShadow,
      ),
      child: Row(
        children: [
          Icon(
            fast ? Icons.no_food_rounded : Icons.mosque_rounded,
            color: PrayerPalette.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(what),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: PrayerPalette.ink,
                  ),
                ),
                Text(
                  l.qazaMadeCount(made),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: PrayerPalette.inkA(0.5),
                  ),
                ),
              ],
            ),
          ),
          _small(
            Icons.remove_rounded,
            owed > 0 ? () => _store.addOwed(what, -1) : null,
            key: 'qaza-minus-$what',
          ),
          SizedBox(
            width: 44,
            child: Text(
              N.of(owed),
              key: Key('qaza-count-$what'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PrayerPalette.ink,
              ),
            ),
          ),
          _small(
            Icons.add_rounded,
            () => _store.addOwed(what, 1),
            key: 'qaza-plus-$what',
          ),
          const SizedBox(width: 6),
          FilledButton(
            key: Key('qaza-made-$what'),
            onPressed: owed > 0 ? () => _makeUp(what) : null,
            style: FilledButton.styleFrom(
              backgroundColor: PrayerPalette.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l.qazaMakeUp, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _small(IconData icon, VoidCallback? onTap, {required String key}) =>
      IconButton(
        key: Key(key),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(backgroundColor: PrayerPalette.inkA(0.05)),
      );
}
