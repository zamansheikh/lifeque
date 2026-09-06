import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'islamic_resources_page.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'salah_guide/salah_step_model.dart';

// ─── Surah data model ─────────────────────────────────────────────────────────
class _Surah {
  final String number;
  final String arabicName;
  final LText name;
  final LText meaning;
  final String category; // 'obligatory' | 'recommended' | 'special'
  final LText shortNote;
  final String arabicText;
  final LText transliteration;
  final LText translation;

  const _Surah({
    required this.number,
    required this.arabicName,
    required this.name,
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
    name: LText('Al-Fatihah', 'সূরা ফাতিহা'),
    meaning: LText('The Opening', 'সূচনা'),
    category: 'obligatory',
    shortNote: LText(
      'Mandatory in every rak\'ah — the pillar of prayer',
      'প্রতি রাকাতে পড়া আবশ্যক — নামাজের রুকন',
    ),
    arabicText:
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
    transliteration: LText(
      'Bismillahir-Rahmanir-Rahim. Al-hamdu lillahi Rabbil-\'alamin. Ar-Rahmanir-Rahim. Maliki yawmid-din. Iyyaka na\'budu wa iyyaka nasta\'in. Ihdinas-sirat al-mustaqim. Sirat alladhina an\'amta \'alayhim, ghayril-maghdubi \'alayhim walad-dallin.',
      'বিসমিল্লাহির রাহমানির রাহিম। আলহামদু লিল্লাহি রাব্বিল আলামিন। আর-রাহমানির রাহিম। মালিকি ইয়াওমিদ্দিন। ইয়্যাকা না‘বুদু ওয়া ইয়্যাকা নাস্তাঈন। ইহদিনাস সিরাতাল মুস্তাকিম। সিরাতাল্লাযিনা আন‘আমতা আলাইহিম, গাইরিল মাগদুবি আলাইহিম ওয়ালাদ দাল্লিন।',
    ),
    translation: LText(
      'In the name of Allah, the Most Gracious, the Most Merciful. Praise be to Allah, Lord of the worlds. The Most Gracious, the Most Merciful. Master of the Day of Judgment. It is You we worship and You alone we ask for help. Guide us to the straight path — the path of those You have blessed, not of those who have incurred Your wrath, nor of those who have gone astray.',
      'পরম করুণাময় অতি দয়ালু আল্লাহর নামে। সমস্ত প্রশংসা বিশ্বজগতের প্রতিপালক আল্লাহর। তিনি পরম করুণাময়, অতি দয়ালু। বিচার দিনের মালিক। আমরা কেবল আপনারই ইবাদত করি এবং কেবল আপনারই সাহায্য চাই। আমাদের সরল পথ দেখান — তাদের পথ যাদের আপনি নিয়ামত দিয়েছেন, তাদের পথ নয় যারা আপনার ক্রোধের শিকার, আর পথভ্রষ্টদেরও নয়।',
    ),
  ),
  _Surah(
    number: '112',
    arabicName: 'الْإِخْلَاص',
    name: LText('Al-Ikhlas', 'সূরা ইখলাস'),
    meaning: LText('Sincerity / Purity of Faith', 'একনিষ্ঠতা / বিশুদ্ধ ঈমান'),
    category: 'recommended',
    shortNote: LText(
      'Worth 1/3 of the Qur\'an. Recommended in second rak\'ah.',
      'কুরআনের এক-তৃতীয়াংশের সমান। দ্বিতীয় রাকাতে পড়া উত্তম।',
    ),
    arabicText:
        'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    transliteration: LText(
      'Qul huwa Allahu ahad. Allahus-samad. Lam yalid wa lam yulad. Wa lam yakun lahu kufuwan ahad.',
      'কুল হুয়াল্লাহু আহাদ। আল্লাহুস সামাদ। লাম ইয়ালিদ ওয়া লাম ইউলাদ। ওয়া লাম ইয়াকুল লাহু কুফুওয়ান আহাদ।',
    ),
    translation: LText(
      'Say: He is Allah, the One. Allah, the Eternal, Absolute. He neither begets nor was begotten. And there is none comparable to Him.',
      'বলুন, তিনি আল্লাহ, এক ও অদ্বিতীয়। আল্লাহ কারও মুখাপেক্ষী নন। তিনি কাউকে জন্ম দেননি, তাঁকেও জন্ম দেওয়া হয়নি। আর তাঁর সমতুল্য কেউ নেই।',
    ),
  ),
  _Surah(
    number: '113',
    arabicName: 'الْفَلَق',
    name: LText('Al-Falaq', 'সূরা ফালাক'),
    meaning: LText('The Daybreak', 'ভোর'),
    category: 'recommended',
    shortNote: LText(
      'Protection from evil. Recite together with An-Nas.',
      'অনিষ্ট থেকে হেফাজত। সূরা নাসের সঙ্গে পড়ুন।',
    ),
    arabicText:
        'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
    transliteration: LText(
      'Qul a\'udhu bi-Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-\'uqad. Wa min sharri hasidin idha hasad.',
      'কুল আউযু বিরাব্বিল ফালাক। মিন শাররি মা খালাক। ওয়া মিন শাররি গাসিকিন ইযা ওয়াকাব। ওয়া মিন শাররিন নাফফাসাতি ফিল উকাদ। ওয়া মিন শাররি হাসিদিন ইযা হাসাদ।',
    ),
    translation: LText(
      'Say: I seek refuge in the Lord of the daybreak, from the evil of what He has created, and from the evil of darkness when it spreads, and from the evil of those who blow on knots, and from the evil of an envier when he envies.',
      'বলুন, আমি আশ্রয় চাই ভোরের প্রতিপালকের কাছে — তিনি যা সৃষ্টি করেছেন তার অনিষ্ট থেকে, রাতের অন্ধকার যখন ঘনিয়ে আসে তার অনিষ্ট থেকে, গিঁটে ফুঁ দেওয়া জাদুকরদের অনিষ্ট থেকে এবং হিংসুকের হিংসার অনিষ্ট থেকে।',
    ),
  ),
  _Surah(
    number: '114',
    arabicName: 'النَّاس',
    name: LText('An-Nas', 'সূরা নাস'),
    meaning: LText('Mankind', 'মানুষ'),
    category: 'recommended',
    shortNote: LText(
      'Protection from whispers of Shaytan and evil.',
      'শয়তানের কুমন্ত্রণা ও অনিষ্ট থেকে হেফাজত।',
    ),
    arabicText:
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
    transliteration: LText(
      'Qul a\'udhu bi-Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudorin-nas. Minal-jinnati wan-nas.',
      'কুল আউযু বিরাব্বিন নাস। মালিকিন নাস। ইলাহিন নাস। মিন শাররিল ওয়াসওয়াসিল খান্নাস। আল্লাযি ইউওয়াসবিসু ফি সুদুরিন নাস। মিনাল জিন্নাতি ওয়ান নাস।',
    ),
    translation: LText(
      'Say: I seek refuge in the Lord of mankind, the King of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers in the hearts of mankind — from among jinn and mankind.',
      'বলুন, আমি আশ্রয় চাই মানুষের প্রতিপালকের কাছে, মানুষের অধিপতির কাছে, মানুষের ইলাহর কাছে — সেই আত্মগোপনকারী কুমন্ত্রণাদাতার অনিষ্ট থেকে, যে মানুষের অন্তরে কুমন্ত্রণা দেয়, জিন ও মানুষের মধ্য থেকে।',
    ),
  ),
  _Surah(
    number: '108',
    arabicName: 'الْكَوْثَر',
    name: LText('Al-Kawthar', 'সূরা কাওসার'),
    meaning: LText('Abundance', 'প্রাচুর্য'),
    category: 'special',
    shortNote: LText(
      'Shortest Surah. Promise of abundance from Allah.',
      'সবচেয়ে ছোট সূরা। আল্লাহর পক্ষ থেকে প্রাচুর্যের প্রতিশ্রুতি।',
    ),
    arabicText:
        'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ ۝ فَصَلِّ لِرَبِّكَ وَانْحَرْ ۝ إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
    transliteration: LText(
      'Inna a\'taynaka al-kawthar. Fasalli li-rabbika wanhar. Inna shani\'aka huwal-abtar.',
      'ইন্না আ‘তাইনাকাল কাওসার। ফাসাল্লি লিরাব্বিকা ওয়ানহার। ইন্না শানিআকা হুয়াল আবতার।',
    ),
    translation: LText(
      'Indeed, We have granted you [O Muhammad] al-Kawthar. So pray to your Lord and sacrifice. Indeed, your enemy is the one cut off.',
      'নিশ্চয়ই আমি আপনাকে কাওসার দান করেছি। সুতরাং আপনার প্রতিপালকের উদ্দেশে নামাজ পড়ুন ও কোরবানি করুন। নিশ্চয়ই আপনার শত্রুই নির্বংশ।',
    ),
  ),
  _Surah(
    number: '103',
    arabicName: 'الْعَصْر',
    name: LText('Al-Asr', 'সূরা আসর'),
    meaning: LText('The Declining Day', 'অতিবাহিত সময়'),
    category: 'special',
    shortNote: LText(
      'A reminder about time. Imam Shafi\'i said it suffices for all morals.',
      'সময় নিয়ে সতর্কবার্তা। ইমাম শাফিঈ (রহ.) বলেছেন, নীতিশিক্ষার জন্য এই সূরাই যথেষ্ট।',
    ),
    arabicText:
        'وَالْعَصْرِ ۝ إِنَّ الْإِنسَانَ لَفِي خُسْرٍ ۝ إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
    transliteration: LText(
      'Wal-\'asr. Innal-insana lafi khusr. Illal-ladhina amanu wa \'amilus-salihat, wa tawassaw bil-haqqi wa tawassaw bis-sabr.',
      'ওয়াল আসর। ইন্নাল ইনসানা লাফি খুসর। ইল্লাল্লাযিনা আমানু ওয়া আমিলুস সালিহাতি ওয়া তাওয়াসাও বিল হাক্কি ওয়া তাওয়াসাও বিস সাবর।',
    ),
    translation: LText(
      'By time, indeed mankind is in loss, except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience.',
      'সময়ের শপথ, নিশ্চয়ই মানুষ ক্ষতির মধ্যে আছে — তারা ছাড়া যারা ঈমান এনেছে, সৎকাজ করেছে এবং পরস্পরকে সত্যের ও ধৈর্যের উপদেশ দিয়েছে।',
    ),
  ),
  _Surah(
    number: '109',
    arabicName: 'الْكَافِرُون',
    name: LText('Al-Kafirun', 'সূরা কাফিরুন'),
    meaning: LText('The Disbelievers', 'অবিশ্বাসীরা'),
    category: 'special',
    shortNote: LText(
      'Recommended in first rak\'ah of sunnah before Fajr & Maghrib.',
      'ফজর ও মাগরিবের আগের সুন্নতের প্রথম রাকাতে পড়া উত্তম।',
    ),
    arabicText:
        'قُلْ يَا أَيُّهَا الْكَافِرُونَ ۝ لَا أَعْبُدُ مَا تَعْبُدُونَ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ وَلَا أَنَا عَابِدٌ مَّا عَبَدتُّمْ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ لَكُمْ دِينُكُمْ وَلِيَ دِينِ',
    transliteration: LText(
      'Qul ya ayyuhal-kafirun. La a\'budu ma ta\'budun. Wa la antum \'abiduna ma a\'bud. Wa la ana \'abidun ma \'abadtum. Wa la antum \'abiduna ma a\'bud. Lakum dinukum wa liya din.',
      'কুল ইয়া আইয়ুহাল কাফিরুন। লা আ‘বুদু মা তা‘বুদুন। ওয়া লা আনতুম আবিদুনা মা আ‘বুদ। ওয়া লা আনা আবিদুম মা আবাদতুম। ওয়া লা আনতুম আবিদুনা মা আ‘বুদ। লাকুম দিনুকুম ওয়া লিয়া দিন।',
    ),
    translation: LText(
      'Say: O disbelievers, I do not worship what you worship. Nor are you worshippers of what I worship. Nor will I be a worshipper of what you worship. Nor will you be worshippers of what I worship. For you is your religion, and for me is my religion.',
      'বলুন, হে কাফিররা, তোমরা যার ইবাদত করো আমি তার ইবাদত করি না। আমি যাঁর ইবাদত করি তোমরাও তাঁর ইবাদতকারী নও। তোমরা যার ইবাদত করেছ আমি তার ইবাদতকারী নই। আমি যাঁর ইবাদত করি তোমরাও তাঁর ইবাদতকারী নও। তোমাদের দ্বীন তোমাদের, আমার দ্বীন আমার।',
    ),
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
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SurahGroup(
                  label: LText('Obligatory', 'আবশ্যক'),
                  arabicLabel: 'الواجبة',
                  icon: Icons.star_rounded,
                  color: IslamicColors.deepGreen,
                  bgColor: IslamicColors.lightGreen,
                  surahs: obligatory,
                ),
                const SizedBox(height: 8),
                _SurahGroup(
                  label: LText('Recommended', 'উত্তম'),
                  arabicLabel: 'المستحبة',
                  icon: Icons.thumb_up_alt_rounded,
                  color: const Color(0xFF3949AB),
                  bgColor: const Color(0xFFE8EAF6),
                  surahs: recommended,
                ),
                const SizedBox(height: 8),
                _SurahGroup(
                  label: LText('Special Occasions', 'বিশেষ সময়ে'),
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

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      title: Text(
        L.of(context).resSurahs,
        style: const TextStyle(
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

  final LText label;
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
                label.of(context),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $arabicLabel',
                style: GoogleFonts.amiri(
                  fontSize: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                N.of(surahs.length),
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
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            color: IslamicColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${widget.surah.name.of(context)} — ${widget.surah.meaning.of(context)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.surah.shortNote.of(context),
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
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        height: 2.2,
                        color: IslamicColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Transliteration
                  Text(
                    widget.surah.transliteration.of(context),
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
                    '"${widget.surah.translation.of(context)}"',
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
                          SnackBar(
                            content: Text(L.of(context).duaCopiedArabic),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: Text(
                        L.of(context).duaCopyArabicLong,
                        style: const TextStyle(fontSize: 12),
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
