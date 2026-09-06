import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../islamic_resources_page.dart';
import 'salah_step_model.dart';
import '../../../../../core/utils/local_numbers.dart';
import '../../../../../l10n/app_localizations.dart';

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
                    N.of(stepNumber),
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
                      step.name.of(context),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: IslamicColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.shortDesc.of(context),
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
                _arabicCard(context, color),
                const SizedBox(height: 14),
                // Description card
                _infoCard(
                  title: L.of(context).guideDescription,
                  icon: Icons.info_outline_rounded,
                  color: color,
                  child: Text(
                    step.detailDesc.of(context),
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
                  title: L.of(context).guideKeyPoints,
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
                                    point.of(context),
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
        step.name.of(context),
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

  Widget _arabicCard(BuildContext context, Color color) {
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
            step.name.of(context),
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
  final PageController _controller = PageController();

  /// Fractional scroll position, so the card can grow toward the next du'a
  /// while the finger is still moving rather than snapping at the end.
  double _page = 0;

  /// Natural height of each du'a, filled in as the pages get laid out. A
  /// PageView hands its children a fixed height, so the only way to size the
  /// card to the du'a on screen is to measure them.
  late final List<double?> _heights = List<double?>.filled(
    widget.duas.length,
    null,
  );

  /// Until the first page reports its height there is nothing to size the
  /// PageView to, so the first du'a is rendered on its own.
  bool _sized = false;

  int get _currentIndex => _page.round().clamp(0, widget.duas.length - 1);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final page = _controller.page;
    if (page != null && page != _page) setState(() => _page = page);
  }

  void _report(int index, double height) {
    if (_heights[index] == height) return;
    setState(() {
      _heights[index] = height;
      _sized = true;
    });
  }

  /// Height between the two pages the view is currently straddling.
  double get _height {
    final last = widget.duas.length - 1;
    final low = _page.floor().clamp(0, last);
    final high = _page.ceil().clamp(0, last);
    final from = _heights[low] ?? _heights[_currentIndex] ?? 0;
    final to = _heights[high] ?? from;
    return from + (to - from) * (_page - low);
  }

  void _goTo(int index) => _controller.animateToPage(
    index,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  void _next() {
    if (_currentIndex < widget.duas.length - 1) _goTo(_currentIndex + 1);
  }

  void _prev() {
    if (_currentIndex > 0) _goTo(_currentIndex - 1);
  }

  Widget _page0(int index) => _MeasureHeight(
    onChange: (height) => _report(index, height),
    child: _DuaContent(dua: widget.duas[index]),
  );

  @override
  Widget build(BuildContext context) {
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
                        ? L
                              .of(context)
                              .guideDuaDhikrCount(
                                _currentIndex + 1,
                                widget.duas.length,
                              )
                        : L.of(context).guideDuaDhikr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: IslamicColors.gold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.duas[_currentIndex].arabic),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(L.of(context).guideCopiedArabic)),
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

          // The du'as themselves, as a carousel the finger can drag.
          if (!_sized)
            _page0(0)
          else
            SizedBox(
              height: _height,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.duas.length,
                itemBuilder: (context, index) => SingleChildScrollView(
                  // Gives the page unbounded height so it lays out at its
                  // natural size and can be measured; the PageView never
                  // scrolls it, the outer box is sized to fit.
                  physics: const NeverScrollableScrollPhysics(),
                  child: _page0(index),
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

/// Reports its child's laid-out height once per layout.
class _MeasureHeight extends StatefulWidget {
  const _MeasureHeight({required this.child, required this.onChange});

  final Widget child;
  final ValueChanged<double> onChange;

  @override
  State<_MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<_MeasureHeight> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _measureAfterLayout();
  }

  @override
  void didUpdateWidget(_MeasureHeight old) {
    super.didUpdateWidget(old);
    _measureAfterLayout();
  }

  void _measureAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) widget.onChange(box.size.height);
    });
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(key: _key, width: double.infinity, child: widget.child);
}

class _DuaContent extends StatelessWidget {
  const _DuaContent({required this.dua});
  final SalahDua dua;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dua.label != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: IslamicColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dua.label!.of(context),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: IslamicColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
              dua.transliteration!.of(context),
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
              '"${dua.translation!.of(context)}"',
              style: const TextStyle(
                fontSize: 13,
                color: IslamicColors.darkText,
                height: 1.5,
              ),
            ),
          ],
          if (dua.source != null) ...[
            const SizedBox(height: 8),
            Text(
              '— ${dua.source!.of(context)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: IslamicColors.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
