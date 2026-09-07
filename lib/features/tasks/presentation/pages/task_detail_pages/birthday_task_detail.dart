import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/local_numbers.dart';
import '../../../../../core/widgets/detail_kit.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';
import '../../widgets/birthday_wish/birthday_wish_log.dart';
import '../../widgets/birthday_wish/birthday_wish_sheet.dart';

/// A birthday's detail view: how old they are, when the next one lands, and
/// which reminders are set for it.
class BirthdayTaskDetail extends StatefulWidget {
  final Task task;

  const BirthdayTaskDetail({super.key, required this.task});

  @override
  State<BirthdayTaskDetail> createState() => _BirthdayTaskDetailState();
}

class _BirthdayTaskDetailState extends State<BirthdayTaskDetail> {
  Timer? _ticker;

  Task get _task => widget.task;

  /// The date of birth. Birthdays store it in `endDate`.
  DateTime get _birth => _task.endDate;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
    BirthdayWishLog.instance
      ..addListener(_onWishLog)
      ..load();
  }

  @override
  void dispose() {
    BirthdayWishLog.instance.removeListener(_onWishLog);
    _ticker?.cancel();
    super.dispose();
  }

  void _onWishLog() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFDB2777);
    final l = L.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // nextOccurrence compares by date, so the birthday reads as "today" on the
    // day itself rather than jumping a year ahead at midnight.
    final next = _task.nextOccurrence;
    final daysUntil = next.difference(today).inDays;
    final isToday = daysUntil == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailHero(
          icon: isToday ? Icons.celebration_rounded : Icons.cake_rounded,
          accent: accent,
          status: _status(context, daysUntil),
          title: _task.title,
          subtitle:
              '${DateFormat('EEEE, d MMMM').format(next)} · '
              '${l.birthdaysTurning(next.year - _birth.year)}',
          description: _task.description,
          isDone: _task.isCompleted,
          action: DetailCheckCircle(
            checked: _task.isCompleted,
            accent: accent,
            onTap: () =>
                context.read<TaskBloc>().add(ToggleTaskCompletion(_task.id)),
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: isToday ? l.detailSectionToday : l.detailSectionCountdown,
          icon: Icons.hourglass_bottom_rounded,
          accent: accent,
          children: [
            if (isToday)
              Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.birthdaysTodayLine(next.year - _birth.year),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              )
            else
              DetailCountdown(
                remaining: next.difference(now),
                color: accent,
                caption: l.birthdaysUntilBigDay,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DetailStat(
                    value: '${_ageOn(today)}',
                    label: l.birthdaysYearsOldNow,
                    icon: Icons.person_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetailStat(
                    value: isToday ? l.commonToday : N.of(daysUntil),
                    label: isToday ? l.birthdaysTheBigDay : l.birthdaysDaysToGo,
                    icon: Icons.event_rounded,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _wishSection(context, accent),
        const SizedBox(height: 12),
        DetailSection(
          title: l.detailSectionReminders,
          icon: Icons.notifications_active_rounded,
          accent: const Color(0xFF7C3AED),
          children: [
            if (_task.birthdayNotificationSchedule.isEmpty)
              Text(
                l.birthdaysNoReminders,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              )
            else
              for (final option in _task.birthdayNotificationSchedule)
                DetailRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: _optionTitle(option),
                  value: _optionBody(option),
                ),
          ],
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: l.detailSectionDetails,
          icon: Icons.info_outline_rounded,
          accent: Colors.grey.shade500,
          children: [
            DetailRow(
              icon: Icons.cake_rounded,
              label: l.birthdaysBorn,
              value: DateFormat('d MMMM y').format(_birth),
            ),
            DetailRow(
              icon: Icons.event_repeat_rounded,
              label: l.birthdaysNext,
              value: DateFormat('EEE, d MMM y').format(next),
            ),
            DetailRow(
              icon: Icons.add_circle_outline_rounded,
              label: l.birthdaysSaved,
              value: DateFormat('d MMM y').format(_task.createdAt),
            ),
            if (_task.updatedAt != null)
              DetailRow(
                icon: Icons.edit_rounded,
                label: l.detailLastEdited,
                value: DateFormat('d MMM y').format(_task.updatedAt!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _wishSection(BuildContext context, Color accent) {
    final l = L.of(context);
    final wished = BirthdayWishLog.instance.wishedThisYear(_task.id);
    return DetailSection(
      title: l.wishSectionTitle,
      icon: Icons.card_giftcard_rounded,
      accent: accent,
      children: [
        Text(
          l.wishSectionBody,
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => BirthdayWishSheet.show(context, _task),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                label: Text(
                  l.wishSendWishes,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        if (wished) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 6),
              Text(
                l.wishWishedThisYear,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Whole years old on [date] — decremented when this year's birthday is
  /// still ahead, which a plain year subtraction gets wrong for half the year.
  int _ageOn(DateTime date) {
    var age = date.year - _birth.year;
    final hadBirthday =
        date.month > _birth.month ||
        (date.month == _birth.month && date.day >= _birth.day);
    if (!hadBirthday) age--;
    return age < 0 ? 0 : age;
  }

  String _status(BuildContext context, int daysUntil) {
    final l = L.of(context);
    if (daysUntil == 0) return l.birthdaysToday;
    if (daysUntil == 1) return l.birthdaysTomorrow;
    return l.birthdaysInDays(daysUntil);
  }

  /// The schedule enum's own strings are English-only.
  String _optionTitle(BirthdayNotificationOption option) {
    final l = L.of(context);
    return switch (option) {
      BirthdayNotificationOption.oneDayBefore => l.birthdayOptOneDay,
      BirthdayNotificationOption.twoHoursBefore => l.birthdayOptTwoHours,
      BirthdayNotificationOption.tenMinutesBefore => l.birthdayOptTenMinutes,
      BirthdayNotificationOption.exactTime => l.birthdayOptExact,
    };
  }

  String _optionBody(BirthdayNotificationOption option) {
    final l = L.of(context);
    return switch (option) {
      BirthdayNotificationOption.oneDayBefore => l.birthdayOptOneDayBody,
      BirthdayNotificationOption.twoHoursBefore => l.birthdayOptTwoHoursBody,
      BirthdayNotificationOption.tenMinutesBefore =>
        l.birthdayOptTenMinutesBody,
      BirthdayNotificationOption.exactTime => l.birthdayOptExactBody,
    };
  }
}
