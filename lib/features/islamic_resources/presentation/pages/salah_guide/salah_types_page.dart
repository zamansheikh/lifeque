import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../islamic_resources_page.dart';
import 'salah_guide_data.dart';
import 'salah_step_model.dart';
import 'detailed_salah_page.dart';

class SalahTypesPage extends StatelessWidget {
  const SalahTypesPage({super.key});

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
                  child: _SalahTypeCard(salahType: salahTypesData[index]),
                ),
                childCount: salahTypesData.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverHeader() {
    return SliverAppBar(
      title: const Text(
        'Salah Guide',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      expandedHeight: 180,
      pinned: true,
      backgroundColor: IslamicColors.deepGreen,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D4F2E), Color(0xFF2E8B57)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.self_improvement_rounded,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'دَلِيلُ الصَّلَاة',
                      style: GoogleFonts.amiri(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalahTypeCard extends StatelessWidget {
  const _SalahTypeCard({required this.salahType});
  final SalahTypeData salahType;

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
          MaterialPageRoute(
            builder: (_) => DetailedSalahPage(salahType: salahType),
          ),
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
                  color: IslamicColors.lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  salahType.icon,
                  size: 28,
                  color: IslamicColors.deepGreen,
                ),
              ),
              const SizedBox(width: 16),
              // text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salahType.arabicTitle,
                      style: GoogleFonts.amiri(
                        fontSize: 15,
                        color: IslamicColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      salahType.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: IslamicColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      salahType.subtitle,
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
