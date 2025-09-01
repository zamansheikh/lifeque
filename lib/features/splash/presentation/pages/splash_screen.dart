import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissionsAndNavigate();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // Wait for animation to complete and give user time to see splash
    await Future.delayed(const Duration(milliseconds: 2000));

    try {
      // Check all required permissions
      bool allPermissionsGranted = await _checkAllPermissions();

      if (mounted) {
        if (allPermissionsGranted) {
          debugPrint('✅ All permissions granted, navigating to home');
          context.go('/');
        } else {
          debugPrint('⚠️ Permissions needed, navigating to permission screen');
          context.go('/permissions');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      // On error, go to permission screen to be safe
      if (mounted) {
        context.go('/permissions');
      }
    }
  }

  Future<bool> _checkAllPermissions() async {
    // Check notification permission
    final notificationStatus = await Permission.notification.status;
    bool notificationGranted = notificationStatus.isGranted;

    // Check battery optimization (Android only)
    bool batteryOptimized = true;
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // For Android 6.0 and above, check battery optimization
        if (androidInfo.version.sdkInt >= 23) {
          final status = await Permission.ignoreBatteryOptimizations.status;
          batteryOptimized = status.isGranted;
        }
      } catch (e) {
        debugPrint('Error checking battery optimization: $e');
        batteryOptimized = false; // Be conservative on error
      }
    }

    debugPrint('🔔 Splash: Notification permission: $notificationGranted');
    debugPrint('🔋 Splash: Battery optimization: $batteryOptimized');

    return notificationGranted && batteryOptimized;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
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
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // App Name
                      Text(
                        'RemindMe',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Tagline
                      Text(
                        'Smart Task & Reminder Manager',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Loading indicator
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Loading text
                      Text(
                        'Checking permissions...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
