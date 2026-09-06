import 'package:flutter/material.dart';
import '../../../../core/utils/local_numbers.dart';
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

  /// Turns the cubit's outcome code into words. An unrecognised value is
  /// passed through, so a message the cubit has not been taught yet still
  /// shows rather than vanishing.
  String _successText(BuildContext context, String raw) {
    final l = L.of(context);
    return switch (MedicineMessage.parse(raw)) {
      MedicineMessage.added => l.medMsgAdded,
      MedicineMessage.updated => l.medMsgUpdated,
      MedicineMessage.deleted => l.medMsgDeleted,
      MedicineMessage.doseTaken => l.medMsgDoseTaken,
      MedicineMessage.doseSkipped => l.medMsgDoseSkipped,
      MedicineMessage.doseMissed => l.medMsgDoseMissed,
      null => raw,
    };
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
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
              tooltip: L.of(context).medRefresh,
            ),
          ),
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
                content: Text(_successText(context, raw)),
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
                  const SizedBox(height: 16),
                  if (people.length > 1) ...[
                    CarePersonFilterBar(
                      people: people,
                      selectedId: filterIsLive ? _personFilter : null,
                      onChanged: (id) => setState(() => _personFilter = id),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SummaryBar(doses: state.todayDoses),
                  const SizedBox(height: 24),
                  if (active.isEmpty)
                    _NothingForPerson(
                      name: people
                          .firstWhere((p) => p.id == _personFilter)
                          .name,
                    )
                  else
                    ...active.map(
                      (m) => _MedicineProgressCard(
                        medicine: m,
                        doses: state.dosesForMedicine(m.id),
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
class _NothingForPerson extends StatelessWidget {
  const _NothingForPerson({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            L.of(context).medNothingForPerson(name),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
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

class _SummaryBar extends StatelessWidget {
  final List<MedicineDose> doses;
  const _SummaryBar({required this.doses});
  @override
  Widget build(BuildContext context) {
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final skipped = doses.where((d) => d.status == DoseStatus.skipped).length;
    final missed = doses.where((d) => d.status == DoseStatus.missed).length;
    final pending = doses.where((d) => d.status == DoseStatus.pending).length;
    final total = doses.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.of(context).medTodayOverview,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CountChip(
                  label: L.of(context).medDoseTaken,
                  value: taken,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountChip(
                  label: L.of(context).medDosePending,
                  value: pending,
                  color: const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountChip(
                  label: L.of(context).medDoseSkipped,
                  value: skipped,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountChip(
                  label: L.of(context).medDoseMissed,
                  value: missed,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : taken / total,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${L.of(context).medProgress}: ${N.percent(total == 0 ? 0 : ((taken / total) * 100).round())}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            N.of(value),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          // Bangla labels run longer than the English they were sized for, so
          // they scale down instead of overflowing the tile.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineProgressCard extends StatelessWidget {
  final Medicine medicine;
  final List<MedicineDose> doses;
  const _MedicineProgressCard({required this.medicine, required this.doses});

  /// Whose medicine this is. Absent when nobody is set, or when only one
  /// person exists — with a single person the badge says nothing.
  Widget? _personBadge(String? personId) {
    final service = di.sl<CarePersonService>();
    if (service.getAll().length < 2) return null;
    final person = service.findById(personId);
    if (person == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          CarePersonAvatar(person: person, size: 18),
          const SizedBox(width: 6),
          Text(
            person.name,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: person.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Today stats for this medicine
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final pending = doses.where((d) => d.status == DoseStatus.pending).length;
    final skipped = doses.where((d) => d.status == DoseStatus.skipped).length;
    final missed = doses.where((d) => d.status == DoseStatus.missed).length;
    final totalToday = doses.length;
    final pct = totalToday == 0 ? 0.0 : taken / totalToday;

    // Next pending / upcoming
    final now = DateTime.now();
    final upcoming =
        doses
            .where((d) => d.status == DoseStatus.pending)
            .where((d) => d.scheduledTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final next = upcoming.isNotEmpty ? upcoming.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () async {
          // Navigate to detail; when returning ensure dashboard state is reloaded.
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MedicineDetailPage(medicine: medicine),
            ),
          );
          if (context.mounted) {
            // Reload dashboard for the current (today) date so we exit any detail state.
            context.read<MedicineCubit>().loadDashboard();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        ?_personBadge(medicine.personId),
                        const SizedBox(height: 6),
                        Text(
                          '${doseLabel(medicine.dosage, medicine.dosageUnit)}'
                          ' • ${L.of(context).medTimesADay(medicine.timesPerDay)}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mealTimingLabel(context, medicine.mealTiming),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _TodayStatusPill(taken: taken, total: totalToday),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          tooltip: L.of(context).medDetails,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () => _showDetails(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _modernChip(
                    Icons.check_circle_rounded,
                    '${L.of(context).medDoseTaken} ${N.of(taken)}',
                    const Color(0xFF10B981),
                  ),
                  _modernChip(
                    Icons.schedule_rounded,
                    '${L.of(context).medDosePending} ${N.of(pending)}',
                    const Color(0xFF06B6D4),
                  ),
                  if (skipped > 0)
                    _modernChip(
                      Icons.skip_next_rounded,
                      '${L.of(context).medDoseSkipped} ${N.of(skipped)}',
                      const Color(0xFFF59E0B),
                    ),
                  if (missed > 0)
                    _modernChip(
                      Icons.error_rounded,
                      '${L.of(context).medDoseMissed} ${N.of(missed)}',
                      const Color(0xFFEF4444),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: next == null
                        ? Text(
                            L.of(context).medDoseTaken,
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            L
                                .of(context)
                                .medNextDose(Clock.h12(next.scheduledTime)),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                  ),
                  _ActionButtons(medicine: medicine, doses: doses),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernStatusCount(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            N.of(value),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context) {
    final totalCourseDoses = medicine.totalDoses;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final taken = doses.where((d) => d.status == DoseStatus.taken).length;
        final skipped = doses
            .where((d) => d.status == DoseStatus.skipped)
            .length;
        final missed = doses.where((d) => d.status == DoseStatus.missed).length;
        final pending = doses
            .where((d) => d.status == DoseStatus.pending)
            .length;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${doseLabel(medicine.dosage, medicine.dosageUnit)}'
                            ' • ${medicineTypeLabel(context, medicine.type)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: L.of(context).medEditAction,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditMedicinePage(medicineId: medicine.id),
                            ),
                          );
                          if (context.mounted) {
                            context.read<MedicineCubit>().loadDashboard();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: IconButton(
                        tooltip: L.of(context).medDeleteAction,
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xFFDC2626),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                L.of(context).medDeleteTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              content: Text(
                                L.of(context).medDeleteBody,
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    L.of(context).permCancel,
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      L.of(context).medDeleteAction,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            context.read<MedicineCubit>().deleteMedicine(
                              medicine.id,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.of(context).medCourseDetails,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _modernChip(
                            Icons.calendar_today,
                            L
                                .of(context)
                                .medStartedOn(
                                  DateFormat(
                                    'd MMM',
                                  ).format(medicine.startDate),
                                ),
                            const Color(0xFF3B82F6),
                          ),
                          _modernChip(
                            Icons.event,
                            L
                                .of(context)
                                .medEndsOn(
                                  DateFormat(
                                    'd MMM',
                                  ).format(medicine.calculatedEndDate),
                                ),
                            const Color(0xFF3B82F6),
                          ),
                          _modernChip(
                            Icons.timelapse,
                            L.of(context).medDaysCount(medicine.durationInDays),
                            const Color(0xFF8B5CF6),
                          ),
                          _modernChip(
                            Icons.list_alt,
                            L.of(context).medTotalDoses(totalCourseDoses),
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.of(context).medTodayProgress,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _modernStatusCount(
                            'Taken',
                            taken,
                            const Color(0xFF10B981),
                          ),
                          _modernStatusCount(
                            'Pending',
                            pending,
                            const Color(0xFF3B82F6),
                          ),
                          _modernStatusCount(
                            'Skipped',
                            skipped,
                            const Color(0xFFF59E0B),
                          ),
                          _modernStatusCount(
                            'Missed',
                            missed,
                            const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text(
                        L.of(context).medClose,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayStatusPill extends StatelessWidget {
  final int taken;
  final int total;
  const _TodayStatusPill({required this.taken, required this.total});
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (taken / total * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF059669).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        N.percent(pct),
        style: const TextStyle(
          color: Color(0xFF059669),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Medicine medicine;
  final List<MedicineDose> doses;
  const _ActionButtons({required this.medicine, required this.doses});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MedicineCubit>();
    // Find earliest pending dose for actions
    final pending = doses.where((d) => d.status == DoseStatus.pending).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final target = pending.isNotEmpty ? pending.first : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: target == null
                ? const Color(0xFFF1F5F9)
                : const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: target == null
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: IconButton(
            tooltip: 'Taken',
            onPressed: target == null
                ? null
                : () => cubit.markDoseAsTaken(target.id, medicine.id),
            icon: Icon(
              Icons.check_circle_rounded,
              color: target == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF10B981),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: target == null
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: target == null
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: IconButton(
            tooltip: L.of(context).medSkipAction,
            onPressed: target == null
                ? null
                : () => cubit.markDoseAsSkipped(target.id, medicine.id),
            icon: Icon(
              Icons.skip_next_rounded,
              color: target == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFF59E0B),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: target == null
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: target == null
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: IconButton(
            tooltip: L.of(context).medMissAction,
            onPressed: target == null
                ? null
                : () => cubit.markDoseAsMissed(target.id, medicine.id),
            icon: Icon(
              Icons.cancel_rounded,
              color: target == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFEF4444),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
