import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/local_numbers.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../domain/subscription.dart';
import 'subscription_cubit.dart';
import 'subscription_ui.dart';

/// Add or edit a subscription. Name and amount are all it needs; the next
/// renewal defaults to one billing cycle from today.
class EditSubscriptionPage extends StatefulWidget {
  final String? id;
  final SubscriptionPreset? preset;

  const EditSubscriptionPage({super.key, this.id, this.preset});

  @override
  State<EditSubscriptionPage> createState() => _EditSubscriptionPageState();
}

class _EditSubscriptionPageState extends State<EditSubscriptionPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _brand = Color(0xFF4F46E5);
  static const _field = Color(0xFFF8FAFC);

  final _cubit = di.sl<SubscriptionCubit>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  String _currency = 'BDT';
  BillingCycle _cycle = BillingCycle.monthly;
  late DateTime _next;
  bool _nextTouched = false;
  int _remind = 3;
  SubscriptionCategory _category = SubscriptionCategory.other;
  bool _trial = false;
  bool _active = true;
  Subscription? _existing;

  bool get _editing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _next = _oneCycleFromToday(_cycle);
    final existing = widget.id == null
        ? null
        : _cubit.state.items.where((s) => s.id == widget.id).firstOrNull;
    if (existing != null) {
      _existing = existing;
      _name.text = existing.name;
      _amount.text = _plain(existing.amount);
      _note.text = existing.note ?? '';
      _currency = existing.currency;
      _cycle = existing.cycle;
      _next = existing.nextRenewal;
      _nextTouched = true;
      _remind = existing.remindDaysBefore;
      _category = existing.category;
      _trial = existing.isTrial;
      _active = existing.isActive;
    } else if (widget.preset != null) {
      _applyPreset(widget.preset!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static DateTime _oneCycleFromToday(BillingCycle cycle) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Subscription.advance(today, cycle, today.day);
  }

  void _applyPreset(SubscriptionPreset p) {
    setState(() {
      _name.text = p.name;
      _category = p.category;
      _currency = p.currency;
    });
  }

  double? get _parsedAmount =>
      double.tryParse(N.ascii(_amount.text).replaceAll(',', '').trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    final now = DateTime.now();
    final sub = Subscription(
      id: _existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      amount: _parsedAmount!,
      currency: _currency,
      cycle: _cycle,
      nextRenewal: DateTime(_next.year, _next.month, _next.day),
      billingDay: _next.day,
      remindDaysBefore: _remind,
      category: _category,
      isTrial: _trial,
      isActive: _active,
      note: note.isEmpty ? null : note,
      lastPaidAt: _existing?.lastPaidAt,
      lastPaidLocal: _existing?.lastPaidLocal,
      createdAt: _existing?.createdAt ?? now,
    );
    await _cubit.save(sub);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final existing = _existing;
    if (existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.subDeleteTitle),
        content: Text(l.subDeleteBody(existing.name)),
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
    await _cubit.delete(existing.id);
    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _next,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: L.of(context).subFormNextRenewal,
    );
    if (picked == null) return;
    setState(() {
      _next = picked;
      _nextTouched = true;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: _field,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          _editing ? l.subFormEdit : l.subFormNew,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
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
              key: const Key('sub-save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l.commonSave),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (!_editing) ...[_presets(), const SizedBox(height: 12)],
            _card(
              children: [
                TextFormField(
                  key: const Key('sub-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                  decoration: InputDecoration(
                    hintText: l.subFormName,
                    border: InputBorder.none,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l.subFormNameEmpty : null,
                ),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('sub-amount'),
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l.subFormAmount,
                          prefixText: '${subscriptionCurrencies[_currency]} ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (_) {
                          final v = _parsedAmount;
                          return v == null || v <= 0
                              ? l.subFormAmountInvalid
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _currencyPicker(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              title: l.subFormCycle,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in BillingCycle.values)
                      _chip(
                        c.labelFor(context),
                        selected: _cycle == c,
                        onTap: () => setState(() {
                          _cycle = c;
                          if (!_nextTouched) _next = _oneCycleFromToday(c);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l.subFormNextRenewal,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: _brand.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            color: _brand,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat.yMMMMEEEEd().format(_next),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.edit_calendar_rounded,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              title: l.subFormRemind,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in const [0, 1, 3, 7])
                      _chip(
                        d == 0 ? l.subRemindSameDay : l.subRemindDays(d),
                        selected: _remind == d,
                        onTap: () => setState(() => _remind = d),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _trial,
                  activeTrackColor: const Color(0xFFD97706),
                  onChanged: (v) => setState(() => _trial = v),
                  title: Text(
                    l.subFormTrial,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(l.subFormTrialBody),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              title: l.subFormCategory,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in SubscriptionCategory.values)
                      _chip(
                        c.labelFor(context),
                        icon: c.icon,
                        color: c.color,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              children: [
                TextField(
                  controller: _note,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l.subFormNote,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              _card(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: !_active,
                    onChanged: (v) => setState(() => _active = !v),
                    title: Text(
                      l.subFormCancelled,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(l.subFormCancelledBody),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _presets() {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l.subFormPopular,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subscriptionPresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = subscriptionPresets[i];
              return ActionChip(
                avatar: Icon(
                  p.category.icon,
                  size: 16,
                  color: p.category.color,
                ),
                label: Text(p.name),
                backgroundColor: Colors.white,
                onPressed: () => _applyPreset(p),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _currencyPicker() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('sub-currency'),
          value: _currency,
          items: [
            for (final e in subscriptionCurrencies.entries)
              DropdownMenuItem(
                value: e.key,
                child: Text('${e.value} ${e.key}'),
              ),
          ],
          onChanged: (v) => setState(() => _currency = v ?? _currency),
        ),
      ),
    );
  }

  Widget _card({String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color color = _brand,
  }) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
