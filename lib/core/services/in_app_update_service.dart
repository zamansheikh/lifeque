import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../injection_container.dart' as di;
import '../../l10n/app_localizations.dart';
import 'navigation_service.dart';

/// Google Play in-app updates: the check, the offer, and the two ways of
/// taking it.
///
/// Play knows two flows. *Immediate* hands the screen to Play, which installs
/// and restarts the app — right when the fix matters. *Flexible* downloads
/// behind the app and installs on a restart the app asks for. Which one runs
/// is Play's call (it says which it allows); this service asks for immediate
/// when it can, flexible otherwise, and finishes the flexible one properly,
/// which the old code never did — downloads sat there uninstalled.
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  static const _promptDayKey = 'update_prompt_day';

  /// The update Play has for us, or null when there is none or this is not
  /// Android.
  ///
  /// Play throws for a sideloaded build or with no network. On the quiet
  /// launch check that is swallowed — nothing to say. From the Settings
  /// button it is rethrown, so the person sees "couldn't check" rather than
  /// a false "up to date".
  static Future<AppUpdateInfo?> checkForUpdates({bool quiet = true}) async {
    if (!Platform.isAndroid) return null;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('🆕 Update available: ${info.availableVersionCode}');
        return info;
      }
      debugPrint('✅ App is up to date');
      return null;
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      if (!quiet) rethrow;
      return null;
    }
  }

  /// On launch: offer the update if there is one.
  ///
  /// Once a day for an ordinary update, so "Later" means later. Every launch
  /// when Play marks it high priority or the install is a week or more
  /// behind — at that point the nag is the point. Returns whether a sheet
  /// was shown, so the caller can hold back its other prompts.
  static Future<bool> maybePromptOnLaunch(BuildContext context) async {
    final info = await checkForUpdates();
    if (info == null) return false;

    final prefs = di.sl<SharedPreferences>();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final urgent =
        info.updatePriority >= 4 || (info.clientVersionStalenessDays ?? 0) >= 7;
    if (!urgent && prefs.getString(_promptDayKey) == today) return false;

    await prefs.setString(_promptDayKey, today);
    if (!context.mounted) return false;
    await showUpdateSheet(context, info);
    return true;
  }

  static Future<void> showUpdateSheet(
    BuildContext context,
    AppUpdateInfo info,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateSheet(info: info),
    );
  }

  /// Runs whichever flow Play allows. Immediate returns when Play is done
  /// with the screen; flexible downloads, then asks before restarting.
  static Future<void> update(AppUpdateInfo info) async {
    try {
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
      if (!info.flexibleUpdateAllowed) return;

      final host = NavigationService.navigatorKey.currentContext;
      if (host != null && host.mounted) {
        ScaffoldMessenger.maybeOf(
          host,
        )?.showSnackBar(SnackBar(content: Text(L.of(host).updateDownloading)));
      }
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) return;

      final ctx = NavigationService.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        // Nobody to ask; install on the next restart, which Play does anyway.
        return;
      }
      await showModalBottomSheet<void>(
        context: ctx,
        backgroundColor: Colors.transparent,
        builder: (_) => const _DownloadedSheet(),
      );
    } catch (e) {
      debugPrint('❌ Update flow failed: $e');
    }
  }
}

/// "A new version is ready" — the offer, in the app's language.
class UpdateSheet extends StatelessWidget {
  final AppUpdateInfo info;

  const UpdateSheet({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _PromptSheet(
      icon: Icons.system_update_rounded,
      title: l.updateAvailableTitle,
      body: l.updateAvailableBody,
      action: l.updateNow,
      later: l.updateLater,
      onAction: () {
        Navigator.of(context).pop();
        InAppUpdateService.update(info);
      },
    );
  }
}

class _DownloadedSheet extends StatelessWidget {
  const _DownloadedSheet();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _PromptSheet(
      icon: Icons.download_done_rounded,
      title: l.updateDownloadedTitle,
      body: l.updateDownloadedBody,
      action: l.updateInstall,
      later: l.updateLater,
      onAction: () {
        Navigator.of(context).pop();
        InAppUpdate.completeFlexibleUpdate();
      },
    );
  }
}

class _PromptSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final String later;
  final VoidCallback onAction;

  const _PromptSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.later,
    required this.onAction,
  });

  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        18 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 32, color: _accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: Text(later),
          ),
        ],
      ),
    );
  }
}
