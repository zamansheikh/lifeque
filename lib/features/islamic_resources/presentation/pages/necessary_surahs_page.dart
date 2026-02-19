import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'islamic_resources_page.dart';

// ─── Surah data model ─────────────────────────────────────────────────────────
class _Surah {
  final String number;
  final String arabicName;
  final String englishName;
  final String meaning;
  final String category; // 'obligatory' | 'recommended' | 'special'
  final String shortNote;
  final String arabicText;
  final String transliteration;
  final String translation;

  const _Surah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.meaning,
    required this.category,
    required this.shortNote,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
  });
}

const List<_Surah> _surahs = [
  _Surah(
    number: '1',
    arabicName: 'الْفَاتِحَة',
    englishName: 'Al-Fatihah',
    meaning: 'The Opening',
    category: 'obligatory',
    shortNote: 'Mandatory in every rak\'ah — the pillar of prayer',
    arabicText:
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
    transliteration:
        'Bismillahir-Rahmanir-Rahim. Al-hamdu lillahi Rabbil-\'alamin. Ar-Rahmanir-Rahim. Maliki yawmid-din. Iyyaka na\'budu wa iyyaka nasta\'in. Ihdinas-sirat al-mustaqim. Sirat alladhina an\'amta \'alayhim, ghayril-maghdubi \'alayhim walad-dallin.',
    translation:
        'In the name of Allah, the Most Gracious, the Most Merciful. Praise be to Allah, Lord of the worlds. The Most Gracious, the Most Merciful. Master of the Day of Judgment. It is You we worship and You alone we ask for help. Guide us to the straight path — the path of those You have blessed, not of those who have incurred Your wrath, nor of those who have gone astray.',
  ),
  _Surah(
    number: '112',
    arabicName: 'الْإِخْلَاص',
    englishName: 'Al-Ikhlas',
    meaning: 'Sincerity / Purity of Faith',
    category: 'recommended',
    shortNote: 'Worth 1/3 of the Qur\'an. Recommended in second rak\'ah.',
    arabicText:
        'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    transliteration:
        'Qul huwa Allahu ahad. Allahus-samad. Lam yalid wa lam yulad. Wa lam yakun lahu kufuwan ahad.',
    translation:
        'Say: He is Allah, the One. Allah, the Eternal, Absolute. He neither begets nor was begotten. And there is none comparable to Him.',
  ),
  _Surah(
    number: '113',
    arabicName: 'الْفَلَق',
    englishName: 'Al-Falaq',
    meaning: 'The Daybreak',
    category: 'recommended',
    shortNote: 'Protection from evil. Recite together with An-Nas.',
    arabicText:
        'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
    transliteration:
        'Qul a\'udhu bi-Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-\'uqad. Wa min sharri hasidin idha hasad.',
    translation:
        'Say: I seek refuge in the Lord of the daybreak, from the evil of what He has created, and from the evil of darkness when it spreads, and from the evil of those who blow on knots, and from the evil of an envier when he envies.',
  ),
  _Surah(
    number: '114',
    arabicName: 'النَّاس',
    englishName: 'An-Nas',
    meaning: 'Mankind',
    category: 'recommended',
    shortNote: 'Protection from whispers of Shaytan and evil.',
    arabicText:
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
    transliteration:
        'Qul a\'udhu bi-Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudorin-nas. Minal-jinnati wan-nas.',
    translation:
        'Say: I seek refuge in the Lord of mankind, the King of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers in the hearts of mankind — from among jinn and mankind.',
  ),
  _Surah(
    number: '108',
    arabicName: 'الْكَوْثَر',
    englishName: 'Al-Kawthar',
    meaning: 'Abundance',
    category: 'special',
    shortNote: 'Shortest Surah. Promise of abundance from Allah.',
    arabicText:
        'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ ۝ فَصَلِّ لِرَبِّكَ وَانْحَرْ ۝ إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
    transliteration:
        'Inna a\'taynaka al-kawthar. Fasalli li-rabbika wanhar. Inna shani\'aka huwal-abtar.',
    translation:
        'Indeed, We have granted you [O Muhammad] al-Kawthar. So pray to your Lord and sacrifice. Indeed, your enemy is the one cut off.',
  ),
  _Surah(
    number: '103',
    arabicName: 'الْعَصْر',
    englishName: 'Al-Asr',
    meaning: 'The Declining Day',
    category: 'special',
    shortNote:
        'A reminder about time. Imam Shafi\'i said it suffices for all morals.',
    arabicText:
        'وَالْعَصْرِ ۝ إِنَّ الْإِنسَانَ لَفِي خُسْرٍ ۝ إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
    transliteration:
        'Wal-\'asr. Innal-insana lafi khusr. Illal-ladhina amanu wa \'amilus-salihat, wa tawassaw bil-haqqi wa tawassaw bis-sabr.',
    translation:
        'By time, indeed mankind is in loss, except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience.',
  ),
  _Surah(
    number: '109',
    arabicName: 'الْكَافِرُون',
    englishName: 'Al-Kafirun',
    meaning: 'The Disbelievers',
    category: 'special',
    shortNote: 'Recommended in first rak\'ah of sunnah before Fajr & Maghrib.',
    arabicText:
        'قُلْ يَا أَيُّهَا الْكَافِرُونَ ۝ لَا أَعْبُدُ مَا تَعْبُدُونَ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ وَلَا أَنَا عَابِدٌ مَّا عَبَدتُّمْ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ لَكُمْ دِينُكُمْ وَلِيَ دِينِ',
    transliteration:
        'Qul ya ayyuhal-kafirun. La a\'budu ma ta\'budun. Wa la antum \'abiduna ma a\'bud. Wa la ana \'abidun ma \'abadtum. Wa la antum \'abiduna ma a\'bud. Lakum dinukum wa liya din.',
    translation:
        'Say: O disbelievers, I do not worship what you worship. Nor are you worshippers of what I worship. Nor will I be a worshipper of what you worship. Nor will you be worshippers of what I worship. For you is your religion, and for me is my religion.',
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class NecessarySurahsPage extends StatelessWidget {
  const NecessarySurahsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final obligatory = _surahs
        .where((s) => s.category == 'obligatory')
        .toList();
    final recommended = _surahs
        .where((s) => s.category == 'recommended')
        .toList();
    final special = _surahs.where((s) => s.category == 'special').toList();

    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SurahGroup(
                  label: 'Obligatory',
                  arabicLabel: 'الواجبة',
                  icon: Icons.star_rounded,
                  color: IslamicColors.deepGreen,
                  bgColor: IslamicColors.lightGreen,
                  surahs: obligatory,
                ),
                const SizedBox(height: 8),
                _SurahGroup(
                  label: 'Recommended',
                  arabicLabel: 'المستحبة',
                  icon: Icons.thumb_up_alt_rounded,
                  color: const Color(0xFF3949AB),
                  bgColor: const Color(0xFFE8EAF6),
                  surahs: recommended,
                ),
                const SizedBox(height: 8),
                _SurahGroup(
                  label: 'Special Occasions',
                  arabicLabel: 'للمناسبات',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFFC2185B),
                  bgColor: const Color(0xFFFCE4EC),
                  surahs: special,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      title: const Text(
        'Necessary Surahs',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      backgroundColor: const Color(0xFF3949AB),
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 16),
                child: Icon(
                  Icons.menu_book_rounded,
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

// ─── Surah group ─────────────────────────────────────────────────────────────
class _SurahGroup extends StatelessWidget {
  const _SurahGroup({
    required this.label,
    required this.arabicLabel,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.surahs,
  });

  final String label;
  final String arabicLabel;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<_Surah> surahs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // group header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $arabicLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${surahs.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...surahs.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SurahCard(surah: s, accentColor: color),
          ),
        ),
      ],
    );
  }
}

// ─── Surah card ───────────────────────────────────────────────────────────────
class _SurahCard extends StatefulWidget {
  const _SurahCard({required this.surah, required this.accentColor});
  final _Surah surah;
  final Color accentColor;

  @override
  State<_SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<_SurahCard> {
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
          // header row
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
                  // surah number badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.surah.number,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.surah.arabicName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IslamicColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${widget.surah.englishName} — ${widget.surah.meaning}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.surah.shortNote,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IslamicColors.mutedText,
                          ),
                        ),
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
          // expanded content
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: IslamicColors.lightGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.surah.arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 2.2,
                        color: IslamicColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Transliteration
                  Text(
                    widget.surah.transliteration,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: IslamicColors.mutedText,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Translation
                  Text(
                    '"${widget.surah.translation}"',
                    style: const TextStyle(
                      fontSize: 13,
                      color: IslamicColors.darkText,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // copy button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.surah.arabicText),
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
                        'Copy Arabic',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.accentColor,
                      ),
                    ),
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
