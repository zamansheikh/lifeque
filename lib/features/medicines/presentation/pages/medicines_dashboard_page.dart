import 'package:flutter/material.dart';
import '../../../../core/utils/local_clock.dart';
import 'package:intl/intl.dart';
import '../utils/medicine_l10n.dart';
import '../widgets/care_person_picker.dart';
import '../../data/services/care_person_service.dart';
import '../../../../injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';
import 'add_edit_medicine_page.dart';
import 'medicine_detail_page.dart';
import '../../../../l10n/app_localizations.dart';

class MedicinesDashboardPage extends StatefulWidget {
  const MedicinesDashboardPage({super.key});
  @override
  State<MedicinesDashboardPage> createState() => _MedicinesDashboardPageState();
}

class _MedicinesDashboardPageState extends State<MedicinesDashboardPage> {
  DateTime _selectedDate = DateTime.now();
  bool _requestedReload = false; // prevent multiple queued refreshes

  /// Null means everyone. Held here rather than in the cubit because it only
  /// narrows what is already loaded — no refetch, no flicker.
  String? _personFilter;
  @override
  void initState() {
    super.initState();
    context.read<MedicineCubit>().loadDashboard(date: _selectedDate);
  }

  void _refresh() =>
      context.read<MedicineCubit>().loadDashboard(date: _selectedDate);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: '/medicines'),
      appBar: AppBar(
        title: Text(
          L.of(context).medTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEditMedicinePage(),
                  ),
                );
                if (mounted) _refresh();
              },
              tooltip: L.of(context).medAdd,
            ),
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineError || state is DoseError) {
            final msg = state is MedicineError
                ? state.message
                : (state as DoseError).message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          } else if (state is DoseOperationSuccess ||
              state is MedicineOperationSuccess) {
            final raw = state is DoseOperationSuccess
                ? state.message
                : (state as MedicineOperationSuccess).message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(medicineMessageLabel(context, raw)),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MedicineLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MedicineDashboardLoaded) {
            final people = di.sl<CarePersonService>().getAll();
            final all = state.medicines
                .where((m) => m.status == MedicineStatus.active)
                .toList();
            // A person who has been deleted leaves their medicines behind, so
            // fall back to everyone rather than showing an empty screen.
            final filterIsLive = people.any((p) => p.id == _personFilter);
            final active = (_personFilter == null || !filterIsLive)
                ? all
                : all.where((m) => m.personId == _personFilter).toList();

            final visibleIds = active.map((m) => m.id).toSet();
            final unresolved = state.unresolvedDoses
                .where((d) => visibleIds.contains(d.medicineId))
                .toList();
            final visibleDoses = state.todayDoses
                .where((d) => visibleIds.contains(d.medicineId))
                .toList();

            if (all.isEmpty) {
              return _EmptyState(
                onAdd: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditMedicinePage(),
                    ),
                  );
                  if (mounted) _refresh();
                },
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _DayHeader(
                    date: state.date,
                    onChange: (d) {
                      setState(() => _selectedDate = d);
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (people.length > 1) ...[
                    CarePersonFilterBar(
                      people: people,
                      selectedId: filterIsLive ? _personFilter : null,
                      onChanged: (id) => setState(() => _personFilter = id),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Anything that slipped past unanswered comes first — it is
                  // the only thing on this page the app cannot work out alone.
                  if (unresolved.isNotEmpty) ...[
                    _CatchUpCard(
                      doses: unresolved,
                      medicines: active,
                      showPerson: people.length > 1,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // The doses due, first. This is what the page is for; the
                  // course list used to sit above it and buried the one thing
                  // anyone opens the app to do.
                  _ProgressStrip(doses: visibleDoses),
                  const SizedBox(height: 18),
                  _SectionTitle(L.of(context).medTodayDoses),
                  const SizedBox(height: 8),
                  if (visibleDoses.isEmpty)
                    _Placeholder(
                      icon: Icons.event_available_rounded,
                      text: active.isEmpty && _personFilter != null
                          ? L
                                .of(context)
                                .medNothingForPerson(
                                  people
                                      .firstWhere((p) => p.id == _personFilter)
                                      .name,
                                )
                          : L.of(context).medNoDosesToday,
                    )
                  else
                    ...(visibleDoses..sort(
                          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
                        ))
                        .map(
                          (dose) => _DoseRow(
                            dose: dose,
                            medicine: active.firstWhere(
                              (m) => m.id == dose.medicineId,
                              orElse: () => active.first,
                            ),
                            showPerson: people.length > 1,
                          ),
                        ),

                  const SizedBox(height: 26),
                  _SectionTitle(L.of(context).medActiveCourses),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    _Placeholder(
                      icon: Icons.medication_outlined,
                      text: L
                          .of(context)
                          .medNothingForPerson(
                            people
                                .firstWhere((p) => p.id == _personFilter)
                                .name,
                          ),
                    )
                  else
                    ...active.map(
                      (m) => _CourseRow(
                        medicine: m,
                        doses: state.dosesForMedicine(m.id),
                        showPerson: people.length > 1,
                        onChanged: _refresh,
                      ),
                    ),
                ],
              ),
            );
          }
          // Any other state (e.g., MedicineDetailLoaded, MedicineLoaded, Dose states)
          // means we're coming back from another screen or an operation; trigger a refresh once.
          if (!_requestedReload) {
            _requestedReload = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _refresh();
                _requestedReload = false;
              }
            });
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// Shown when a person filter is on but that person has nothing active.

