import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  /// Check for available updates from Google Play Store
  static Future<AppUpdateInfo?> checkForUpdates() async {
    // Play in-app updates are Android-only; the plugin has no iOS
    // implementation, so calling it there just throws MissingPluginException.
    if (!Platform.isAndroid) return null;
    try {
      debugPrint('🔄 Checking for app updates from Google Play Store...');

      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('🆕 Update available: ${updateInfo.availableVersionCode}');
        return updateInfo;
      } else {
        debugPrint('✅ App is up to date');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Start immediate update (forces user to update)
  static Future<void> startImmediateUpdate() async {
    try {
      debugPrint('🔄 Starting immediate update...');
      await InAppUpdate.startFlexibleUpdate();
      debugPrint('✅ Immediate update started');
    } catch (e) {
      debugPrint('❌ Error starting immediate update: $e');
    }
  }

  /// Start flexible update (user can continue using app while downloading)
  static Future<void> startFlexibleUpdate() async {
    try {
      debugPrint('🔄 Starting flexible update...');
      await InAppUpdate.startFlexibleUpdate();
      debugPrint('✅ Flexible update started');
    } catch (e) {
      debugPrint('❌ Error starting flexible update: $e');
    }
  }

  /// Complete flexible update installation
  static Future<void> completeFlexibleUpdate() async {
    try {
      debugPrint('🔄 Completing flexible update...');
      await InAppUpdate.completeFlexibleUpdate();
      debugPrint('✅ Flexible update completed');
    } catch (e) {
      debugPrint('❌ Error completing flexible update: $e');
    }
  }

  /// Show update dialog with options
  static Future<void> showUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Update Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A new version of LifeQue is available on Google Play Store.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Version: ${updateInfo.availableVersionCode}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update Priority: High',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            if (updateInfo.immediateUpdateAllowed)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  startImmediateUpdate();
                },
                child: const Text('Update Now'),
              ),
            if (updateInfo.flexibleUpdateAllowed)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  startFlexibleUpdate();
                },
                child: const Text('Update in Background'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ],
        );
      },
    );
  }

  /// Show update snackbar for flexible updates
  static void showUpdateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text('Update downloaded. Tap to install.'),
          ],
        ),
        action: SnackBarAction(
          label: 'INSTALL',
          textColor: Colors.yellow,
          onPressed: () => completeFlexibleUpdate(),
        ),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static bool _hasCheckedThisSession = false;

  /// Check and handle updates automatically
  static Future<void> checkAndHandleUpdates(
    BuildContext context, {
    bool force = false,
  }) async {
    // If not forced and already checked this session, skip
    if (!force && _hasCheckedThisSession) {
      debugPrint('ℹ️ Skip update check: Already checked this session');
      return;
    }

    try {
      final updateInfo = await checkForUpdates();

      if (updateInfo != null && context.mounted) {
        _hasCheckedThisSession = true;
        // Show update dialog
        await showUpdateDialog(context, updateInfo);
      } else if (updateInfo == null) {
        // Mark as checked even if no update found
        _hasCheckedThisSession = true;
      }
    } catch (e) {
      debugPrint('❌ Error in checkAndHandleUpdates: $e');
    }
  }
}
