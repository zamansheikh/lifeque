import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'islamic_resources_page.dart';

// ─── Data model ───────────────────────────────────────────────────────────────
class _Dua {
  final String arabicName;
  final String englishName;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String? when; // context/when to recite

  const _Dua({
    required this.arabicName,
    required this.englishName,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    this.when,
  });
}

class _DuaCategory {
  final String arabicLabel;
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final List<_Dua> duas;

  const _DuaCategory({
    required this.arabicLabel,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.duas,
  });
}

// ─── All Duas data ────────────────────────────────────────────────────────────
final List<_DuaCategory> _categories = [
  _DuaCategory(
    arabicLabel: 'فِي الصَّلَاة',
    label: 'During Salah',
    color: IslamicColors.deepGreen,
    bgColor: IslamicColors.lightGreen,
    icon: Icons.self_improvement_rounded,
    duas: const [
      _Dua(
        arabicName: 'دُعَاء الِاسْتِفْتَاح',
        englishName: 'Opening Du\'a (Istiftah)',
        when: 'Silent — after Opening Takbir',
        arabicText:
            'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلٰهَ غَيْرُكَ',
        transliteration:
            'Subhanakallahumma wa bihamdika wa tabarakasmuka wa ta\'ala jadduka wa la ilaha ghayruk.',
        translation:
            'How perfect You are O Allah, and I praise You. Blessed is Your Name and Exalted is Your Majesty. There is no god worthy of worship except You.',
      ),
      _Dua(
        arabicName: 'ذِكْر الرُّكُوع',
        englishName: 'Dhikr of Ruku\'',
        when: 'Repeated 3 times (minimum) in Ruku\'',
        arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيم',
        transliteration: 'Subhana Rabbiyal \'Azim',
        translation: 'Glory be to my Lord, the Most Great',
      ),
      _Dua(
        arabicName: 'عِنْد الرَّفْع مِن الرُّكُوع',
        englishName: 'Rising from Ruku\'',
        when: 'While rising from bowing',
        arabicText:
            'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْدُ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيه',
        transliteration:
            'Sami\'Allahu liman hamidah. Rabbana wa lakal hamd, hamdan kathiran tayyiban mubarakan fih.',
        translation:
            'Allah hears the one who praises Him. Our Lord, to You is all praise — abundant, pure, and blessed praise.',
      ),
      _Dua(
        arabicName: 'ذِكْر السُّجُود',
        englishName: 'Dhikr of Sujud',
        when: 'Repeated 3 times (minimum) in prostration',
        arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
        transliteration: 'Subhana Rabbiyal A\'la',
        translation: 'Glory be to my Lord, the Most High',
      ),
      _Dua(
        arabicName: 'دُعَاء بَيْن السَّجْدَتَيْن',
        englishName: 'Du\'a between Sujuds',
        when: 'In the Jalsah (sitting between two prostrations)',
        arabicText:
            'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي',
        transliteration:
            'Rabbighfirli, warhamni, wajburni, warfa\'ni, warzuqni, wahdinii, wa\'afini.',
        translation:
            'O Lord, forgive me, have mercy on me, restore me, raise me up, provide for me, guide me, and grant me wellbeing.',
      ),
    ],
  ),
  _DuaCategory(
    arabicLabel: 'بَعْدَ الصَّلَاة',
    label: 'After Salah',
    color: const Color(0xFF6A1B9A),
    bgColor: const Color(0xFFF3E5F5),
    icon: Icons.volunteer_activism_rounded,
    duas: const [
      _Dua(
        arabicName: 'الِاسْتِغْفَار',
        englishName: 'Istighfar (3 times)',
        when: 'Immediately after Salam — 3 times',
        arabicText: 'أَسْتَغْفِرُ اللَّه',
        transliteration: 'Astaghfirullah',
        translation: 'I seek forgiveness from Allah',
      ),
      _Dua(
        arabicName: 'دُعَاء السَّلَام',
        englishName: 'Peace Du\'a',
        when: 'After the three istigfars',
        arabicText:
            'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَام',
        transliteration:
            'Allahumma Antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.',
        translation:
            'O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Majesty and Honor.',
      ),
      _Dua(
        arabicName: 'التَّسْبِيح وَالتَّحْمِيد',
        englishName: 'Tasbih, Tahmid & Takbir',
        when: '33 + 33 + 34 = 100',
        arabicText:
            'سُبْحَانَ اللَّهِ ×٣٣ ۝ الْحَمْدُ لِلَّهِ ×٣٣ ۝ اللَّهُ أَكْبَر ×٣٤',
        transliteration:
            'Subhanallah (×33), Alhamdulillah (×33), Allahu Akbar (×34)',
        translation:
            'Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (34 times).',
      ),
      _Dua(
        arabicName: 'آيَة الْكُرْسِي',
        englishName: 'Ayat al-Kursi',
        when: 'Once after every obligatory prayer — great protection',
        arabicText:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
        transliteration:
            'Allahu la ilaha illa huwal-hayyul-qayyum. La ta\'khudhuhuu sinatun wa la nawm. Lahuu ma fis-samawati wa ma fil-ard...',
        translation:
            'Allah — there is no deity except Him, the Ever-Living, the Self-Sustaining. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth... (Surah 2:255)',
      ),
    ],
  ),
  _DuaCategory(
    arabicLabel: 'أَذْكَار الصَّبَاح وَالْمَسَاء',
    label: 'Morning & Evening Adhkar',
    color: const Color(0xFFE65100),
    bgColor: const Color(0xFFFFF3E0),
    icon: Icons.wb_sunny_rounded,
    duas: const [
      _Dua(
        arabicName: 'سَيِّد الِاسْتِغْفَار',
        englishName: 'Master of Seeking Forgiveness',
        when: 'Morning and Evening — once each',
        arabicText:
            'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلٰهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ وَأَبُوءُ بِذَنْبِي',
        transliteration:
            'Allahumma anta Rabbi, la ilaha illa anta, khalaqtani wa ana \'abduka wa ana \'ala \'ahdika wa wa\'dika mastata\'tu, a\'udhu bika min sharri ma sana\'tu, abu\'u laka bini\'matika wa abu\'u bidhanbii...',
        translation:
            'O Allah, You are my Lord. There is no god but You. You created me and I am Your slave. I uphold Your covenant and my promise to You as best I can. I seek refuge in You from the evil of what I have done...',
      ),
      _Dua(
        arabicName: 'دُعَاء الصَّبَاح',
        englishName: 'Morning Protection',
        when: 'Morning — 3 times',
        arabicText:
            'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيم',
        transliteration:
            'Bismillahil-ladhi la yadurru ma\'asmihi shay\'un fil-ardi wala fis-sama\'i wa huwas-sami\'ul-\'alim.',
        translation:
            'In the name of Allah, with whose name nothing can cause harm on earth or in the heavens, and He is the All-Hearing, All-Knowing.',
      ),
      _Dua(
        arabicName: 'أذكار المساء',
        englishName: 'Evening Remembrance',
        when: 'Evening — 3 times',
        arabicText:
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَق',
        transliteration:
            'A\'udhu bikalimAtillahit-tammati min sharri ma khalaq.',
        translation:
            'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      ),
    ],
  ),
  _DuaCategory(
    arabicLabel: 'أَدْعِيَة مُتَنَوِّعَة',
    label: 'General Du\'as',
    color: const Color(0xFF1565C0),
    bgColor: const Color(0xFFE3F2FD),
    icon: Icons.favorite_border_rounded,
    duas: const [
      _Dua(
        arabicName: 'دُعَاء الدُّنْيَا وَالآخِرَة',
        englishName: 'Best of Both Worlds',
        arabicText:
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّار',
        transliteration:
            'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
        translation:
            'Our Lord, give us good in this world and good in the Hereafter, and protect us from the torment of the Fire.',
      ),
      _Dua(
        arabicName: 'دُعَاء الثَّبَات',
        englishName: 'Du\'a for Steadfastness',
        arabicText: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
        transliteration: 'Ya muqallibal-qulub, thabbit qalbi \'ala dinik.',
        translation:
            'O Turner of hearts, make my heart firm upon Your religion.',
      ),
      _Dua(
        arabicName: 'دُعَاء الهِدَايَة',
        englishName: 'Du\'a for Guidance',
        arabicText: 'اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي',
        transliteration: 'Allahummahdini wa saddidni.',
        translation: 'O Allah, guide me and keep me on the right path.',
      ),
      _Dua(
        arabicName: 'دُعَاء الخَيْر',
        englishName: 'Du\'a for All Good',
        arabicText:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
        transliteration:
            'Allahumma inni as\'alukal-huda wat-tuqa wal-\'afafa wal-ghina.',
        translation:
            'O Allah, I ask You for guidance, piety, chastity, and self-sufficiency.',
      ),
    ],
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class DuasAzkarPage extends StatelessWidget {
  const DuasAzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final cat = _categories[index];
                return _DuaCategorySection(category: cat);
              }, childCount: _categories.length),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      title: const Text(
        'Du\'a & Adhkar',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      backgroundColor: const Color(0xFFC2185B),
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF880E4F), Color(0xFFE91E63)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 16),
                child: Icon(
                  Icons.volunteer_activism_rounded,
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
}

// ─── Category section ────────────────────────────────────────────────────────
class _DuaCategorySection extends StatelessWidget {
  const _DuaCategorySection({required this.category});
  final _DuaCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // category header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: category.bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: category.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(category.icon, size: 18, color: category.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.arabicLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: category.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${category.duas.length} du\'as',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: category.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...category.duas.map(
          (dua) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DuaCard(dua: dua, accentColor: category.color),
          ),
        ),
      ],
    );
  }
}

// ─── Dua card ─────────────────────────────────────────────────────────────────
class _DuaCard extends StatefulWidget {
  const _DuaCard({required this.dua, required this.accentColor});
  final _Dua dua;
  final Color accentColor;

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // header
          InkWell(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(_expanded ? 0 : 16),
              bottomRight: Radius.circular(_expanded ? 0 : 16),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.dua.arabicName.split(' ').last,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dua.arabicName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IslamicColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.dua.englishName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.darkText,
                          ),
                        ),
                        if (widget.dua.when != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.dua.when!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: IslamicColors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.accentColor,
                  ),
                ],
              ),
            ),
          ),
          // expanded body
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: IslamicColors.lightGold,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: IslamicColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      widget.dua.arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 2.0,
                        fontWeight: FontWeight.w600,
                        color: IslamicColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Transliteration
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.dua.transliteration,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: IslamicColors.mutedText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Translation
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.dua.translation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: IslamicColors.darkText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.dua.arabicText),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arabic text copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text(
                          'Copy',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: widget.accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
