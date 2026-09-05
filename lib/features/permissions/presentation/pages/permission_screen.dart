import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Brand palette (matches onboarding) ────────────────────────────────────
const _kPrimary = Color(0xFF2563EB);
const _kPrimaryLight = Color(0xFF60A5FA);
const _kAccent = Color(0xFF06B6D4);

// ─── Step data ──────────────────────────────────────────────────────────────

class _PermStep {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final Color heroColor;
  final List<_Benefit> benefits;
  final String ctaLabel;

  const _PermStep({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.heroColor,
    required this.benefits,
    required this.ctaLabel,
  });
}

class _Benefit {
  final IconData icon;
  final String text;
  const _Benefit(this.icon, this.text);
}

const _notificationStep = _PermStep(
  title: 'Never Miss a\nReminder',
  subtitle:
      'LifeQue keeps you on track with timely alerts\nfor tasks, medicines, prayers & more.',
  heroIcon: Icons.notifications_active_rounded,
  heroColor: _kPrimary,
  benefits: [
    _Benefit(Icons.alarm_rounded, 'Task & deadline reminders'),
    _Benefit(Icons.medication_rounded, 'Medicine schedules on time'),
    _Benefit(Icons.mosque_rounded, 'Prayer time notifications'),
    _Benefit(Icons.cake_rounded, 'Birthday & event alerts'),
  ],
  ctaLabel: 'Enable Notifications',
);

const _batteryStep = _PermStep(
  title: 'Keep Reminders\nAlive',
  subtitle:
      'Android may stop background apps to save battery.\nAllow LifeQue to run so nothing slips through.',
  heroIcon: Icons.battery_charging_full_rounded,
  heroColor: Color(0xFF16A34A),
  benefits: [
    _Benefit(Icons.timer_off_rounded, 'Prevent missed reminders'),
    _Benefit(Icons.sync_rounded, 'Syncs prayer times silently'),
    _Benefit(Icons.bolt_rounded, 'Minimal battery impact'),
    _Benefit(Icons.verified_rounded, 'Recommended by Android'),
  ],
  ctaLabel: 'Allow Background Activity',
);

