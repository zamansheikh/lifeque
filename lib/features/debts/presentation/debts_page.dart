import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_numbers.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../../subscriptions/presentation/subscription_ui.dart' show formatMoney;
import '../domain/debt.dart';
import 'debt_cubit.dart';

const _receive = Color(0xFF059669);
const _pay = Color(0xFFDC2626);

String taka(double v) =>
    formatMoney(v == v.roundToDouble() ? v : (v * 100).round() / 100, 'BDT');

/// Money lent and borrowed: what is due back, what is due out, and from
/// whom — each with how much has come back and when the rest is due.
class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage>
    with SingleTickerProviderStateMixin {
  final _cubit = di.sl<DebtCubit>();
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _cubit.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const AppDrawer(currentRoute: '/debts'),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(
            l.navDebts,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: l.commonMenu,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('debt-add'),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          onPressed: () => context.push('/debts/add'),
          icon: const Icon(Icons.add_rounded),
          label: Text(l.debtAdd),
        ),
        body: BlocBuilder<DebtCubit, DebtsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.items.isEmpty) return const _Empty();
            final now = DateTime.now();
            List<Debt> open(bool theyOweMe) =>
                state.items
                    .where((d) => d.theyOweMe == theyOweMe && !d.isSettled)
                    .toList()
                  ..sort(_byUrgency);
            final settled = state.items.where((d) => d.isSettled).toList();
            final receive = open(true), pay = open(false);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _Summary(state: state),
                ),
                TabBar(
                  controller: _tabs,
                  labelColor: const Color(0xFF0F766E),
                  indicatorColor: const Color(0xFF0F766E),
                  tabs: [
                    Tab(text: '${l.debtToReceive} ${N.of(receive.length)}'),
                    Tab(text: '${l.debtToPay} ${N.of(pay.length)}'),
                    Tab(text: l.debtTabSettled),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _list(receive, now),
                      _list(pay, now),
                      _list(settled, now),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Late first, then by due date, then undated — newest first.
  static int _byUrgency(Debt a, Debt b) {
    final da = a.dueDate, db = b.dueDate;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return b.date.compareTo(a.date);
  }

  Widget _list(List<Debt> items, DateTime now) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
    children: [for (final d in items) _DebtCard(debt: d, now: now)],
  );
}

class _Summary extends StatelessWidget {
  final DebtsState state;
  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final net = state.toReceive - state.toPay;
    Widget half(String label, double v, Color c, String key) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                taka(v),
                key: Key(key),
                style: TextStyle(
                  color: c,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            half(l.debtToReceive, state.toReceive, _receive, 'debt-receive'),
            const SizedBox(width: 10),
            half(l.debtToPay, state.toPay, _pay, 'debt-pay'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          net.abs() < 0.005
              ? l.debtNetEven
              : net > 0
              ? l.debtNetReceive(taka(net))
              : l.debtNetPay(taka(-net)),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

String debtDueText(BuildContext context, Debt d, DateTime now) {
  final l = L.of(context);
  final days = d.daysUntilDue(now);
  if (days == null) return '';
  if (days < 0) return l.debtOverdue(-days);
  if (days == 0) return l.debtDueToday;
  return l.debtDueIn(days);
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final DateTime now;
  const _DebtCard({required this.debt, required this.now});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = debt.theyOweMe ? _receive : _pay;
    final status = debt.statusAt(now);
    final dueColor = switch (status) {
      DebtStatus.overdue => _pay,
      DebtStatus.dueSoon => const Color(0xFFD97706),
      _ => Colors.grey.shade600,
    };
    final settled = status == DebtStatus.settled;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: status == DebtStatus.overdue
            ? BorderSide(color: _pay.withValues(alpha: 0.4))
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        key: Key('debt-card-${debt.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/debts/edit/${debt.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: c.withValues(alpha: 0.12),
                    child: Text(
                      debt.person.characters.first.toUpperCase(),
                      style: TextStyle(color: c, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.person,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          (debt.note?.isNotEmpty ?? false)
                              ? debt.note!
                              : DateFormat.yMMMd().format(debt.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        taka(settled ? debt.amount : debt.remaining),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: settled ? Colors.grey : c,
                        ),
                      ),
                      if (!settled && debt.paid > 0)
                        Text(
                          l.debtRemainingOf(
                            taka(debt.remaining),
                            taka(debt.amount),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (!settled) ...[
                if (debt.paid > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: debt.progress,
                      minHeight: 6,
                      color: c,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (debt.dueDate != null) ...[
                      Icon(Icons.event_rounded, size: 14, color: dueColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          debtDueText(context, debt, now),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: dueColor,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        key: Key('debt-pay-${debt.id}'),
                        onPressed: () => showDebtPaymentSheet(context, debt),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c,
                          side: BorderSide(color: c.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          debt.theyOweMe ? l.debtGotBack : l.debtPaidBack,
                          style: const TextStyle(fontSize: 12.5),
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
    );
  }
}

/// How much came back (or went back). Prefilled with the rest; "all of it"
/// settles the debt.
Future<void> showDebtPaymentSheet(BuildContext context, Debt debt) async {
  final l = L.of(context);
  final cubit = di.sl<DebtCubit>();
  String plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  final controller = TextEditingController(text: plain(debt.remaining));
  final amount = await showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            debt.theyOweMe
                ? l.debtPayTitleGot(debt.person)
                : l.debtPayTitlePaid(debt.person),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l.debtRemainingOf(taka(debt.remaining), taka(debt.amount)),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('debt-pay-amount'),
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '৳ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffix: TextButton(
                onPressed: () => controller.text = plain(debt.remaining),
                child: Text(l.debtPayAll),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('debt-pay-confirm'),
              onPressed: () {
                final v = double.tryParse(
                  N.ascii(controller.text).replaceAll(',', '').trim(),
                );
                if (v == null || v <= 0) return;
                Navigator.pop(ctx, v > debt.remaining ? debt.remaining : v);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l.commonSave),
            ),
          ),
        ],
      ),
    ),
  );
  if (amount != null) await cubit.addPayment(debt, amount);
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.handshake_rounded,
                size: 44,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.debtEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l.debtEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
