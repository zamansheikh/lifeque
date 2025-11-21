import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:math' as math;
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
  bool _hasShownBatteryOverlay = false;
  String _currentOverlayType = ''; // 'notification' or 'battery'
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;
  final GlobalKey _notificationCardKey = GlobalKey();
  final GlobalKey _batteryCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for overlay
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    } else if (_notificationPermission && !_batteryOptimization) {
      // If notification granted but battery not, move to next step
      _hideTutorialOverlay();
      // Wait for hide animation then show next overlay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _showTutorialOverlay();
        }
      });
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
    // Show notification overlay first if not granted and not shown
    if (!_hasShownOverlay && !_notificationPermission) {
      setState(() {
        _showOverlay = true;
        _hasShownOverlay = true;
        _currentOverlayType = 'notification';
      });
      _overlayController.forward();
    }
    // Show battery overlay if notification is granted but battery isn't
    else if (!_hasShownBatteryOverlay &&
        _notificationPermission &&
        !_batteryOptimization) {
      setState(() {
        _showOverlay = true;
        _hasShownBatteryOverlay = true;
        _currentOverlayType = 'battery';
      });
      _overlayController.forward();
    }
  }

  void _hideTutorialOverlay() {
    _overlayController.stop();
    setState(() {
      _showOverlay = false;
    });

    // Check if we should show the next overlay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_currentOverlayType == 'notification' &&
          !_hasShownBatteryOverlay &&
          !_batteryOptimization) {
        _showTutorialOverlay(); // This will show battery overlay
      }
    });
  }

  Widget _buildTutorialOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Animated gradient background with particles effect
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5 * _overlayAnimation.value,
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.4 * _overlayAnimation.value,
                    ),
                    Colors.black.withValues(
                      alpha: 0.8 * _overlayAnimation.value,
                    ),
                    Colors.black.withValues(
                      alpha: 0.95 * _overlayAnimation.value,
                    ),
                  ],
                ),
              ),
            ),

            // Floating particles effect
            ..._buildFloatingParticles(),

            // Enhanced spotlight effect with integrated instructions
            _buildEnhancedSpotlight(),
          ],
        );
      },
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(20, (index) {
      final random = (index * 17) % 100;
      final x = (random / 100) * MediaQuery.of(context).size.width;
      final y =
          (((index * 23) % 100) / 100) * MediaQuery.of(context).size.height;
      final delay = (index * 0.1) % 1.0;

      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _overlayAnimation,
          builder: (context, child) {
            final animationValue = (_overlayAnimation.value + delay) % 1.0;
            return Transform.translate(
              offset: Offset(
                math.sin(animationValue * 2 * math.pi) * 20,
                animationValue * -50,
              ),
              child: Opacity(
                opacity:
                    (0.3 *
                            _overlayAnimation.value *
                            math.sin(animationValue * math.pi))
                        .abs(),
                child: Container(
                  width: 4 + (random % 3),
                  height: 4 + (random % 3),
                  decoration: BoxDecoration(
                    color: _currentOverlayType == 'notification'
                        ? Colors.blue.withValues(alpha: 0.6)
                        : Colors.green.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _currentOverlayType == 'notification'
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEnhancedSpotlight() {
    // Get the target card based on overlay type
    final GlobalKey targetKey = _currentOverlayType == 'notification'
        ? _notificationCardKey
        : _batteryCardKey;

    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    // Use a static value instead of pulsing animation for better usability
    final pulseValue = 1.0;

    return Stack(
      children: [
        // Multiple layered spotlight effects
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: EnhancedSpotlightPainter(
            spotlightRect: Rect.fromLTWH(
              position.dx - 12,
              position.dy - 12,
              size.width + 24,
              size.height + 24,
            ),
            animation: _overlayAnimation.value,
            pulseValue: pulseValue,
            color: _currentOverlayType == 'notification'
                ? Colors.blue
                : Colors.green,
          ),
        ),

        // Speech bubble instruction with smart positioning
        Positioned(
          left: position.dx + 20,
          top: _getSpeechBubbleTop(position, size),
          width: size.width - 40,
          child: Column(
            children: [
              // Custom speech bubble with tail
              CustomPaint(
                painter: SpeechBubblePainter(
                  color: _currentOverlayType == 'notification'
                      ? Colors.blue
                      : Colors.green,
                  pointUp: _shouldBubblePointUp(position, size),
                ),
                child: Container(
                  width: size.width - 40,
                  padding: _shouldBubblePointUp(position, size)
                      ? const EdgeInsets.fromLTRB(20, 20, 20, 25)
                      : const EdgeInsets.fromLTRB(20, 25, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentOverlayType == 'notification'
                                ? Icons.notifications_active
                                : Icons.battery_saver,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentOverlayType == 'notification'
                                  ? 'Enable Notifications'
                                  : 'Battery Optimization',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _hideTutorialOverlay,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentOverlayType == 'notification'
                            ? 'To enable battery optimization need to click here, here is some extra information why need.'
                            : 'To enable battery optimization need to click here, here is some extra information why need.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for smart speech bubble positioning
  bool _shouldBubblePointUp(Offset position, Size size) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bubbleHeight = 120.0; // Estimated height of speech bubble
    final cardBottom = position.dy + size.height;

    // If there's not enough space below the card, position bubble above
    return (cardBottom + bubbleHeight + 50) > screenHeight;
  }

  double _getSpeechBubbleTop(Offset position, Size size) {
    if (_shouldBubblePointUp(position, size)) {
      // Position above the card
      return position.dy - 135; // Bubble height + spacing
    } else {
      // Position below the card
      return position.dy + size.height + 15;
    }
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
                          key: _batteryCardKey,
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
      Paint()..color = Colors.black.withValues(alpha: 0.7 * animation),
    );

    // Add a subtle glow around the spotlight
    final glowPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3 * animation)
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

// Enhanced spotlight painter with pulsing effects
class EnhancedSpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double animation;
  final double pulseValue;
  final Color color;

  EnhancedSpotlightPainter({
    required this.spotlightRect,
    required this.animation,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a path for the entire screen
    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create animated spotlight area with pulsing effect
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          spotlightRect.inflate(pulseValue * 5),
          const Radius.circular(20),
        ),
      );

    // Subtract the spotlight area from the screen
    final combinedPath = Path.combine(
      PathOperation.difference,
      screenPath,
      spotlightPath,
    );

    // Draw the darkened area with animated gradient
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        Colors.black.withValues(alpha: 0.3 * animation),
        Colors.black.withValues(alpha: 0.7 * animation),
        Colors.black.withValues(alpha: 0.95 * animation),
      ],
    );

    canvas.drawPath(
      combinedPath,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Multiple glow layers for enhanced effect
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: (0.4 * animation) / i)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15.0 * i);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          spotlightRect.inflate(8 + (pulseValue * 5) + (i * 3)),
          const Radius.circular(25),
        ),
        glowPaint,
      );
    }

    // Inner highlight ring
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.6 * animation)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        spotlightRect.inflate(2 + pulseValue * 2),
        const Radius.circular(18),
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(EnhancedSpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.animation != animation ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.color != color;
  }
}

// Pattern painter for animated background effects
class PatternPainter extends CustomPainter {
  final double animation;
  final Color color;

  PatternPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05 * animation)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Create animated geometric pattern
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = math.max(size.width, size.height) / 2;

    // Draw animated circles
    for (int i = 1; i <= 5; i++) {
      final radius = (maxRadius / 5 * i) * (0.5 + animation * 0.5);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }

    // Draw animated grid lines
    final gridSize = 30.0;
    final offset = (animation * gridSize) % gridSize;

    for (double x = -offset; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = -offset; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final bool pointUp;

  SpeechBubblePainter({required this.color, this.pointUp = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final shadowPath = Path();

    const radius = 15.0;
    const tailHeight = 15.0;
    const tailWidth = 25.0;
    final tailStartX = size.width * 0.2; // Position the tail towards the left

    if (pointUp) {
      // Create speech bubble with tail pointing down (bubble above card)
      // Start from bottom-left corner (after the tail)
      path.moveTo(radius, size.height - tailHeight);

      // Bottom edge (with space for tail)
      path.lineTo(tailStartX - tailWidth / 2, size.height - tailHeight);

      // Create the tail pointing downward
      path.lineTo(tailStartX, size.height); // Tip of the tail
      path.lineTo(tailStartX + tailWidth / 2, size.height - tailHeight);

      // Continue bottom edge
      path.lineTo(size.width - radius, size.height - tailHeight);

      // Bottom-right corner
      path.arcToPoint(
        Offset(size.width, size.height - tailHeight - radius),
        radius: const Radius.circular(radius),
      );

      // Right edge
      path.lineTo(size.width, radius);

      // Top-right corner
      path.arcToPoint(
        Offset(size.width - radius, 0),
        radius: const Radius.circular(radius),
      );

      // Top edge
      path.lineTo(radius, 0);

      // Top-left corner
      path.arcToPoint(Offset(0, radius), radius: const Radius.circular(radius));

      // Left edge
      path.lineTo(0, size.height - tailHeight - radius);

      // Bottom-left corner
      path.arcToPoint(
        Offset(radius, size.height - tailHeight),
        radius: const Radius.circular(radius),
      );
    } else {
      // Create speech bubble with tail pointing up (bubble below card) - original logic
      // Start from top-left corner (after the tail)
      path.moveTo(radius, tailHeight);

      // Top edge (with space for tail)
      path.lineTo(tailStartX - tailWidth / 2, tailHeight);

      // Create the tail pointing upward
      path.lineTo(tailStartX, 0); // Tip of the tail
      path.lineTo(tailStartX + tailWidth / 2, tailHeight);

      // Continue top edge
      path.lineTo(size.width - radius, tailHeight);

      // Top-right corner
      path.arcToPoint(
        Offset(size.width, tailHeight + radius),
        radius: const Radius.circular(radius),
      );

      // Right edge
      path.lineTo(size.width, size.height - radius);

      // Bottom-right corner
      path.arcToPoint(
        Offset(size.width - radius, size.height),
        radius: const Radius.circular(radius),
      );

      // Bottom edge
      path.lineTo(radius, size.height);

      // Bottom-left corner
      path.arcToPoint(
        Offset(0, size.height - radius),
        radius: const Radius.circular(radius),
      );

      // Left edge
      path.lineTo(0, tailHeight + radius);

      // Top-left corner
      path.arcToPoint(
        Offset(radius, tailHeight),
        radius: const Radius.circular(radius),
      );
    }

    path.close();

    // Create shadow path (slightly offset)
    shadowPath.addPath(path, const Offset(0, 3));

    // Draw shadow first
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw the main bubble
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SpeechBubblePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointUp != pointUp;
  }
}
