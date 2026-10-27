import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_numbers.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../domain/subscription.dart';
import 'subscription_cubit.dart';
import 'subscription_ui.dart';

/// Everything paid for on a schedule: what it costs a month, where the money
/// goes, and what renews next — each with a countdown and a progress bar
/// through its billing cycle, so a renewal is seen coming rather than
/// noticed on the bank statement.
class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  static const _ink = Color(0xFF1E293B);
  final _cubit = di.sl<SubscriptionCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const AppDrawer(currentRoute: '/subscriptions'),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(
            l.navSubscriptions,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: l.commonMenu,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('sub-add'),
          tooltip: l.subAdd,
          backgroundColor: const Color(0xFF4F46E5),
          onPressed: () => context.push('/subscriptions/add'),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
        body: BlocBuilder<SubscriptionCubit, SubscriptionsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.items.isEmpty) return const _EmptyState();
            return _List(items: state.items);
          },
        ),
      ),
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────

class _List extends StatelessWidget {
  final List<Subscription> items;
  const _List({required this.items});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final now = DateTime.now();
    final groups = groupSubscriptions(items, now);
    final sections = [
      (l.subGroupOverdue, groups[SubscriptionGroup.overdue]!),
      (l.subGroupWeek, groups[SubscriptionGroup.week]!),
      (l.subGroupMonth, groups[SubscriptionGroup.month]!),
      (l.subGroupLater, groups[SubscriptionGroup.later]!),
      (l.subGroupCancelled, groups[SubscriptionGroup.cancelled]!),
    ];

    return RefreshIndicator(
      onRefresh: () => context.read<SubscriptionCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _SummaryCard(items: items, now: now),
          const SizedBox(height: 12),
          _CategoryBar(items: items),
          for (final (label, list) in sections)
            if (list.isNotEmpty) ...[
              _SectionHeader(label: label, count: list.length),
              for (final s in list) _SubscriptionCard(sub: s, now: now),
            ],
        ],
      ),
    );
  }
}

enum SubscriptionGroup { overdue, week, month, later, cancelled }

/// Sections of the list: late first, then by how soon, cancelled last.
Map<SubscriptionGroup, List<Subscription>> groupSubscriptions(
  Iterable<Subscription> items,
  DateTime now,
) {
  final groups = {
    for (final g in SubscriptionGroup.values) g: <Subscription>[],
  };
  for (final s in items) {
    final days = s.daysUntil(now);
    final g = !s.isActive
        ? SubscriptionGroup.cancelled
        : days < 0
        ? SubscriptionGroup.overdue
        : days <= 7
        ? SubscriptionGroup.week
        : days <= 31
        ? SubscriptionGroup.month
        : SubscriptionGroup.later;
    groups[g]!.add(s);
  }
  for (final list in groups.values) {
    list.sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal));
  }
  return groups;
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            N.of(count),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
        ],
      ),
    );
  }
}

/// "৩ দিন বাকি" / "আজ নবায়ন" / "২ দিন পেরিয়েছে".
String renewalText(BuildContext context, Subscription s, DateTime now) {
  final l = L.of(context);
  final days = s.daysUntil(now);
  if (days < 0) return l.subDaysLate(-days);
  if (days == 0) return l.subToday;
  if (days == 1) return l.subTomorrow;
  return l.subDaysLeft(days);
}

