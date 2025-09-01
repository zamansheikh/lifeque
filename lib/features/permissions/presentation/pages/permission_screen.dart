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
  String _batteryStatus = 'Unknown';

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
          // Try to check if battery optimization is actually disabled
          // This is a best-effort approach as direct detection is limited
          final status = await Permission.ignoreBatteryOptimizations.status;
          if (status.isGranted) {
            _batteryOptimization = true;
            _batteryStatus = 'Disabled (Good!)';
          } else {
            _batteryOptimization = false;
            _batteryStatus = 'Enabled (Needs Action)';
          }
        } else {
          _batteryOptimization = true; // Not applicable for older versions
          _batteryStatus = 'Not Required';
        }
      } else {
        _batteryOptimization = true; // Not applicable for iOS
        _batteryStatus = 'Not Required';
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      if (Platform.isAndroid) {
        _batteryStatus = 'Check Manually';
      }
    }

    setState(() => _isLoading = false);

    // If all permissions are granted after manual check, proceed
    if (_notificationPermission && _batteryOptimization) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final currentStatus = await Permission.notification.status;

    if (currentStatus.isPermanentlyDenied) {
      // Show dialog to open app settings
      _showSettingsDialog();
      return;
    }

    final status = await Permission.notification.request();
    setState(() {
      _notificationPermission = status.isGranted;
    });

    if (_notificationPermission && _batteryOptimization) {
      widget.onPermissionsGranted();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Open Settings'),
          ],
        ),
        content: const Text(
          'Notification permission was denied. Please enable notifications in your device settings to receive task reminders.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
              // Re-check permissions when user comes back
              await Future.delayed(const Duration(seconds: 1));
              _checkPermissions();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      try {
        // Try to request battery optimization permission first
        final status = await Permission.ignoreBatteryOptimizations.request();

        if (status.isGranted) {
          setState(() {
            _batteryOptimization = true;
            _batteryStatus = 'Disabled (Good!)';
          });

          if (_notificationPermission && _batteryOptimization) {
            widget.onPermissionsGranted();
          }
          return;
        }

        // If not granted, show guidance dialog
        _showBatteryOptimizationDialog();
      } catch (e) {
        debugPrint('Error with battery optimization: $e');
        _showBatteryOptimizationDialog();
      }
    }
  }

  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.battery_saver,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Battery Optimization'),
          ],
        ),
        content: const Text(
          'For reliable notifications, RemindMe needs to run in the background:\n\n'
          '1. Find "RemindMe" in the app list\n'
          '2. Select "Don\'t optimize" or "Allow"\n'
          '3. Confirm your choice\n\n'
          'This ensures you never miss important reminders!',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Try to open battery optimization settings
              try {
                await openAppSettings();
              } catch (e) {
                debugPrint('Could not open app settings: $e');
              }

              // Show confirmation dialog after delay
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                _showBatteryOptimizationConfirmation();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showBatteryOptimizationConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Did you disable battery optimization?'),
        content: const Text(
          'Have you disabled battery optimization for RemindMe in your device settings?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Don't change the state, keep showing as not optimized
            },
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Recheck permissions to get updated status
              _checkPermissions();
            },
            child: const Text('Yes, Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with App Name and Logo
                  Row(
                    children: [
                      // App Logo
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback icon if image fails to load
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RemindMe',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Smart Task & Reminder Manager',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Welcome message with clearer explanation
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.purple.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Setup Required',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Just 2 simple steps',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'To ensure you never miss important reminders, RemindMe needs permission to send notifications and run in the background.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue.shade600,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap the buttons below to grant permissions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Progress circles
                        _buildProgressStep(
                          stepNumber: 1,
                          title: 'Notifications',
                          isCompleted: _notificationPermission,
                          isActive: !_notificationPermission,
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: _notificationPermission
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        _buildProgressStep(
                          stepNumber: 2,
                          title: Platform.isAndroid ? 'Battery' : 'Ready',
                          isCompleted: _batteryOptimization,
                          isActive:
                              _notificationPermission && !_batteryOptimization,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Permission cards with clearer actions
                  _buildPermissionCard(
                    title: 'Notifications',
                    description:
                        'Get timely alerts for your tasks, medicine reminders, and important events',
                    icon: Icons.notifications_rounded,
                    isGranted: _notificationPermission,
                    onTap: _requestNotificationPermission,
                    color: Colors.blue,
                    actionText: _notificationPermission
                        ? 'Granted'
                        : 'Enable Now',
                  ),
                  const SizedBox(height: 16),

                  // Battery Optimization (Android only)
                  if (Platform.isAndroid) ...[
                    _buildPermissionCard(
                      title: 'Battery Optimization',
                      description:
                          'Prevent system from stopping notifications in the background\nStatus: $_batteryStatus',
                      icon: Icons.battery_saver_rounded,
                      isGranted: _batteryOptimization,
                      onTap: _requestBatteryOptimization,
                      color: Colors.orange,
                      actionText: _batteryOptimization
                          ? 'Optimized'
                          : 'Fix Now',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // App Features Showcase
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple.shade400,
                                      Colors.pink.shade400,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'What RemindMe Can Do',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          child: Column(
                            children: [
                              _buildFeatureCard(
                                icon: Icons.task_alt_rounded,
                                title: 'Smart Task Management',
                                description:
                                    'Create, organize, and track your daily tasks with intelligent reminders',
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 8),

                              _buildFeatureCard(
                                icon: Icons.medical_services_rounded,
                                title: 'Medicine Reminders',
                                description:
                                    'Never miss a dose with customizable medication schedules and tracking',
                                color: Colors.green,
                              ),
                              const SizedBox(height: 8),

                              _buildFeatureCard(
                                icon: Icons.cake_rounded,
                                title: 'Birthday Reminders',
                                description:
                                    'Remember important dates and celebrate with your loved ones',
                                color: Colors.pink,
                              ),
                              const SizedBox(height: 8),

                              _buildFeatureCard(
                                icon: Icons.access_time_rounded,
                                title: 'One-time Reminders',
                                description:
                                    'Set quick reminders for appointments, calls, or any important events',
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 8),

                              _buildFeatureCard(
                                icon: Icons.notifications_active_rounded,
                                title: 'Smart Notifications',
                                description:
                                    'Interactive notifications with actions - complete, snooze, or view details',
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 8),

                              _buildFeatureCard(
                                icon: Icons.push_pin_rounded,
                                title: 'Pinned Reminders',
                                description:
                                    'Keep important tasks always visible in your notification panel',
                                color: Colors.indigo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Success message and continue button
                  if (_notificationPermission && _batteryOptimization) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perfect! You\'re All Set',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'RemindMe is ready to help you stay organized',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onPermissionsGranted,
                              style:
                                  ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ).copyWith(
                                    backgroundColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                  ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Using RemindMe',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required int stepNumber,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                ? Colors.blue
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isCompleted
                ? Colors.green
                : isActive
                ? Colors.blue
                : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
    required Color color,
    required String actionText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.shade200
              : color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? Colors.green.shade100
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle_rounded : icon,
                    color: isGranted ? Colors.green : color,
                    size: 24,
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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action button (only show if not granted)
          if (!isGranted) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: color.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          actionText,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Success indicator for granted permissions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(
                  top: BorderSide(color: Colors.green.shade200, width: 1),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    actionText,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
