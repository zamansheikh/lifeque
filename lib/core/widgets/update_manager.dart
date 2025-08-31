import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateManager extends StatefulWidget {
  final Widget child;
  final bool showUpdateDialogOnStartup;

  const UpdateManager({
    super.key,
    required this.child,
    this.showUpdateDialogOnStartup = true,
  });

  @override
  State<UpdateManager> createState() => _UpdateManagerState();
}

class _UpdateManagerState extends State<UpdateManager> {
  bool _hasCheckedForUpdates = false;

  @override
  void initState() {
    super.initState();
    if (widget.showUpdateDialogOnStartup) {
      _checkForUpdatesOnStartup();
    }
  }

  /// Check for updates when app starts and show dialog if available
  void _checkForUpdatesOnStartup() async {
    // Wait a bit for the app to settle
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasCheckedForUpdates) return;

    try {
      _hasCheckedForUpdates = true;
      final updateInfo = await UpdateService.checkForUpdateSilently();

      if (mounted && updateInfo?.isUpdateAvailable == true) {
        // Show update dialog with delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await UpdateService.showUpdateDialog(context, updateInfo!);
        }
      }
    } catch (e) {
      debugPrint('Startup update check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
