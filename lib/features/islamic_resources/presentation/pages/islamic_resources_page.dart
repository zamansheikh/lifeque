import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'salah_info_page.dart';
import 'waqt_rakah_page.dart';
import 'necessary_surahs_page.dart';
import 'duas_azkar_page.dart';

// ─── Islamic colour palette (shared across all sub-pages) ────────────────────
class IslamicColors {
  static const deepGreen = Color(0xFF1A6B3C);
  static const mediumGreen = Color(0xFF2E8B57);
  static const lightGreen = Color(0xFFE8F5EE);
  static const gold = Color(0xFFC9A84C);
  static const lightGold = Color(0xFFFDF3DC);
  static const cream = Color(0xFFF8F4ED);
  static const darkText = Color(0xFF1A2130);
  static const mutedText = Color(0xFF6B7280);
  static const cardBg = Colors.white;
}

// ─── category model ───────────────────────────────────────────────────────────
class _ResourceCategory {
  final String title;
  final String subtitle;
  final String arabicTitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Widget page;

  const _ResourceCategory({
    required this.title,
    required this.subtitle,
    required this.arabicTitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.page,
  });
}

// ─── main page ────────────────────────────────────────────────────────────────
class IslamicResourcesPage extends StatelessWidget {
  const IslamicResourcesPage({super.key});

  static final List<_ResourceCategory> _categories = [
    _ResourceCategory(
      title: 'Salah Guide',
      arabicTitle: 'دليل الصلاة',
      subtitle: 'Step-by-step prayer instructions',
      icon: Icons.self_improvement_rounded,
      iconBg: Color(0xFFE8F5EE),
      iconColor: IslamicColors.deepGreen,
      page: const SalahInfoPage(),
    ),
    _ResourceCategory(
      title: 'Waqt & Rakah Table',
      arabicTitle: 'وقت الصلاة والركعات',
      subtitle: 'Prayer times and rak\'ah counts',
      icon: Icons.access_time_rounded,
      iconBg: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
      page: const WaqtRakahPage(),
    ),
    _ResourceCategory(
      title: 'Necessary Surahs',
      arabicTitle: 'السور الضرورية',
      subtitle: 'Essential Qur\'anic chapters',
      icon: Icons.menu_book_rounded,
      iconBg: Color(0xFFE8EAF6),
      iconColor: Color(0xFF3949AB),
      page: const NecessarySurahsPage(),
    ),
    _ResourceCategory(
      title: 'Du\'a & Adhkar',
      arabicTitle: 'الأدعية والأذكار',
      subtitle: 'Supplications & remembrances',
      icon: Icons.volunteer_activism_rounded,
      iconBg: Color(0xFFFCE4EC),
      iconColor: Color(0xFFC2185B),
      page: const DuasAzkarPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryCard(category: _categories[index]),
                ),
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      stretch: true,
      backgroundColor: IslamicColors.deepGreen,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: const Text(
          'Islamic Resources',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D4F2E), Color(0xFF2E8B57)],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -10,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: 0,
              bottom: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mosque_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بِسْمِ اللّٰهِ',
                    style: GoogleFonts.amiri(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── category card tile ───────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final _ResourceCategory category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: IslamicColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => category.page),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              // icon box
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: category.iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, size: 28, color: category.iconColor),
              ),
              const SizedBox(width: 16),
              // text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.arabicTitle,
                      style: GoogleFonts.amiri(
                        fontSize: 15,
                        color: IslamicColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: IslamicColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: IslamicColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              // arrow indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: IslamicColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: IslamicColors.deepGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
