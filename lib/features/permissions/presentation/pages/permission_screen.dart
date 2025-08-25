import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionScreen({super.key, required this.onPermissionsGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _notificationPermission = false;
  bool _batteryOptimization = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      _notificationPermission = notificationStatus.isGranted;

      // Check battery optimization (Android only)
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // For Android 6.0 and above, check battery optimization
        if (androidInfo.version.sdkInt >= 23) {
          // This is a simplified check - in a real app you might want to
          // use a platform channel to check actual battery optimization status
          _batteryOptimization = true; // Assume enabled by default
        } else {
          _batteryOptimization = true; // Not applicable for older versions
        }
      } else {
        _batteryOptimization = true; // Not applicable for iOS
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }

    setState(() => _isLoading = false);

    // If all permissions are granted, proceed
    if (_notificationPermission && _batteryOptimization) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationPermission = status.isGranted;
    });

    if (_notificationPermission && _batteryOptimization) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestBatteryOptimization() async {
    // This is a placeholder. In a real app, you would:
    // 1. Check if battery optimization is disabled
    // 2. Show a dialog explaining why it's needed
    // 3. Open system settings for the user to disable it

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battery Optimization'),
        content: const Text(
          'To ensure reliable notifications, please disable battery optimization for this app in your device settings.\n\n'
          'This allows the app to run in the background and deliver timely task reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _batteryOptimization = true; // Assume user will do it
              });

              if (_notificationPermission && _batteryOptimization) {
                widget.onPermissionsGranted();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RemindMe needs some permissions to work properly:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Notification Permission
            _buildPermissionCard(
              title: 'Notifications',
              description: 'Allow RemindMe to send you task reminders',
              icon: Icons.notifications,
              isGranted: _notificationPermission,
              onTap: _requestNotificationPermission,
            ),
            const SizedBox(height: 16),

            // Battery Optimization
            if (Platform.isAndroid) ...[
              _buildPermissionCard(
                title: 'Battery Optimization',
                description:
                    'Disable battery optimization to ensure reliable background notifications',
                icon: Icons.battery_saver,
                isGranted: _batteryOptimization,
                onTap: _requestBatteryOptimization,
              ),
              const SizedBox(height: 32),
            ],

            const Spacer(),

            if (_notificationPermission && _batteryOptimization) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All permissions granted! You\'re ready to use RemindMe.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onPermissionsGranted,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(
                isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isGranted ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
