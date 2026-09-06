import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/detail_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import 'add_edit_medicine_page.dart';
import '../../../../core/utils/local_clock.dart';

/// A medicine's detail view: how the course is going, what it is, and every
/// dose so far.
///
/// Rebuilt on the shared detail kit, so it reads like the task, reminder,
/// birthday and to-do pages instead of the gradient-heavy card stack it was.
class MedicineDetailPage extends StatefulWidget {
  final Medicine medicine;

  const MedicineDetailPage({super.key, required this.medicine});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  /// The last good snapshot, kept so an unrelated cubit state (a dose being
  /// written, say) doesn't blank the page.
  MedicineDetailLoaded? _cachedDetail;

  static const _accent = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    context.read<MedicineCubit>().loadMedicineDetail(widget.medicine.id);
  }

  void _reload() =>
      context.read<MedicineCubit>().loadMedicineDetail(widget.medicine.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          L.of(context).medDetailTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Refresh used to be a third button up here; the list pulls to
          // refresh instead.
          IconButton(
            tooltip: L.of(context).commonEdit,
            icon: const Icon(Icons.edit_rounded, size: 21),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditMedicinePage(medicine: widget.medicine),
                ),
              );
              if (mounted) _reload();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineDetailLoaded &&
              state.medicine.id == widget.medicine.id) {
            setState(() => _cachedDetail = state);
          }
        },
        builder: (context, state) {
          if (state is MedicineError || state is DoseError) {
            final message = state is MedicineError
                ? state.message
                : (state as DoseError).message;
            return _error(message);
          }
          if (_cachedDetail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: _detail(_cachedDetail!),
          );
        },
      ),
    );
  }

  Widget _error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _reload,
              child: Text(L.of(context).commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(MedicineDetailLoaded state) {
    final medicine = state.medicine;
    final accent = _statusAccent(medicine);
    final l = L.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        DetailHero(
          icon: Icons.medication_rounded,
          accent: accent,
          status: _statusLabel(context, medicine),
          title: medicine.name,
          subtitle:
              '${medicine.dosageDisplay} · '
              '${l.medTimesADay(medicine.timesPerDay)} · '
              '${medicine.mealTimingDisplayName}',
          description: medicine.description,
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: l.medSectionCourse,
          icon: Icons.insights_rounded,
          accent: accent,
          children: [
            DetailProgress(
              value: state.adherencePercent,
              color: accent,
              label: l.medDosesTaken,
            ),
            const SizedBox(height: 14),
            DetailProgress(
              value: state.daysTotal == 0
                  ? 0
                  : state.daysElapsed / state.daysTotal,
              color: const Color(0xFF7C3AED),
              label: l.medDayOf(state.daysElapsed, state.daysTotal),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DetailStat(
                    value: '${state.taken}',
                    label: l.medDoseTaken,
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DetailStat(
                    value: '${state.pending}',
                    label: l.medDoseToCome,
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DetailStat(
                    value: '${state.skipped}',
                    label: l.medDoseSkipped,
                    icon: Icons.skip_next_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DetailStat(
                    value: '${state.missed}',
                    label: l.medDoseMissed,
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: l.detailSectionAbout,
          icon: Icons.info_outline_rounded,
          accent: Colors.grey.shade500,
          children: [
            DetailRow(
              icon: Icons.category_rounded,
              label: l.medType,
              value: medicine.typeDisplayName,
            ),
            DetailRow(
              icon: Icons.science_rounded,
              label: l.medDosage,
              value: medicine.dosageDisplay,
            ),
            DetailRow(
              icon: Icons.restaurant_rounded,
              label: l.medTiming,
              value: medicine.mealTimingDisplayName,
            ),
            DetailRow(
              icon: Icons.play_circle_outline_rounded,
              label: l.medStarted,
              value: DateFormat('d MMM y').format(medicine.startDate),
            ),
            DetailRow(
              icon: Icons.flag_rounded,
              label: l.medEnds,
              value: DateFormat('d MMM y').format(medicine.calculatedEndDate),
            ),
            if (medicine.doctorName != null)
              DetailRow(
                icon: Icons.person_rounded,
                label: l.medDoctor,
                value: medicine.doctorName!,
              ),
            if (medicine.notes != null && medicine.notes!.trim().isNotEmpty)
              DetailRow(
                icon: Icons.sticky_note_2_outlined,
                label: l.medNotes,
                value: medicine.notes!,
              ),
            if (medicine.notificationTimes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final time in medicine.notificationTimes)
                    _timeChip(time, accent),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: l.medSectionDoseHistory,
          icon: Icons.history_rounded,
          accent: _accent,
          children: [
            if (state.doses.isEmpty)
              Text(
                l.medNoDoses,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              )
            else
              for (final entry in state.dosesByDate.entries)
                _dayTile(entry.key, entry.value),
          ],
        ),
      ],
    );
  }

  Widget _timeChip(String time, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: accent),
          const SizedBox(width: 5),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  /// One day of the course, collapsed to "3/3" until it's opened.
  Widget _dayTile(DateTime date, List<MedicineDose> doses) {
    final sorted = [...doses]
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final taken = sorted.where((d) => d.status == DoseStatus.taken).length;
    final complete = taken == sorted.length && sorted.isNotEmpty;
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Theme(
      // The default divider draws a line across the card on every tile.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        initiallyExpanded: isToday,
        title: Row(
          children: [
            Text(
              isToday
                  ? L.of(context).commonToday
                  : DateFormat('EEE, d MMM').format(date),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isToday ? _accent : Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: (complete ? const Color(0xFF10B981) : Colors.grey)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$taken/${sorted.length}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: complete
                      ? const Color(0xFF059669)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        children: [for (final dose in sorted) _doseRow(dose)],
      ),
    );
  }

  Widget _doseRow(MedicineDose dose) {
    final color = _doseColor(dose.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_doseIcon(dose.status), color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Clock.h12(dose.scheduledTime),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // The row used to end with the last four characters of the dose's
          // id, which means nothing to anybody reading it.
          Text(
            _doseLabel(dose.status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _doseColor(DoseStatus status) => switch (status) {
    DoseStatus.taken => const Color(0xFF10B981),
    DoseStatus.pending => const Color(0xFF06B6D4),
    DoseStatus.skipped => const Color(0xFFF59E0B),
    DoseStatus.missed => const Color(0xFFEF4444),
  };

  IconData _doseIcon(DoseStatus status) => switch (status) {
    DoseStatus.taken => Icons.check_circle_rounded,
    DoseStatus.pending => Icons.schedule_rounded,
    DoseStatus.skipped => Icons.skip_next_rounded,
    DoseStatus.missed => Icons.cancel_rounded,
  };

  String _doseLabel(DoseStatus status) {
    final l = L.of(context);
    return switch (status) {
      DoseStatus.taken => l.medDoseTaken,
      DoseStatus.pending => l.medDoseToCome,
      DoseStatus.skipped => l.medDoseSkipped,
      DoseStatus.missed => l.medDoseMissed,
    };
  }

  Color _statusAccent(Medicine medicine) {
    if (medicine.isCompleted) return const Color(0xFF10B981);
    if (medicine.isActive) return _accent;
    return const Color(0xFFF59E0B);
  }

  String _statusLabel(BuildContext context, Medicine medicine) {
    final l = L.of(context);
    if (medicine.isCompleted) return l.medStatusFinished;
    if (medicine.isActive) return l.medStatusOnCourse;
    return l.medStatusNotStarted;
  }
}
