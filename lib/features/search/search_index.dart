import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/local_numbers.dart';
import '../../injection_container.dart' as di;
import '../../l10n/app_localizations.dart';
import '../debts/data/debt_repository.dart';
import '../debts/presentation/debts_page.dart' show taka;
import '../expenses/data/datasources/expense_local_data_source.dart';
import '../habits/data/habit_repository.dart';
import '../habits/presentation/habit_ui.dart';
import '../medicines/data/datasources/medicine_local_data_source.dart';
import '../subscriptions/data/subscription_repository.dart';
import '../subscriptions/presentation/subscription_ui.dart';
import '../tasks/data/datasources/task_local_data_source.dart';
import '../tasks/domain/entities/task.dart';

/// Which part of the app a result comes from; also the order sections show.
enum SearchKind {
  page,
  task,
  birthday,
  habit,
  expense,
  subscription,
  debt,
  medicine,
}

/// One thing that can be found, and where tapping it goes.
class SearchHit {
  final SearchKind kind;
  final String title;
  final String? subtitle;

  /// Extra text that matches but isn't shown: a note, a description.
  final String hidden;
  final String route;
  final Object? extra;
  final IconData icon;
  final Color color;

  /// Newer first within a section.
  final DateTime? date;

  SearchHit({
    required this.kind,
    required this.title,
    this.subtitle,
    this.hidden = '',
    required this.route,
    this.extra,
    required this.icon,
    required this.color,
    this.date,
  });

  late final String _haystack = fold('$title ${subtitle ?? ''} $hidden');
  late final String _title = fold(title);
}

/// Lower case, Latin digits: "৫০০" finds "500" and the other way round.
String fold(String s) => N.ascii(s).toLowerCase();

/// Every word of [query] must appear somewhere. Titles that start with the
/// query come first, then titles that contain it, then the rest; newer
/// before older within each.
List<SearchHit> searchHits(List<SearchHit> all, String query) {
  final q = fold(query.trim());
  if (q.isEmpty) return const [];
  final words = q.split(RegExp(r'\s+'));
  final found = all
      .where((h) => words.every((w) => h._haystack.contains(w)))
      .toList();
  int rank(SearchHit h) => h._title.startsWith(q)
      ? 0
      : h._title.contains(q)
      ? 1
      : 2;
  found.sort((a, b) {
    final k = a.kind.index.compareTo(b.kind.index);
    if (k != 0) return k;
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final ad = a.date, bd = b.date;
    if (ad == null || bd == null) return 0;
    return bd.compareTo(ad);
  });
  return found;
}

/// The pages themselves, so "qaza" or "ramadan" leads straight there.
List<SearchHit> pageHits(L l) {
  SearchHit page(
    String title,
    String route,
    IconData icon, [
    String alt = '',
  ]) => SearchHit(
    kind: SearchKind.page,
    title: title,
    hidden: alt,
    route: route,
    icon: icon,
    color: const Color(0xFF475569),
  );
  return [
    page(l.navTasks, '/', Icons.task_alt_rounded, 'tasks todo reminders'),
    page(l.navBirthdays, '/birthdays', Icons.cake_rounded, 'birthdays'),
    page(
      l.navExpenses,
      '/expenses',
      Icons.account_balance_wallet_rounded,
      'expenses budget',
    ),
    page(
      l.navSubscriptions,
      '/subscriptions',
      Icons.autorenew_rounded,
      'subscriptions',
    ),
    page(l.navDebts, '/debts', Icons.handshake_rounded, 'debts lent borrowed'),
    page(l.navHabits, '/habits', Icons.local_fire_department_rounded, 'habits'),
    page(l.navMedicines, '/medicines', Icons.medication_rounded, 'medicines'),
    page(
      l.navPrayerTimes,
      '/prayer-times',
      Icons.mosque_rounded,
      'prayer namaz salah',
    ),
    page(l.qazaTitle, '/qaza', Icons.restore_rounded, 'qaza missed prayers'),
    page(
      l.ramadanTitle,
      '/ramadan',
      Icons.nightlight_round,
      'ramadan ramzan roza fasting',
    ),
    page(
      l.navStudyTimer,
      '/study-timer',
      Icons.timer_rounded,
      'study pomodoro timer',
    ),
    page(
      l.navSettings,
      '/settings',
      Icons.settings_rounded,
      'settings backup language',
    ),
  ];
}