// ── Summary ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<Subscription> items;
  final DateTime now;
  const _SummaryCard({required this.items, required this.now});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final active = items.where((s) => s.isActive).toList();
    final monthly = active.fold<double>(
      0,
      (sum, s) => sum + (s.monthlyCostLocal ?? 0),
    );
    // Billed in another currency and never paid here yet: no taka figure
    // to add, so they are listed beside the total instead.
    final unknown = <String, double>{};
    for (final s in active.where((s) => s.monthlyCostLocal == null)) {
      unknown[s.currency] = (unknown[s.currency] ?? 0) + s.monthlyCost;
    }
    final next = active.isEmpty
        ? null
        : (List.of(
            active,
          )..sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal))).first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.subMonthly,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // Totals are estimates (a yearly plan spread over months), so
            // whole taka: paisa would only be noise.
            formatMoney(monthly.roundToDouble(), 'BDT'),
            key: const Key('sub-monthly-total'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l.subYearly(formatMoney((monthly * 12).roundToDouble(), 'BDT'))} · '
            '${l.subActiveCount(active.length)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          if (unknown.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              l.subAlsoAbroad(
                unknown.entries
                    .map((e) => formatMoney(e.value, e.key))
                    .join(' + '),
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.subNext(next.name, renewalText(context, next, now)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Monthly cost split by category, as one stacked bar with a legend.
class _CategoryBar extends StatelessWidget {
  final List<Subscription> items;
  const _CategoryBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final byCategory = <SubscriptionCategory, double>{};
    for (final s in items.where((s) => s.isActive)) {
      final cost = s.monthlyCostLocal;
      if (cost == null || cost <= 0) continue;
      byCategory[s.category] = (byCategory[s.category] ?? 0) + cost;
    }
    if (byCategory.isEmpty) return const SizedBox.shrink();
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.subByCategory,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final e in entries)
                    Expanded(
                      flex: (e.value / total * 1000).round().clamp(1, 1000),
                      child: Container(color: e.key.color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final e in entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: e.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key.labelFor(context)} '
                      '${formatMoney(e.value.roundToDouble(), 'BDT')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  final DateTime now;
  const _SubscriptionCard({required this.sub, required this.now});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = sub.statusAt(now);
    final color = statusColor(status);
    final cancelled = status == RenewalStatus.cancelled;
    final showPay =
        status == RenewalStatus.overdue || status == RenewalStatus.dueSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: status == RenewalStatus.overdue
            ? Border.all(color: color.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('sub-card-${sub.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/subscriptions/edit/${sub.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Opacity(
              opacity: cancelled ? 0.55 : 1,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sub.category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          sub.category.icon,
                          color: sub.category.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    sub.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                if (sub.isTrial) ...[
                                  const SizedBox(width: 6),
                                  _badge(l.subTrial, const Color(0xFFD97706)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatMoney(sub.amount, sub.currency)} '
                              '${sub.cycle.perFor(context)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!cancelled)
                        _badge(renewalText(context, sub, now), color),
                    ],
                  ),
                  if (!cancelled) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sub.progressAt(now),
                        minHeight: 6,
                        color: color,
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            DateFormat.yMMMd().format(sub.nextRenewal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (showPay)
                          SizedBox(
                            height: 32,
                            child: FilledButton.icon(
                              key: Key('sub-pay-${sub.id}'),
                              onPressed: () => showPaySheet(context, sub),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: Text(l.subPaidButton),
                              style: FilledButton.styleFrom(
                                backgroundColor: color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

// ── Paying ────────────────────────────────────────────────────────────────

/// Confirms a renewal was paid: what it cost in taka (asked for when billed
/// in another currency), whether to record it as an expense, and when the
/// next one is.
Future<void> showPaySheet(BuildContext context, Subscription sub) async {
  final l = L.of(context);
  final cubit = context.read<SubscriptionCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final initial = sub.isLocalCurrency ? sub.amount : sub.lastPaidLocal;
  final controller = TextEditingController(
    text: initial == null
        ? ''
        : (initial == initial.roundToDouble()
              ? initial.toInt().toString()
              : initial.toStringAsFixed(2)),
  );
  var log = true;
  final next = Subscription.advance(sub.nextRenewal, sub.cycle, sub.anchorDay);

  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.subPayTitle(sub.name),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('sub-pay-amount'),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.subPayAmountLocal,
                prefixText: '৳ ',
                helperText: sub.isLocalCurrency
                    ? null
                    : l.subPayForeignHint(
                        formatMoney(sub.amount, sub.currency),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: log,
              onChanged: (v) => setState(() => log = v),
              title: Text(l.subPayLog),
            ),
            Text(
              l.subPayNext(DateFormat.yMMMd().format(next)),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('sub-pay-confirm'),
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l.subPayConfirm),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (done != true) return;

  final amount = double.tryParse(
    N.ascii(controller.text).replaceAll(',', '').trim(),
  );
  await cubit.markPaid(sub, amountLocal: amount, logExpense: log);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l.subPaidDone(sub.name))));
}

// ── Empty ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 100),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.autorenew_rounded,
              size: 44,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l.subEmptyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l.subEmptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.subFormPopular,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in subscriptionPresets.take(6))
              ActionChip(
                avatar: Icon(
                  p.category.icon,
                  size: 16,
                  color: p.category.color,
                ),
                label: Text(p.name),
                onPressed: () => context.push('/subscriptions/add', extra: p),
              ),
          ],
        ),
      ],
    );
  }
}
