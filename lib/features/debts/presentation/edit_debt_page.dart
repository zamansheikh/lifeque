import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/local_clock.dart';
import '../../../core/utils/local_numbers.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../domain/debt.dart';
import 'debt_cubit.dart';
import 'debts_page.dart' show taka, showDebtPaymentSheet;

/// Add or edit one debt: which way the money went, with whom, how much, and
/// by when it should come back.
class EditDebtPage extends StatefulWidget {
  final String? id;
  const EditDebtPage({super.key, this.id});

  @override
  State<EditDebtPage> createState() => _EditDebtPageState();
}

class _EditDebtPageState extends State<EditDebtPage> {
  static const _brand = Color(0xFF0F766E);
  final _cubit = di.sl<DebtCubit>();
  final _formKey = GlobalKey<FormState>();
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  bool _theyOweMe = true;
  DateTime _date = DateTime.now();
  DateTime? _due;
  Debt? _existing;

  bool get _editing => widget.id != null;

  @override
  void initState() {
    super.initState();
    final d = widget.id == null
        ? null
        : _cubit.state.items.where((d) => d.id == widget.id).firstOrNull;
    if (d != null) {
      _existing = d;
      _person.text = d.person;
      _amount.text = d.amount == d.amount.roundToDouble()
          ? d.amount.toInt().toString()
          : d.amount.toStringAsFixed(2);
      _note.text = d.note ?? '';
      _theyOweMe = d.theyOweMe;
      _date = d.date;
      _due = d.dueDate;
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _parsed =>
      double.tryParse(N.ascii(_amount.text).replaceAll(',', '').trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    final base = _existing;
    final debt = Debt(
      id: base?.id ?? const Uuid().v4(),
      person: _person.text.trim(),
      amount: _parsed!,
      theyOweMe: _theyOweMe,
      date: _date,
      dueDate: _due,
      note: note.isEmpty ? null : note,
      payments: base?.payments ?? const [],
      settledAt: base?.settledAt,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    await _cubit.save(debt);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final d = _existing;
    if (d == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.debtDeleteTitle),
        content: Text(l.debtDeleteBody(d.person)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _cubit.delete(d.id);
    if (mounted) context.pop();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(DateTime.now().year + 10),
  );

  /// Everyone already in the list, for one-tap names.
  List<String> get _people {
    final seen = <String>{};
    return [
      for (final d in _cubit.state.items)
        if (seen.add(d.person)) d.person,
    ].take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = today.add(const Duration(days: 7));
    final month = DateTime(today.year, today.month + 1, today.day);
    bool same(DateTime? a, DateTime b) =>
        a != null && a.year == b.year && a.month == b.month && a.day == b.day;
    final existing = _existing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(_editing ? l.debtFormEdit : l.debtFormNew),
        actions: [
          if (_editing)
            IconButton(
              tooltip: l.commonDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
              ),
              onPressed: _delete,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: FilledButton.icon(
              key: const Key('debt-save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l.commonSave),
              style: FilledButton.styleFrom(backgroundColor: _brand),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.call_made_rounded),
                  label: Text(l.debtFormILent),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.call_received_rounded),
                  label: Text(l.debtFormIBorrowed),
                ),
              ],
              selected: {_theyOweMe},
              onSelectionChanged: (s) => setState(() => _theyOweMe = s.first),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
              child: Text(
                _theyOweMe ? l.debtFormLentHint : l.debtFormBorrowedHint,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            ),
            TextFormField(
              key: const Key('debt-person'),
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.debtFormPerson,
                prefixIcon: const Icon(Icons.person_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.debtFormPersonEmpty : null,
            ),
            if (!_editing && _people.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in _people)
                    ActionChip(
                      label: Text(p),
                      onPressed: () => setState(() => _person.text = p),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('debt-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.subFormAmount,
                prefixText: '৳ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (_) {
                final v = _parsed;
                return v == null || v <= 0 ? l.subFormAmountInvalid : null;
              },
            ),
            const SizedBox(height: 16),
            _label(l.debtFormDate),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.event_rounded, color: _brand),
              title: Text(DateFormat.yMMMMd().format(_date)),
              onTap: () async {
                final d = await _pick(_date);
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 16),
            _label(l.debtFormDue),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.debtDueNone),
                  selected: _due == null,
                  onSelected: (_) => setState(() => _due = null),
                ),
                ChoiceChip(
                  label: Text(l.debtDueWeek),
                  selected: same(_due, week),
                  onSelected: (_) => setState(() => _due = week),
                ),
                ChoiceChip(
                  label: Text(l.debtDueMonth),
                  selected: same(_due, month),
                  onSelected: (_) => setState(() => _due = month),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: Text(
                    _due != null && !same(_due, week) && !same(_due, month)
                        ? DateFormat.yMMMd().format(_due!)
                        : l.reminderFormPick,
                  ),
                  selected:
                      _due != null && !same(_due, week) && !same(_due, month),
                  onSelected: (_) async {
                    final d = await _pick(_due ?? week);
                    if (d != null) setState(() => _due = d);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: l.debtFormNote,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (existing != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _label(l.debtHistory)),
                  if (!existing.isSettled)
                    TextButton(
                      onPressed: () async {
                        await showDebtPaymentSheet(context, existing);
                        if (context.mounted) context.pop();
                      },
                      child: Text(
                        existing.theyOweMe ? l.debtGotBack : l.debtPaidBack,
                      ),
                    ),
                ],
              ),
              for (final p in existing.payments.reversed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF059669),
                  ),
                  title: Text(taka(p.amount)),
                  trailing: Text(
                    '${DateFormat.yMMMd().format(p.at)}, ${Clock.h12(p.at)}',
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  if (existing.isSettled) {
                    await _cubit.reopen(existing);
                  } else {
                    await _cubit.settle(existing);
                  }
                  if (context.mounted) context.pop();
                },
                child: Text(existing.isSettled ? l.debtReopen : l.debtSettle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      ),
    ),
  );
}
