import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../widgets/permission_card.dart';
import '../widgets/feature_card.dart';
import '../widgets/progress_step.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionScreen({super.key, required this.onPermissionsGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  bool _notificationPermission = false;
  bool _batteryOptimization = false;
  bool _isLoading = false;
  String _batteryStatus = 'Unknown';

  // Overlay tutorial state variables
  bool _showOverlay = false;
  bool _hasShownOverlay = false;
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;
  final GlobalKey _notificationCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for overlay
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    );

    _checkPermissions();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
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

    // Show tutorial overlay if notification permission is not granted and hasn't been shown yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialOverlay();
    });
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
          'For reliable notifications, LifeQue needs to run in the background:\n\n'
          '1. Find "LifeQue" in the app list\n'
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
          'Have you disabled battery optimization for LifeQue in your device settings?',
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

  // Tutorial overlay methods
  void _showTutorialOverlay() {
    if (!_hasShownOverlay && !_notificationPermission) {
      setState(() {
        _showOverlay = true;
        _hasShownOverlay = true;
      });
      _overlayController.forward();
    }
  }

  void _hideTutorialOverlay() {
    _overlayController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  Widget _buildTutorialOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark overlay background
            Container(
              color: Colors.black.withOpacity(0.7 * _overlayAnimation.value),
            ),

            // Spotlight effect on notification card
            _buildSpotlight(),

            // Tutorial card with information
            _buildTutorialCard(),
          ],
        );
      },
    );
  }

  Widget _buildSpotlight() {
    // Get the notification card position and size
    final RenderBox? renderBox =
        _notificationCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: SpotlightPainter(
        spotlightRect: Rect.fromLTWH(
          position.dx - 8,
          position.dy - 8,
          size.width + 16,
          size.height + 16,
        ),
        animation: _overlayAnimation.value,
      ),
    );
  }

  Widget _buildTutorialCard() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1,
      left: 24,
      right: 24,
      child: Transform.scale(
        scale: _overlayAnimation.value,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tutorial header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Notifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Never miss important reminders',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tutorial content
                Text(
                  'LifeQue needs notification permission to remind you about:\n\n'
                  '• 📝 Task deadlines and upcoming events\n'
                  '• 💊 Medicine reminders with exact timing\n'
                  '• 🎂 Birthday and anniversary alerts\n'
                  '• ⏰ Prayer times and spiritual reminders\n\n'
                  'Tap the notification card below to enable this feature.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _hideTutorialOverlay,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Maybe Later',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _hideTutorialOverlay();
                          // Automatically scroll to and highlight the notification card
                          Future.delayed(const Duration(milliseconds: 300), () {
                            Scrollable.ensureVisible(
                              _notificationCardKey.currentContext!,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Got It!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                                  'LifeQue',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                              'To ensure you never miss important reminders, LifeQue needs permission to send notifications and run in the background.',
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
                            ProgressStep(
                              stepNumber: 1,
                              title: 'Notifications',
                              isCompleted: _notificationPermission,
                              isActive: !_notificationPermission,
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _notificationPermission
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            ProgressStep(
                              stepNumber: 2,
                              title: Platform.isAndroid ? 'Battery' : 'Ready',
                              isCompleted: _batteryOptimization,
                              isActive:
                                  _notificationPermission &&
                                  !_batteryOptimization,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Permission cards with clearer actions
                      PermissionCard(
                        key: _notificationCardKey,
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
                        PermissionCard(
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
                                    'What LifeQue Can Do',
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
                                  FeatureCard(
                                    icon: Icons.task_alt_rounded,
                                    title: 'Smart Task Management',
                                    description:
                                        'Create, organize, and track your daily tasks with intelligent reminders',
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 8),

                                  FeatureCard(
                                    icon: Icons.medical_services_rounded,
                                    title: 'Medicine Reminders',
                                    description:
                                        'Never miss a dose with customizable medication schedules and tracking',
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 8),

                                  FeatureCard(
                                    icon: Icons.cake_rounded,
                                    title: 'Birthday Reminders',
                                    description:
                                        'Remember important dates and celebrate with your loved ones',
                                    color: Colors.pink,
                                  ),
                                  const SizedBox(height: 8),

                                  FeatureCard(
                                    icon: Icons.access_time_rounded,
                                    title: 'One-time Reminders',
                                    description:
                                        'Set quick reminders for appointments, calls, or any important events',
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 8),

                                  FeatureCard(
                                    icon: Icons.notifications_active_rounded,
                                    title: 'Smart Notifications',
                                    description:
                                        'Interactive notifications with actions - complete, snooze, or view details',
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(height: 8),

                                  FeatureCard(
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
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'LifeQue is ready to help you stay organized',
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ).copyWith(
                                        backgroundColor:
                                            WidgetStateProperty.all(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Start Using LifeQue',
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
          // Tutorial overlay
          if (_showOverlay) _buildTutorialOverlay(),
        ],
      ),
    );
  }
}

// Custom painter for creating spotlight effect
class SpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double animation;

  SpotlightPainter({required this.spotlightRect, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a path for the entire screen
    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create a path for the spotlight area (rounded rectangle)
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(spotlightRect, const Radius.circular(16)),
      );

    // Subtract the spotlight area from the screen
    final combinedPath = Path.combine(
      PathOperation.difference,
      screenPath,
      spotlightPath,
    );

    // Draw the darkened area (everything except the spotlight)
    canvas.drawPath(
      combinedPath,
      Paint()..color = Colors.black.withOpacity(0.7 * animation),
    );

    // Add a subtle glow around the spotlight
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3 * animation)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        spotlightRect.inflate(4),
        const Radius.circular(20),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.animation != animation;
  }
}