/// The doses that went by without an answer, and the two buttons that settle
/// them. Deliberately at the top and deliberately loud: an unanswered dose is
/// the one thing here the app cannot decide on its own, and leaving it to rot
/// quietly is what made the adherence history untrustworthy.
class _CatchUpCard extends StatelessWidget {
  const _CatchUpCard({
    required this.doses,
    required this.medicines,
    required this.showPerson,
  });

  final List<MedicineDose> doses;
  final List<Medicine> medicines;
  final bool showPerson;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 19,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.medCatchUpTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              Text(
                l.medCatchUpCount(doses.length),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.medCatchUpBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 12),
          // Oldest first: working down the backlog in order is less confusing
          // than being asked about last night before this morning.
          for (final dose in doses.reversed)
            _CatchUpRow(
              dose: dose,
              medicine: medicines.firstWhere(
                (m) => m.id == dose.medicineId,
                orElse: () => medicines.first,
              ),
              showPerson: showPerson,
            ),
        ],
      ),
    );
  }
}

class _CatchUpRow extends StatelessWidget {
  const _CatchUpRow({
    required this.dose,
    required this.medicine,
    required this.showPerson,
  });

  final MedicineDose dose;
  final Medicine medicine;
  final bool showPerson;

  /// "8:00 pm", or with the day in front once it is no longer today.
  String _when(BuildContext context) {
    final time = Clock.h12(dose.scheduledTime);
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dose.scheduledTime);
    final days = today.difference(day).inDays;
    if (days <= 0) return time;
    if (days == 1) return '${L.of(context).medYesterday} · $time';
    return '${L.of(context).medDaysAgo(days)} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MedicineCubit>();
    final person = showPerson
        ? di.sl<CarePersonService>().findById(medicine.personId)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: medicine.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextSpan(
                        text:
                            '  ${doseLabel(medicine.dosage, medicine.dosageUnit)}'
                            ' · ${_when(context)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (person != null) ...[
                const SizedBox(width: 8),
                CarePersonAvatar(person: person, size: 22),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CatchUpButton(
                  label: L.of(context).medCatchUpTaken,
                  icon: Icons.check_rounded,
                  color: const Color(0xFF10B981),
                  filled: true,
                  onTap: () => cubit.markDoseAsTaken(dose.id, medicine.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CatchUpButton(
                  label: L.of(context).medCatchUpMissed,
                  icon: Icons.close_rounded,
                  color: const Color(0xFFB45309),
                  onTap: () => cubit.markDoseAsMissed(dose.id, medicine.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatchUpButton extends StatelessWidget {
  const _CatchUpButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled ? color : color.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: filled ? Colors.white : color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit and delete for a course.
///
/// Delete lived on the old dashboard card and was lost when that card was
/// replaced; without it a medicine added by mistake could never be removed.
class _CourseMenu extends StatelessWidget {
  const _CourseMenu({required this.medicine, required this.onChanged});

  final Medicine medicine;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'edit') {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditMedicinePage(medicine: medicine),
            ),
          );
          onChanged();
        } else {
          await _confirmDelete(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 18),
              const SizedBox(width: 10),
              Text(l.medEditAction),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 10),
              Text(
                l.medDeleteAction,
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = L.of(context);
    final cubit = context.read<MedicineCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l.medDeleteTitle),
        content: Text('${medicine.name}\n\n${l.medDeleteBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.permCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.medDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.deleteMedicine(medicine.id);
  }
}

// ─── Building blocks of the redesigned dashboard ─────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
    child: Column(
      children: [
        Icon(icon, size: 34, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

/// One line of progress instead of the full-width card that used to push the
/// doses themselves below the fold.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.doses});

  final List<MedicineDose> doses;

  @override
  Widget build(BuildContext context) {
    final total = doses.length;
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final done = total > 0 && taken == total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.task_alt_rounded : Icons.medication_liquid_rounded,
                size: 17,
                color: done ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  done
                      ? L.of(context).medAllDoneToday
                      : L.of(context).medDoseProgress(taken, total),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: done
                        ? const Color(0xFF10B981)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : taken / total,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                done ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single dose: when, what, for whom, and one tap to tick it off.
class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.dose,
    required this.medicine,
    required this.showPerson,
  });

  final MedicineDose dose;
  final Medicine medicine;
  final bool showPerson;

  @override
  Widget build(BuildContext context) {
    final pending = dose.status == DoseStatus.pending;
    final overdue = pending && dose.scheduledTime.isBefore(DateTime.now());
    final person = showPerson
        ? di.sl<CarePersonService>().findById(medicine.personId)
        : null;
    final accent = switch (dose.status) {
      DoseStatus.taken => const Color(0xFF10B981),
      DoseStatus.skipped => const Color(0xFFF59E0B),
      DoseStatus.missed => const Color(0xFFEF4444),
      DoseStatus.pending =>
        overdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue
              ? accent.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Time first — a dose list is read down the clock.
          SizedBox(
            width: 74,
            child: Text(
              Clock.h12(dose.scheduledTime),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    decoration: dose.status == DoseStatus.taken
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    // Overdue leads: the line is one row deep, and this is the
                    // part that must survive when Bangla runs long enough to
                    // truncate. Meal timing is the least urgent, so it trails.
                    if (overdue) L.of(context).medOverdue,
                    doseLabel(medicine.dosage, medicine.dosageUnit),
                    if (medicine.mealTiming != MealTiming.anytime)
                      mealTimingLabel(context, medicine.mealTiming),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: overdue ? accent : const Color(0xFF94A3B8),
                    fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (person != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      CarePersonAvatar(person: person, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        person.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: person.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (pending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DoseAction(
                  icon: Icons.skip_next_rounded,
                  color: const Color(0xFFF59E0B),
                  tooltip: L.of(context).medSkipAction,
                  onTap: () => context.read<MedicineCubit>().markDoseAsSkipped(
                    dose.id,
                    medicine.id,
                  ),
                ),
                const SizedBox(width: 6),
                _DoseAction(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF10B981),
                  filled: true,
                  tooltip: L.of(context).medDoseTaken,
                  onTap: () => context.read<MedicineCubit>().markDoseAsTaken(
                    dose.id,
                    medicine.id,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                switch (dose.status) {
                  DoseStatus.taken => Icons.check_circle_rounded,
                  DoseStatus.skipped => Icons.remove_circle_rounded,
                  _ => Icons.cancel_rounded,
                },
                color: accent,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _DoseAction extends StatelessWidget {
  const _DoseAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 38,
            child: Icon(icon, size: 21, color: filled ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}

/// A course at a glance. The detail page carries the rest.
class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.medicine,
    required this.doses,
    required this.showPerson,
    required this.onChanged,
  });

  final Medicine medicine;
  final List<MedicineDose> doses;
  final bool showPerson;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final person = showPerson
        ? di.sl<CarePersonService>().findById(medicine.personId)
        : null;
    final left = medicine.calculatedEndDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 100000);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MedicineDetailPage(medicine: medicine),
              ),
            );
            onChanged();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (person?.color ?? const Color(0xFF3B82F6))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 21,
                    color: person?.color ?? const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          doseLabel(medicine.dosage, medicine.dosageUnit),
                          L.of(context).medTimesADay(medicine.timesPerDay),
                          // An open-ended course has no meaningful countdown.
                          if (medicine.isOngoing)
                            L.of(context).medOngoing
                          else
                            L.of(context).medDaysLeft(left),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (person != null) ...[
                  const SizedBox(width: 8),
                  CarePersonAvatar(person: person, size: 26),
                ],
                _CourseMenu(medicine: medicine, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            L.of(context).medEmptyTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            L.of(context).medEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                L.of(context).medAdd,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChange;
  const _DayHeader({required this.date, required this.onChange});
  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMM y').format(date);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF64748B),
              ),
              onPressed: () => onChange(date.subtract(const Duration(days: 1))),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                formatted,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
              ),
              onPressed: () => onChange(date.add(const Duration(days: 1))),
            ),
          ),
        ],
      ),
    );
  }
}
