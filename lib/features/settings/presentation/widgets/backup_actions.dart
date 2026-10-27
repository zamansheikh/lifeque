import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../debts/presentation/debt_cubit.dart';
import '../../../habits/presentation/habit_cubit.dart';
import '../../../qaza/qaza_store.dart';
import '../../../ramadan/ramadan_store.dart';
import '../../../subscriptions/presentation/subscription_cubit.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/language_preference_service.dart';
import '../../../../core/services/navigation_preferences_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/database_helper.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../injection_container.dart' as di;
import '../../../../l10n/app_localizations.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../../../home_widget/services/home_widget_service.dart';
import '../../../medicines/domain/repositories/medicine_repository.dart';
import '../../../medicines/presentation/bloc/medicine_cubit.dart';
import '../../../study/services/study_sound_service.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/widgets/birthday_wish/birthday_wish_log.dart';
import '../../../tasks/data/run_todo_migration.dart';

/// Export and import of a full backup, from the Settings page.
///
/// Files only ever pass through the system share sheet, the system "save as"
/// screen and the system file picker. Those hand the app the one file the
/// user chose, so no storage permission is requested.
class BackupActions {
  BackupActions._();

  static Future<BackupService> _service() async {
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    return BackupService(
      database: () => di.sl<DatabaseHelper>().database,
      prefs: SharedPreferences.getInstance,
      appVersion: version,
    );
  }

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ── Export ──────────────────────────────────────────────────────────────

  static Future<void> export(BuildContext context) async {
    final choice = await showModalBottomSheet<_ExportTo>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _ExportSheet(),
    );
    if (choice == null || !context.mounted) return;
    final l = L.of(context);

    try {
      final service = await _service();
      final bytes = Uint8List.fromList(utf8.encode(await service.export()));
      final name = service.fileName();

      if (choice == _ExportTo.phone) {
        final saved = await FilePicker.saveFile(
          fileName: name,
          bytes: bytes,
          mimeType: 'application/json',
        );
        if (saved != null && context.mounted) _snack(context, l.backupSaved);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: 'application/json')]),
        );
      }
    } catch (e) {
      debugPrint('💾 Backup export failed: $e');
      if (context.mounted) _snack(context, l.backupFailed);
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────

  static Future<void> import(BuildContext context) async {
    final l = L.of(context);

    // Any file type: a backup that came through WhatsApp or Drive often loses
    // its .json name or its type, so the contents decide, not the extension.
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile();
    } catch (e) {
      debugPrint('💾 Picker failed: $e');
      return;
    }
    if (file == null || !context.mounted) return;

    final service = await _service();
    final String json;
    final BackupSummary summary;
    try {
      json = utf8.decode(await file.readAsBytes());
      summary = service.inspect(json);
    } on BackupException catch (e) {
      if (context.mounted) _snack(context, _problemText(l, e.problem));
      return;
    } catch (_) {
      if (context.mounted) _snack(context, l.backupNotABackup);
      return;
    }
    if (!context.mounted) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RestoreDialog(summary: summary),
    );
    if (go != true || !context.mounted) return;

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(l.backupRestoring)),
              ],
            ),
          ),
        ),
      ),
    );

    String message;
    try {
      await service.restore(json);
      await _afterRestore();
      message = l.backupRestored;
    } on BackupException catch (e) {
      message = _problemText(l, e.problem);
    } catch (e) {
      debugPrint('💾 Restore failed: $e');
      message = l.backupRestoreFailed;
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    // Back to the (restored) home screen, so every page reads the new data.
    final prefs = await SharedPreferences.getInstance();
    router.go(NavigationPreferencesService(prefs).getHomeRoute());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _problemText(L l, BackupProblem p) => switch (p) {
    BackupProblem.notABackup => l.backupNotABackup,
    BackupProblem.tooNew => l.backupTooNew,
    BackupProblem.writeFailed => l.backupRestoreFailed,
  };

  /// Everything that read settings or data into memory reads them again, and
  /// alarms and notifications are rebuilt from the restored data. Each step
  /// is best-effort: the data is already restored, and one stale screen
  /// should not report the whole restore as failed.
  static Future<void> _afterRestore() async {
    Future<void> step(String name, FutureOr<void> Function() body) async {
      try {
        await body();
      } catch (e) {
        debugPrint('💾 After restore, $name failed: $e');
      }
    }

    await step('language', LanguagePreferenceService.instance.load);
    await step('prayer alarms', PrayerAlarmService().reloadFromStorage);
    await step('study sounds', StudySounds.instance.load);
    await step('birthday wishes', BirthdayWishLog.instance.load);
    // A backup from before the merge still holds a separate to-do list.
    await step('to-dos', runTodoMigration);
    await step('notifications', () async {
      final ns = di.sl<NotificationService>();
      await ns.syncNotifications(
        di.sl<MedicineRepository>(),
        di.sl<TaskRepository>(),
      );
    });
    await step('screens', () async {
      di.sl<TaskBloc>().add(LoadTasks());
      di.sl<ExpenseBloc>().add(LoadSessions());
      await di.sl<MedicineCubit>().loadDashboard();
      await di.sl<SubscriptionCubit>().load();
      await di.sl<DebtCubit>().load();
      await di.sl<HabitCubit>().load();
    });
    await step('qaza', QazaStore.instance.load);
    await step('ramadan', RamadanStore.instance.load);
    unawaited(step('home widget', () => HomeWidgetService().updateWidget()));
  }
}

enum _ExportTo { phone, share }

class _ExportSheet extends StatelessWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget option(_ExportTo to, IconData icon, String title, String body) {
      return ListTile(
        key: Key('backup-export-${to.name}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(body),
        onTap: () => Navigator.of(context).pop(to),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.backupExport,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            option(
              _ExportTo.phone,
              Icons.save_alt_rounded,
              l.backupSaveToPhone,
              l.backupSaveToPhoneBody,
            ),
            option(
              _ExportTo.share,
              Icons.share_rounded,
              l.backupShare,
              l.backupShareBody,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.backupPrivateNote,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestoreDialog extends StatelessWidget {
  final BackupSummary summary;
  const _RestoreDialog({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final tasks = summary.rowsIn('tasks');
    final medicines = summary.rowsIn('medicines');
    final date = DateFormat.yMMMd().add_jm().format(summary.createdAt);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l.backupRestoreTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.backupMadeOn(N.digits(date))),
          if (tasks > 0) ...[
            const SizedBox(height: 6),
            Text('• ${l.backupTasksCount(tasks)}'),
          ],
          if (medicines > 0) ...[
            const SizedBox(height: 4),
            Text('• ${l.backupMedicinesCount(medicines)}'),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.backupRestoreWarning,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: const Key('backup-restore-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.backupRestoreAction),
        ),
      ],
    );
  }
}
