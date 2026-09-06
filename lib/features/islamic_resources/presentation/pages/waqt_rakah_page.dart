import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'islamic_resources_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../prayer_times/presentation/utils/prayer_l10n.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────
class _PrayerRow {
  final String arabic;
  final String name;
  final Color rowColor;
  final String sunnahPre;
  final String fard;
  final String sunnahPost;
  final String extra;

  /// Which range description to show; resolved by [_rangeFor].
  final String timeKey;

  const _PrayerRow({
    required this.arabic,
    required this.name,
    required this.rowColor,
    required this.sunnahPre,
    required this.fard,
    required this.sunnahPost,
    required this.extra,
    required this.timeKey,
  });
}

/// The waqt range in the app's language.
String _rangeFor(BuildContext context, String key) {
  final l = L.of(context);
  return switch (key) {
    'fajr' => l.waqtFajrRange,
    'dhuhr' => l.waqtDhuhrRange,
    'asr' => l.waqtAsrRange,
    'maghrib' => l.waqtMaghribRange,
    'isha' => l.waqtIshaRange,
    'jumuah' => l.waqtJumuahNote,
    _ => '',
  };
}

const List<_PrayerRow> _prayers = [
  _PrayerRow(
    arabic: 'الْفَجْر',
    name: 'Fajr',
    rowColor: Color(0xFFE3F2FD),
    sunnahPre: '2',
    fard: '2',
    sunnahPost: '—',
    extra: '—',
    timeKey: 'fajr',
  ),
  _PrayerRow(
    arabic: 'الظُّهْر',
    name: 'Dhuhr',
    rowColor: Color(0xFFFFF8E1),
    sunnahPre: '4',
    fard: '4',
    sunnahPost: '2',
    extra: '—',
    timeKey: 'dhuhr',
  ),
  _PrayerRow(
    arabic: 'الْعَصْر',
    name: 'Asr',
    rowColor: Color(0xFFFFF3E0),
    sunnahPre: '4',
    fard: '4',
    sunnahPost: '—',
    extra: '—',
    timeKey: 'asr',
  ),
  _PrayerRow(
    arabic: 'الْمَغْرِب',
    name: 'Maghrib',
    rowColor: Color(0xFFFCE4EC),
    sunnahPre: '—',
    fard: '3',
    sunnahPost: '2',
    extra: '—',
    timeKey: 'maghrib',
  ),
  _PrayerRow(
    arabic: 'الْعِشَاء',
    name: 'Isha',
    rowColor: Color(0xFFEDE7F6),
    sunnahPre: '4',
    fard: '4',
    sunnahPost: '2',
    extra: 'Witr\n1–3',
    timeKey: 'isha',
  ),
  _PrayerRow(
    arabic: 'الْجُمُعَة',
    name: 'Jumu\'ah',
    rowColor: Color(0xFFE8F5E9),
    sunnahPre: '4',
    fard: '2',
    sunnahPost: '4+2',
    extra: '—',
    timeKey: 'jumuah',
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class WaqtRakahPage extends StatelessWidget {
  const WaqtRakahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionTitle('Rak\'ah Count Table'),
                const SizedBox(height: 10),
                _RakahTable(),
                const SizedBox(height: 6),
                _noteCard(
                  'Source: Sahih al-Bukhari & Muslim — Consensus of the four major schools.',
                ),
                const SizedBox(height: 22),
                _sectionTitle(L.of(context).waqtSectionTimes),
                const SizedBox(height: 10),
                ..._prayers.map((p) => _PrayerTimeCard(prayer: p)),
                const SizedBox(height: 22),
                _sectionTitle(L.of(context).waqtSectionWudu),
                const SizedBox(height: 10),
                _WuduNotesCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      title: Text(
        L.of(context).waqtTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      backgroundColor: const Color(0xFFE65100),
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 16),
                child: Icon(
                  Icons.access_time_rounded,
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

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: IslamicColors.deepGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: IslamicColors.darkText,
          ),
        ),
      ],
    );
  }

  Widget _noteCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: IslamicColors.lightGold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: IslamicColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: IslamicColors.gold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: IslamicColors.darkText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full-width Rakah Table ───────────────────────────────────────────────────
