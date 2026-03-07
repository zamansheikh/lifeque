import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../islamic_resources_page.dart';
import 'salah_step_model.dart';
import 'salah_step_card.dart';

class DetailedSalahPage extends StatelessWidget {
  const DetailedSalahPage({super.key, required this.salahType});

  final SalahTypeData salahType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SalahStepCard(
                    step: salahType.steps[index],
                    stepNumber: index + 1,
                    accentColor: IslamicColors.deepGreen,
                  ),
                ),
                childCount: salahType.steps.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      title: Text(
        salahType.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      backgroundColor: IslamicColors.deepGreen,
      foregroundColor: Colors.white,
      expandedHeight: 180,
      pinned: true,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salahType.arabicTitle,
                          style: GoogleFonts.amiri(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salahType.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${salahType.steps.length} sequential steps',
                          style: TextStyle(
                            color: IslamicColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    salahType.icon,
                    size: 54,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
