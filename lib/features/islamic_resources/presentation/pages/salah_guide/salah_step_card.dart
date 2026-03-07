import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../islamic_resources_page.dart';
import 'salah_step_model.dart';

class SalahStepCard extends StatelessWidget {
  const SalahStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.accentColor,
  });

  final SalahStep step;
  final int stepNumber;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SalahStepDetailPage(step: step)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // step number circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.arabicName,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        color: IslamicColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.englishName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: IslamicColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.shortDesc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: IslamicColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Salah Step Detail Page ───────────────────────────────────────────────────
class SalahStepDetailPage extends StatelessWidget {
  const SalahStepDetailPage({super.key, required this.step});
  final SalahStep step;

  Color get _phaseColor {
    switch (step.phase) {
      case 'before':
        return const Color(0xFF1565C0);
      case 'after':
        return const Color(0xFF6A1B9A);
      default:
        return IslamicColors.deepGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor;

    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, color),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Arabic name card
                _arabicCard(color),
                const SizedBox(height: 14),
                // Description card
                _infoCard(
                  title: 'Description',
                  icon: Icons.info_outline_rounded,
                  color: color,
                  child: Text(
                    step.detailDesc,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.7,
                      color: IslamicColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Key points card
                _infoCard(
                  title: 'Key Points',
                  icon: Icons.checklist_rounded,
                  color: color,
                  child: Column(
                    children: step.keyPoints
                        .map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: IslamicColors.darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (step.duas != null && step.duas!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DuaCarousel(duas: step.duas!, color: color),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Color color) {
    return SliverAppBar(
      title: Text(
        step.englishName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      backgroundColor: color,
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.9), color],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 16),
                child: Icon(
                  step.icon,
                  size: 50,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arabicCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            step.arabicName,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.englishName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: IslamicColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DuaCarousel extends StatefulWidget {
  const _DuaCarousel({required this.duas, required this.color});
  final List<SalahDua> duas;
  final Color color;

  @override
  State<_DuaCarousel> createState() => _DuaCarouselState();
}

class _DuaCarouselState extends State<_DuaCarousel> {
  int _currentIndex = 0;

  void _next() {
    if (_currentIndex < widget.duas.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dua = widget.duas[_currentIndex];
    final hasMultiple = widget.duas.length > 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: IslamicColors.lightGold,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: IslamicColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 16,
                    color: IslamicColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasMultiple
                        ? 'Du\'a / Dhikr  (${_currentIndex + 1}/${widget.duas.length})'
                        : 'Du\'a / Dhikr',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: IslamicColors.gold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: dua.arabic));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied Arabic text')),
                    );
                  },
                  icon: const Icon(
                    Icons.copy,
                    size: 18,
                    color: IslamicColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: IslamicColors.gold, height: 1),

          // Content with swipe + auto-resize
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -100) _next();
              if (details.primaryVelocity! > 100) _prev();
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _DuaContent(key: ValueKey(_currentIndex), dua: dua),
              ),
            ),
          ),

          // Indicators + navigation
          if (hasMultiple) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left arrow
                  GestureDetector(
                    onTap: _prev,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: _currentIndex > 0
                          ? IslamicColors.gold
                          : IslamicColors.gold.withValues(alpha: 0.25),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dots
                  ...List.generate(
                    widget.duas.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == i ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? IslamicColors.gold
                            : IslamicColors.gold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right arrow
                  GestureDetector(
                    onTap: _next,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _currentIndex < widget.duas.length - 1
                          ? IslamicColors.gold
                          : IslamicColors.gold.withValues(alpha: 0.25),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _DuaContent extends StatelessWidget {
  const _DuaContent({super.key, required this.dua});
  final SalahDua dua;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              dua.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 24,
                height: 2.2,
                fontWeight: FontWeight.w600,
                color: IslamicColors.darkText,
              ),
            ),
          ),
          if (dua.transliteration != null) ...[
            const SizedBox(height: 10),
            Text(
              dua.transliteration!,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: IslamicColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
          if (dua.translation != null) ...[
            const SizedBox(height: 8),
            Text(
              '"${dua.translation!}"',
              style: const TextStyle(
                fontSize: 13,
                color: IslamicColors.darkText,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