class _RakahTable extends StatelessWidget {
  const _RakahTable();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Proportional widths: Prayer 22%, Pre 14%, Fard 16%, Post 16%, Extra 15%, Time = rest
        final w = constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // header row
                _buildHeaderRow(context, w),
                // data rows
                ..._prayers.asMap().entries.map(
                  (e) => _buildDataRow(context, e.value, e.key.isEven, w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context, double w) {
    return Container(
      color: IslamicColors.deepGreen,
      child: Row(
        children: [
          _hCell(L.of(context).waqtColPrayer, w * 0.24, TextAlign.left),
          _hCell(L.of(context).waqtColPreSunnah, w * 0.14),
          _hCell(L.of(context).waqtColFard, w * 0.14),
          _hCell(L.of(context).waqtColPostSunnah, w * 0.16),
          _hCell(L.of(context).waqtColExtra, w * 0.14),
          _hCell(L.of(context).waqtColTotal, w * 0.18),
        ],
      ),
    );
  }

  Widget _hCell(
    String text,
    double width, [
    TextAlign align = TextAlign.center,
  ]) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    _PrayerRow prayer,
    bool even,
    double w,
  ) {
    final pre = int.tryParse(prayer.sunnahPre) ?? 0;
    final fard = int.tryParse(prayer.fard) ?? 0;
    final post = _parsePost(prayer.sunnahPost);
    final extra = _parseExtra(prayer.extra);
    final total = pre + fard + post + extra;
    final totalStr = total > 0 ? '$total' : '${fard + post}';

    return Container(
      color: even ? Colors.white : const Color(0xFFF9F9F9),
      child: Row(
        children: [
          // prayer name cell
          SizedBox(
            width: w * 0.24,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.arabic,
                    style: GoogleFonts.amiri(
                      fontSize: 16,
                      color: IslamicColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    prayerLabel(context, prayer.name),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: IslamicColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _dCell(prayer.sunnahPre, w * 0.14, Colors.blue.shade700),
          _dCell(prayer.fard, w * 0.14, IslamicColors.deepGreen, bold: true),
          _dCell(prayer.sunnahPost, w * 0.16, Colors.teal.shade700),
          _dCell(prayer.extra, w * 0.14, Colors.purple.shade700),
          _dCell(totalStr, w * 0.18, IslamicColors.darkText, bold: true),
        ],
      ),
    );
  }

  Widget _dCell(String text, double width, Color color, {bool bold = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: text == '—' ? Colors.grey.shade400 : color,
          ),
        ),
      ),
    );
  }

  int _parsePost(String s) {
    if (s == '—') return 0;
    if (s.contains('+')) {
      return s
          .split('+')
          .fold<int>(0, (sum, v) => sum + (int.tryParse(v) ?? 0));
    }
    return int.tryParse(s) ?? 0;
  }

  int _parseExtra(String s) {
    if (s == '—') return 0;
    if (s.contains('1–3')) return 1;
    return int.tryParse(s) ?? 0;
  }
}

// ─── Prayer time card ─────────────────────────────────────────────────────────
class _PrayerTimeCard extends StatelessWidget {
  const _PrayerTimeCard({required this.prayer});
  final _PrayerRow prayer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // colored indicator
            Container(
              width: 6,
              height: 70,
              decoration: BoxDecoration(
                color: prayer.rowColor.withValues(alpha: 2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          prayer.arabic,
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            color: IslamicColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prayerLabel(context, prayer.name),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: IslamicColors.mutedText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _rangeFor(context, prayer.timeKey),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: IslamicColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // fard count badge
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: IslamicColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${prayer.fard} Fard',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: IslamicColors.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wudu notes card ─────────────────────────────────────────────────────────
class _WuduNotesCard extends StatelessWidget {
  const _WuduNotesCard();

  @override
  Widget build(BuildContext context) {
    final notes = [
      _Note(L.of(context).wuduInvalidated, L.of(context).wuduInvalidatedBody),
      _Note(L.of(context).ghuslRequired, L.of(context).ghuslRequiredBody),
      _Note(L.of(context).tayammumAllowed, L.of(context).tayammumAllowedBody),
      _Note(L.of(context).masahKhuffayn, L.of(context).masahKhuffaynBody),
    ];

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
        children: notes
            .map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: IslamicColors.deepGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: IslamicColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: IslamicColors.mutedText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Note {
  final String title;
  final String value;
  const _Note(this.title, this.value);
}