// ─── Page ────────────────────────────────────────────────────────────────────

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;
  const PermissionScreen({super.key, required this.onPermissionsGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _notificationGranted = false;
  bool _batteryGranted = false;
  bool _loading = true;
  bool _needsBattery = true;

  late final AnimationController _bgController;
  late final AnimationController _heroController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _init();
  }

  Future<void> _init() async {
    final notif = await Permission.notification.status;
    _notificationGranted = notif.isGranted;

    if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        if (info.version.sdkInt >= 23) {
          final bat = await Permission.ignoreBatteryOptimizations.status;
          _batteryGranted = bat.isGranted;
        } else {
          _batteryGranted = true;
          _needsBattery = false;
        }
      } catch (_) {
        _batteryGranted = false;
      }
    } else {
      _batteryGranted = true;
      _needsBattery = false;
    }

    setState(() => _loading = false);

    if (_allGranted) {
      widget.onPermissionsGranted();
      return;
    }

    // Skip to battery step if notification already granted
    if (_notificationGranted && _needsBattery && !_batteryGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToPage(1);
      });
    }
  }

  bool get _allGranted =>
      _notificationGranted && (_batteryGranted || !_needsBattery);

  int get _totalSteps => _needsBattery ? 3 : 2;

  void _goToPage(int p) {
    _pageController.animateToPage(
      p,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestNotification() async {
    final current = await Permission.notification.status;
    if (current.isPermanentlyDenied) {
      _showOpenSettingsDialog(
        'Notification permission was denied. Please enable notifications in your device settings.',
      );
      return;
    }

    final status = await Permission.notification.request();
    setState(() => _notificationGranted = status.isGranted);

    if (_notificationGranted) {
      if (_needsBattery && !_batteryGranted) {
        _goToPage(1);
      } else {
        _goToPage(_totalSteps - 1);
      }
    }
  }

  Future<void> _requestBattery() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (status.isGranted) {
        setState(() => _batteryGranted = true);
        _goToPage(_totalSteps - 1);
        return;
      }
      _showBatteryDialog();
    } catch (_) {
      _showBatteryDialog();
    }
  }

  void _skipStep() {
    if (_page == 0 && _needsBattery) {
      _goToPage(1);
    } else {
      _goToPage(_totalSteps - 1);
    }
  }

  void _showOpenSettingsDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: _kPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Open Settings'),
          ],
        ),
        content: Text(msg, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) _recheckAll();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showBatteryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                Icons.battery_saver_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Battery Optimization')),
          ],
        ),
        content: const Text(
          'For reliable reminders:\n\n'
          '1. Find "LifeQue" in the list\n'
          '2. Select "Don\'t optimize"\n'
          '3. Confirm your choice\n\n'
          'This uses minimal battery.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) _recheckAll();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _recheckAll() async {
    final notif = await Permission.notification.status;
    _notificationGranted = notif.isGranted;
    if (Platform.isAndroid && _needsBattery) {
      final bat = await Permission.ignoreBatteryOptimizations.status;
      _batteryGranted = bat.isGranted;
    }
    setState(() {});
    if (_allGranted) {
      _goToPage(_totalSteps - 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    final mq = MediaQuery.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient BG (matches onboarding) ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(t * 2 * math.pi) * 0.6,
                      math.sin(t * 2 * math.pi) * 0.6,
                    ),
                    end: Alignment(
                      math.cos((t + 0.5) * 2 * math.pi) * 0.6,
                      math.sin((t + 0.5) * 2 * math.pi) * 0.6,
                    ),
                    colors: const [
                      Color(0xFFE0EFFE),
                      Color(0xFFF0F4FF),
                      Color(0xFFE8F4FD),
                      Color(0xFFF8FAFC),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Decorative blobs ──
          Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(
              size: 220,
              color: _kPrimaryLight.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: _GlowCircle(
              size: 180,
              color: _kAccent.withValues(alpha: 0.10),
            ),
          ),

          // ── Pages ──
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _page = i);
              _heroController
                ..reset()
                ..forward();
            },
            children: [
              _PermStepView(
                step: _notificationStep,
                heroAnimation: _heroController,
                isGranted: _notificationGranted,
                onRequest: _requestNotification,
                onSkip: _skipStep,
              ),
              if (_needsBattery)
                _PermStepView(
                  step: _batteryStep,
                  heroAnimation: _heroController,
                  isGranted: _batteryGranted,
                  onRequest: _requestBattery,
                  onSkip: _skipStep,
                ),
              _CelebrationView(
                heroAnimation: _heroController,
                allGranted: _allGranted,
                notificationGranted: _notificationGranted,
                onContinue: widget.onPermissionsGranted,
              ),
            ],
          ),

          // ── Bottom dots ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, mq.padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8FAFC).withValues(alpha: 0),
                    const Color(0xFFF8FAFC).withValues(alpha: 0.9),
                    const Color(0xFFF8FAFC),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalSteps,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _page == i
                          ? _kPrimary
                          : _kPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Step view ────────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _PermStepView extends StatelessWidget {
  final _PermStep step;
  final AnimationController heroAnimation;
  final bool isGranted;
  final VoidCallback onRequest;
  final VoidCallback onSkip;

  const _PermStepView({
    required this.step,
    required this.heroAnimation,
    required this.isGranted,
    required this.onRequest,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 80),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // ── Hero bubble ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final slide = CurvedAnimation(
                  parent: heroAnimation,
                  curve: Curves.easeOutBack,
                ).value;
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - slide)),
                  child: Opacity(
                    opacity: slide.clamp(0.0, 1.0),
                    child: _HeroBubble(
                      icon: step.heroIcon,
                      color: step.heroColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Title ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
                ).value;
                return Transform.translate(
                  offset: Offset(0, 24 * (1 - t)),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Subtitle ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.25, 0.8, curve: Curves.easeOut),
                ).value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Text(
                    step.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Benefit rows ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.35, 0.9, curve: Curves.easeOut),
                ).value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - t)),
                    child: Column(
                      children: step.benefits
                          .map(
                            (b) =>
                                _BenefitRow(benefit: b, color: step.heroColor),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),

            const Spacer(flex: 2),

            // ── CTA ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                ).value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: isGranted
                            ? GestureDetector(
                                onTap: onSkip,
                                child: const _GrantedButton(),
                              )
                            : FilledButton.icon(
                                onPressed: onRequest,
                                icon: Icon(step.heroIcon, size: 20),
                                label: Text(
                                  step.ctaLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: step.heroColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                      ),
                      if (!isGranted) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Maybe later',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Celebration view ─────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _CelebrationView extends StatelessWidget {
  final AnimationController heroAnimation;
  final bool allGranted;
  final bool notificationGranted;
  final VoidCallback onContinue;

  const _CelebrationView({
    required this.heroAnimation,
    required this.allGranted,
    required this.notificationGranted,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 80),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Hero check ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final scale = CurvedAnimation(
                  parent: heroAnimation,
                  curve: Curves.elasticOut,
                ).value;
                return Transform.scale(
                  scale: 0.5 + (scale * 0.5),
                  child: Opacity(
                    opacity: scale.clamp(0.0, 1.0),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            // ── Title + subtitle ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                ).value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      Text(
                        allGranted ? "You're All Set!" : 'Almost There!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        allGranted
                            ? 'LifeQue is ready to help you stay\norganised and never miss a thing.'
                            : 'You can always enable missing\npermissions later in Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Status summary ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                ).value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _StatusRow(
                          icon: Icons.notifications_active_rounded,
                          label: 'Notifications',
                          granted: notificationGranted,
                        ),
                        const SizedBox(height: 12),
                        if (Platform.isAndroid)
                          _StatusRow(
                            icon: Icons.battery_charging_full_rounded,
                            label: 'Background Activity',
                            granted: allGranted,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(flex: 3),

            // ── Continue ──
            AnimatedBuilder(
              animation: heroAnimation,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: heroAnimation,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                ).value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'Start Using LifeQue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Shared small widgets ─────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _HeroBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _HeroBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 54, color: Colors.white),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final _Benefit benefit;
  final Color color;
  const _BenefitRow({required this.benefit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(benefit.icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              benefit.text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrantedButton extends StatelessWidget {
  const _GrantedButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22),
          SizedBox(width: 10),
          Text(
            'Already Enabled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool granted;
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: granted ? const Color(0xFF22C55E) : Colors.grey.shade400,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: granted ? const Color(0xFF1E293B) : Colors.grey.shade500,
            ),
          ),
        ),
        Icon(
          granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 22,
          color: granted ? const Color(0xFF22C55E) : Colors.grey.shade300,
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
