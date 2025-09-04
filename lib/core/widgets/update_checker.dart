// ==========================================
// UPDATE CHECKER WIDGET (DEPRECATED)  
// ==========================================
// This widget has been replaced with Google Play Store in-app updates
// Using InAppUpdateService instead of GitHub-based updates
// Keeping this code commented for reference

/*
import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateChecker extends StatefulWidget {
  const UpdateChecker({super.key});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  UpdateInfo? _updateInfo;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdatesInBackground();
  }

  Future<void> _checkForUpdatesInBackground() async {
    try {
      final updateInfo = await UpdateService.checkForUpdateSilently();
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
        });
      }
    } catch (e) {
      debugPrint('Background update check failed: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdate();

      if (!mounted) return;

      setState(() {
        _updateInfo = updateInfo;
        _isChecking = false;
      });

      if (updateInfo == null) {
        _showErrorSnackbar('Failed to check for updates');
      } else if (updateInfo.isUpdateAvailable) {
        await UpdateService.showUpdateDialog(context, updateInfo);
      } else {
        _showSuccessSnackbar('You have the latest version!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        _showErrorSnackbar('Error checking for updates: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUpdate = _updateInfo?.isUpdateAvailable == true;

    return Card(
      elevation: 0,
      color: hasUpdate ? Colors.orange.shade50 : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasUpdate ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasUpdate
                        ? Colors.orange.shade100
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasUpdate
                        ? Icons.system_update_alt_rounded
                        : Icons.system_update_rounded,
                    color: hasUpdate
                        ? Colors.orange.shade700
                        : colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasUpdate ? 'Update Available' : 'App Updates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasUpdate
                              ? Colors.orange.shade700
                              : Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        hasUpdate
                            ? 'Version ${_updateInfo!.latestVersion} is available'
                            : 'Check for the latest version',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUpdate)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_updateInfo != null) ...[
                  Text(
                    'Current: ${_updateInfo!.currentVersion}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (hasUpdate) ...[
                    const SizedBox(width: 16),
                    Text(
                      'Latest: ${_updateInfo!.latestVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isChecking
                      ? null
                      : (hasUpdate
                            ? () => UpdateService.showUpdateDialog(
                                context,
                                _updateInfo!,
                              )
                            : _checkForUpdates),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasUpdate
                        ? Colors.orange.shade600
                        : colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isChecking
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          hasUpdate
                              ? Icons.download_rounded
                              : Icons.refresh_rounded,
                          size: 16,
                        ),
                  label: Text(
                    _isChecking
                        ? 'Checking...'
                        : (hasUpdate ? 'Update Now' : 'Check Updates'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
*/

// ==========================================
// END OF DEPRECATED UPDATE CHECKER WIDGET
// ==========================================