/// Reads everything searchable once. A part that fails to load is left
/// out rather than failing the whole search.
Future<List<SearchHit>> buildSearchIndex(L l) async {
  final hits = <SearchHit>[...pageHits(l)];

  Future<void> part(String name, Future<void> Function() load) async {
    try {
      await load();
    } catch (e) {
      debugPrint('🔎 Could not index $name: $e');
    }
  }

  await Future.wait([
    part('tasks', () async {
      final tasks = await di.sl<TaskLocalDataSource>().getAllTasks();
      for (final t in tasks) {
        if (t.taskType == TaskType.birthday) {
          hits.add(
            SearchHit(
              kind: SearchKind.birthday,
              title: t.title,
              subtitle: l.searchBirthdayOn(
                DateFormat.MMMMd().format(t.endDate),
              ),
              hidden: t.description ?? '',
              route: '/edit-birthday/${t.id}',
              icon: Icons.cake_rounded,
              color: const Color(0xFFEC4899),
            ),
          );
        } else {
          hits.add(
            SearchHit(
              kind: SearchKind.task,
              title: t.title,
              subtitle: t.description?.trim().isEmpty ?? true
                  ? (t.hasDueDate ? DateFormat.yMMMd().format(t.endDate) : null)
                  : t.description!.trim().split('\n').first,
              hidden: t.description ?? '',
              route: '/task-detail/${t.id}',
              icon: t.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: t.isCompleted
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF4F46E5),
              date: t.endDate,
            ),
          );
        }
      }
    }),
    part('habits', () async {
      for (final h in await di.sl<HabitRepository>().all()) {
        hits.add(
          SearchHit(
            kind: SearchKind.habit,
            title: h.name,
            route: '/habits/view/${h.id}',
            icon: habitIcon(h.icon),
            color: habitColor(h.color),
          ),
        );
      }
    }),
    part('expenses', () async {
      final sessions = await di.sl<ExpenseLocalDataSource>().getAllSessions();
      for (final s in sessions) {
        final when = DateFormat.yMMMd().format(s.date);
        hits.add(
          SearchHit(
            kind: SearchKind.expense,
            title: s.title,
            subtitle: '${taka(s.totalAmount)} · $when',
            hidden: s.notes ?? '',
            route: '/expenses/detail',
            extra: s,
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF059669),
            date: s.date,
          ),
        );
        for (final item in s.items) {
          hits.add(
            SearchHit(
              kind: SearchKind.expense,
              title: item.name,
              subtitle: '${taka(item.amount)} · ${l.searchInSession(s.title)}',
              hidden: item.customCategoryName ?? '',
              route: '/expenses/detail',
              extra: s,
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF10B981),
              date: s.date,
            ),
          );
        }
      }
    }),
    part('subscriptions', () async {
      for (final s in await di.sl<SubscriptionRepository>().all()) {
        hits.add(
          SearchHit(
            kind: SearchKind.subscription,
            title: s.name,
            subtitle:
                '${formatMoney(s.amount, s.currency)} · ${DateFormat.yMMMd().format(s.nextRenewal)}',
            hidden: s.note ?? '',
            route: '/subscriptions/edit/${s.id}',
            icon: Icons.autorenew_rounded,
            color: const Color(0xFF7C3AED),
            date: s.nextRenewal,
          ),
        );
      }
    }),
    part('debts', () async {
      for (final d in await di.sl<DebtRepository>().all()) {
        hits.add(
          SearchHit(
            kind: SearchKind.debt,
            title: d.person,
            subtitle: d.isSettled
                ? '${taka(d.amount)} · ✓'
                : '${taka(d.remaining)} · ${d.theyOweMe ? l.debtFormILent : l.debtFormIBorrowed}',
            hidden: d.note ?? '',
            route: '/debts/edit/${d.id}',
            icon: d.theyOweMe
                ? Icons.call_made_rounded
                : Icons.call_received_rounded,
            color: const Color(0xFF0F766E),
            date: d.date,
          ),
        );
      }
    }),
    part('medicines', () async {
      final meds = await di.sl<MedicineLocalDataSource>().getAllMedicines();
      for (final m in meds) {
        final dose = m.dosage == m.dosage.roundToDouble()
            ? m.dosage.toInt().toString()
            : m.dosage.toString();
        hits.add(
          SearchHit(
            kind: SearchKind.medicine,
            title: m.name,
            subtitle: N.digits('$dose ${m.dosageUnit}'),
            hidden:
                '${m.description ?? ''} ${m.doctorName ?? ''} ${m.notes ?? ''}',
            route: '/edit-medicine/${m.id}',
            icon: Icons.medication_rounded,
            color: const Color(0xFFDC2626),
            date: m.startDate,
          ),
        );
      }
    }),
  ]);
  return hits;
}
