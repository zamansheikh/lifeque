import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/navigation_preferences_service.dart';
import '../../../../injection_container.dart' as di;

// ─── Brand palette (matches the app's blue seed) ─────────────────────────────
const _kPrimary = Color(0xFF2563EB);
const _kPrimaryLight = Color(0xFF60A5FA);
const _kAccent = Color(0xFF06B6D4);

// ─── Slide data ──────────────────────────────────────────────────────────────

class _Slide {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final List<_FeatureChip> chips;

  const _Slide({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.chips,
  });
}

class _FeatureChip {
  final IconData icon;
  final String label;
  const _FeatureChip(this.icon, this.label);
}

const _slides = [
  _Slide(
    title: 'Welcome to\nLifeQue',
    subtitle:
        'Your all-in-one personal life manager.\nOrganise, track, and never miss a thing.',
    heroIcon: Icons.auto_awesome_rounded,
    chips: [
      _FeatureChip(Icons.task_alt_rounded, 'Tasks'),
      _FeatureChip(Icons.checklist_rounded, 'To Do List'),
      _FeatureChip(Icons.account_balance_wallet_rounded, 'Expenses'),
      _FeatureChip(Icons.medication_rounded, 'Medicines'),
      _FeatureChip(Icons.mosque_rounded, 'Prayer'),
      _FeatureChip(Icons.timer_rounded, 'Study'),
    ],
  ),
  _Slide(
    title: 'Stay\nOrganised',
    subtitle:
        'Create tasks with priorities, deadlines,\nand recurring reminders in seconds.',
    heroIcon: Icons.task_alt_rounded,
    chips: [
      _FeatureChip(Icons.flag_rounded, 'Priorities'),
      _FeatureChip(Icons.repeat_rounded, 'Recurring'),
      _FeatureChip(Icons.cake_rounded, 'Birthdays'),
      _FeatureChip(Icons.notifications_active_rounded, 'Reminders'),
    ],
  ),
  _Slide(
    title: 'Track\nEverything',
    subtitle:
        'Budget your money, log expenses,\nand manage your medications effortlessly.',
    heroIcon: Icons.insights_rounded,
    chips: [
      _FeatureChip(Icons.pie_chart_rounded, 'Budgets'),
      _FeatureChip(Icons.receipt_long_rounded, 'Expenses'),
      _FeatureChip(Icons.medication_rounded, 'Med Reminders'),
      _FeatureChip(Icons.bar_chart_rounded, 'Analytics'),
    ],
  ),
  _Slide(
    title: 'Powerful\nTools',
    subtitle:
        'Accurate prayer times, Pomodoro study timer,\nand a fully customisable home screen.',
    heroIcon: Icons.bolt_rounded,
    chips: [
      _FeatureChip(Icons.mosque_rounded, 'Prayer Times'),
      _FeatureChip(Icons.explore_rounded, 'Qibla'),
      _FeatureChip(Icons.timer_rounded, 'Pomodoro'),
      _FeatureChip(Icons.dashboard_customize_rounded, 'Customise'),
    ],
  ),
];

// ─── Page ────────────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _page = 0;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final svc = NavigationPreferencesService(di.sl<SharedPreferences>());
    await svc.markOnboardingDone();
    if (!mounted) return;
    // Navigate to permission screen after onboarding (not directly home)
    context.go('/permissions');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
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

          // Decorative circles (subtle)
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

          // Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _heroController
                ..reset()
                ..forward();
            },
            itemBuilder: (_, i) => _SlideContent(
              slide: _slides[i],
              heroAnimation: _heroController,
              isFirst: i == 0,
            ),
          ),

          // Skip
          if (_page < _slides.length - 1)
            Positioned(
              top: mq.padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimary,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, mq.padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _kPrimary
                              : _kPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: _kPrimary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _page == _slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (_page < _slides.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide content ───────────────────────────────────────────────────────────

class _SlideContent extends StatelessWidget {
  final _Slide slide;
  final Animation<double> heroAnimation;
  final bool isFirst;

  const _SlideContent({
    required this.slide,
    required this.heroAnimation,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(
      parent: heroAnimation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    final slideUp =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: heroAnimation,
            curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 180),
        child: SlideTransition(
          position: slideUp,
          child: FadeTransition(
            opacity: fadeIn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Hero circle with logo / icon
                Center(
                  child: _HeroBubble(icon: slide.heroIcon, showLogo: isFirst),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  slide.title,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 14),

                // Subtitle
                Text(
                  slide.subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 28),

                // Feature chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slide.chips
                      .map((c) => _FeatureTag(chip: c))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero bubble ─────────────────────────────────────────────────────────────

class _HeroBubble extends StatelessWidget {
  final IconData icon;
  final bool showLogo;

  const _HeroBubble({required this.icon, required this.showLogo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: showLogo
          ? Padding(
              padding: const EdgeInsets.all(28),
              child: ClipOval(
                child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                ),
                Icon(icon, color: Colors.white, size: 52),
              ],
            ),
    );
  }
}

// ─── Feature tag chip ────────────────────────────────────────────────────────

class _FeatureTag extends StatelessWidget {
  final _FeatureChip chip;
  const _FeatureTag({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            chip.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glow circle decoration ─────────────────────────────────────────────────

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
