import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'islamic_resources_page.dart';

// ─── Data model ──────────────────────────────────────────────────────────────
class SalahStep {
  final String id;
  final String arabicName;
  final String englishName;
  final String phase; // 'before' | 'during' | 'after'
  final IconData icon;
  final String shortDesc;
  final String detailDesc;
  final List<String> keyPoints;
  final String? arabicDua;
  final String? transliteration;
  final String? translation;

  const SalahStep({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.phase,
    required this.icon,
    required this.shortDesc,
    required this.detailDesc,
    required this.keyPoints,
    this.arabicDua,
    this.transliteration,
    this.translation,
  });
}

// ─── All salah steps data ─────────────────────────────────────────────────────
const List<SalahStep> salahSteps = [
  // ── BEFORE ──────────────────────────────────────────────────────────────────
  SalahStep(
    id: 'niyyah',
    arabicName: 'نِيَّة',
    englishName: 'Intention (Niyyah)',
    phase: 'before',
    icon: Icons.favorite_border_rounded,
    shortDesc: 'Make the intention in your heart',
    detailDesc:
        'Niyyah is the sincere intention in the heart to perform the prayer for the sake of Allah. '
        'It does not need to be uttered aloud — it is a matter of the heart. '
        'You should intend which prayer you are performing (e.g., Fajr, Dhuhr) and that it is fard (obligatory) or sunnah.',
    keyPoints: [
      'Intention is in the heart, not the tongue',
      'Specify which salah you are performing',
      'Intend it purely for the sake of Allah',
      'Form the intention before starting Takbir',
    ],
  ),
  SalahStep(
    id: 'wudu',
    arabicName: 'الوُضُوء',
    englishName: 'Wudu (Ablution)',
    phase: 'before',
    icon: Icons.water_drop_outlined,
    shortDesc: 'Purify with ritual ablution',
    detailDesc:
        'Wudu is the ritual purification with water that is required before performing Salah. '
        'Without wudu, the prayer is not valid.',
    keyPoints: [
      '1. Say Bismillah and wash both hands 3 times',
      '2. Rinse the mouth 3 times',
      '3. Sniff water into the nose and blow it out 3 times',
      '4. Wash the face completely 3 times',
      '5. Wash arms up to and including elbows 3 times (right first)',
      '6. Wipe the head once with wet hands',
      '7. Wipe the ears inside and outside once',
      '8. Wash feet up to and including ankles 3 times (right first)',
    ],
    arabicDua:
        'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    transliteration:
        'Ash-hadu alla ilaha illallahu wa ash-hadu anna Muhammadan \'abduhu wa rasoluhu',
    translation:
        'I testify that there is no god but Allah, and I testify that Muhammad is His slave and Messenger.',
  ),
  SalahStep(
    id: 'qibla',
    arabicName: 'اسْتِقْبَالُ الْقِبْلَة',
    englishName: 'Facing the Qibla',
    phase: 'before',
    icon: Icons.explore_outlined,
    shortDesc: 'Face the direction of the Ka\'bah',
    detailDesc:
        'Before beginning the prayer, you must face the direction of the Ka\'bah in Mecca. '
        'This is done by using a compass, phone app, or the sun/stars to determine the qibla direction. '
        'Cover your \'awrah and ensure the place of prayer is clean.',
    keyPoints: [
      'Face the Ka\'bah in Mecca (direction known as Qibla)',
      'Cover the \'awrah appropriately',
      'Ensure the ground is clean (or use a prayer mat)',
      'Remove shoes before stepping on the prayer mat',
    ],
  ),

  // ── DURING ──────────────────────────────────────────────────────────────────
  SalahStep(
    id: 'takbir',
    arabicName: 'تَكْبِيرَةُ الْإِحْرَام',
    englishName: 'Opening Takbir',
    phase: 'during',
    icon: Icons.record_voice_over_outlined,
    shortDesc: 'Say Allahu Akbar to enter prayer',
    detailDesc:
        'The Takbiratul Ihram is the opening declaration of "Allahu Akbar" (Allah is the Greatest). '
        'Once said, you have entered the sacred state of prayer and worldly speech is forbidden. '
        'Raise both hands up to ear lobes (men) or shoulders (women) while saying the Takbir.',
    keyPoints: [
      'Raise hands to earlobes while saying Allahu Akbar',
      'This locks you into the prayer — you cannot speak',
      'Face the Qibla and stand upright',
      'Place right hand over left on the chest',
    ],
    arabicDua: 'اللَّهُ أَكْبَر',
    transliteration: 'Allahu Akbar',
    translation: 'Allah is the Greatest',
  ),
  SalahStep(
    id: 'qiyam',
    arabicName: 'الْقِيَام',
    englishName: 'Qiyam – Standing & Recitation',
    phase: 'during',
    icon: Icons.accessibility_new_rounded,
    shortDesc: 'Stand upright and recite Al-Fatihah',
    detailDesc:
        'In Qiyam you stand upright, hands folded over the chest. '
        'Begin with the opening du\'a (Istiftah), then seek refuge (Ta\'awwudh), '
        'then recite Bismillah and Surah Al-Fatihah — which is obligatory in every rak\'ah. '
        'Follow it with another surah or a few verses (in the first two rak\'ahs).',
    keyPoints: [
      'Recite opening du\'a silently (Subhanakallahumma wa bihamdika...)',
      'Say A\'udhu billahi minash-shaytanir-rajim',
      'Say Bismillahir-rahmanir-rahim',
      'Recite Surah Al-Fatihah — obligatory in every rak\'ah',
      'In first two rak\'ahs, recite an additional surah',
      'Imam recites aloud in Fajr, Maghrib, Isha; silently in Dhuhr and Asr',
    ],
    arabicDua:
        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
    transliteration:
        'Al-hamdu lillahi rabb il-\'alamin. Ar-rahman ir-rahim. Maliki yawm id-din. Iyyaka na\'budu wa iyyaka nasta\'in. Ihdinas-sirat al-mustaqim.',
    translation:
        'Praise be to Allah, Lord of the worlds. The Most Merciful, the Most Compassionate. Master of the Day of Judgment. It is You we worship and You alone we ask for help. Guide us to the straight path.',
  ),
  SalahStep(
    id: 'ruku',
    arabicName: 'الرُّكُوع',
    englishName: 'Ruku\' (Bowing)',
    phase: 'during',
    icon: Icons.airline_seat_flat_angled_rounded,
    shortDesc: 'Bow with hands on knees',
    detailDesc:
        'Bow forward with your back flat and horizontal, hands placed firmly on your knees with fingers spread. '
        'Keep your head in line with your back. The minimum is to bow until you can touch your knees. '
        'The Sunnah is to say the dhikr at least three times.',
    keyPoints: [
      'Back flat, parallel to the ground',
      'Hands grip the knees, fingers spread',
      'Head in line with the back',
      'Say tasbih at least 3 times',
    ],
    arabicDua: 'سُبْحَانَ رَبِّيَ الْعَظِيم',
    transliteration: 'Subhana Rabbiyal \'Azim',
    translation: 'Glory be to my Lord, the Most Great',
  ),
  SalahStep(
    id: 'iktidal',
    arabicName: 'الِاعْتِدَال',
    englishName: 'I\'tidal (Rising from Ruku\')',
    phase: 'during',
    icon: Icons.height_rounded,
    shortDesc: 'Rise fully upright, praising Allah',
    detailDesc:
        'After completing the Ruku\', rise back to a fully upright position, '
        'saying "Sami\'Allahu liman hamidah" while rising, and then "Rabbana lakal hamd" while standing still.',
    keyPoints: [
      'Rise fully upright — this is a pillar (rukn)',
      'Raise hands while rising and say the tasmee\'',
      'Stand still for a moment (at least briefly)',
      'Then say the tahmid',
    ],
    arabicDua: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْد',
    transliteration: 'Sami\'Allahu liman hamidah. Rabbana wa lakal hamd.',
    translation:
        'Allah hears the one who praises Him. Our Lord, to You is all praise.',
  ),
  SalahStep(
    id: 'sujud1',
    arabicName: 'السُّجُود الْأَوَّل',
    englishName: 'First Sujud (Prostration)',
    phase: 'during',
    icon: Icons.person_outline_rounded,
    shortDesc: 'Prostrate on seven body parts',
    detailDesc:
        'Prostrate with seven bones touching the ground: forehead (with nose), two palms, '
        'two knees, and two sets of toes. The forehead should be placed firmly on the ground. '
        'Arms should not rest on the ground (elbows up, away from the body). '
        'Recite the tasbih at least three times.',
    keyPoints: [
      'Seven body parts on ground: forehead+nose, 2 palms, 2 knees, toes',
      'Elbows off the ground, raised away from the body',
      'Toes pointing towards Qibla',
      'Say tasbih at least 3 times',
      'Hands in line with or in front of the face',
    ],
    arabicDua: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
    transliteration: 'Subhana Rabbiyal A\'la',
    translation: 'Glory be to my Lord, the Most High',
  ),
  SalahStep(
    id: 'jalsa',
    arabicName: 'الْجَلْسَة',
    englishName: 'Jalsah (Sitting Between Sujuds)',
    phase: 'during',
    icon: Icons.event_seat_rounded,
    shortDesc: 'Sit briefly between the two prostrations',
    detailDesc:
        'After the first Sujud, rise to a seated position (Jalsah) briefly. '
        'Sit on the left foot with the right foot upright and toes pointing toward Qibla. '
        'There is a du\'a to recite in this position.',
    keyPoints: [
      'Sit on the left foot, right foot upright',
      'Right toes point toward Qibla',
      'Recite the sitting du\'a (Rabbighfirli)',
      'Do not rush — this position is a wajib (obligatory act)',
    ],
    arabicDua:
        'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي',
    transliteration:
        'Rabbighfirli war-hamni wajburni warfa\'ni warzuqni wahdinii wa\'afini wa\'fu \'anni',
    translation:
        'O Lord, forgive me, have mercy on me, restore me, raise me, provide for me, guide me, grant me wellbeing, and pardon me.',
  ),
  SalahStep(
    id: 'sujud2',
    arabicName: 'السُّجُود الثَّانِي',
    englishName: 'Second Sujud',
    phase: 'during',
    icon: Icons.person_outline_rounded,
    shortDesc: 'Prostrate a second time on seven body parts',
    detailDesc:
        'Perform the second prostration exactly like the first: seven body parts on the ground, '
        'elbows up, head firm, and recite the tasbih at least three times. '
        'After this, rise for the next rak\'ah or proceed to Tashahhud.',
    keyPoints: [
      'Same posture as the first Sujud',
      'All seven body parts touching the ground',
      'Say tasbih at least 3 times',
      'After this completes one rak\'ah',
    ],
    arabicDua: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
    transliteration: 'Subhana Rabbiyal A\'la',
    translation: 'Glory be to my Lord, the Most High',
  ),
  SalahStep(
    id: 'tashahhud',
    arabicName: 'التَّشَهُّد',
    englishName: 'Tashahhud (Final Sitting)',
    phase: 'during',
    icon: Icons.event_seat_outlined,
    shortDesc: 'Sit and recite Tashahhud & Salawat',
    detailDesc:
        'In the final sitting (after the last rak\'ah), sit in the Tashahhud position. '
        'Recite the Tashahhud (At-Tahiyyat), followed by Salawat (Durood Ibrahim), '
        'and end with the closing du\'a before giving Salam.',
    keyPoints: [
      'Sit on the left buttock (Tawarruk position in final sitting per Hanbali/Shafi\'i)',
      'Index finger raised during the Shahadah phrase',
      'Recite At-Tahiyyat fully',
      'Recite Salawat (Durood Ibrahim) after',
      'Optionally recite a closing du\'a',
    ],
    arabicDua:
        'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    transliteration:
        'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu \'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu \'alayna wa \'ala \'ibadillahis-salihin. Ash-hadu alla ilaha illallah wa ash-hadu anna Muhammadan \'abduhu wa rasoluhu.',
    translation:
        'All greetings, prayers and good words are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah and I bear witness that Muhammad is His slave and Messenger.',
  ),
  SalahStep(
    id: 'salam',
    arabicName: 'التَّسْلِيم',
    englishName: 'Salam (Closing)',
    phase: 'during',
    icon: Icons.waving_hand_outlined,
    shortDesc: 'End the prayer with Salam on both sides',
    detailDesc:
        'The prayer is concluded by turning the head to the right and saying "As-Salamu \'Alaykum wa Rahmatullah," '
        'then turning to the left and repeating. This exits the sacred state of prayer.',
    keyPoints: [
      'Turn head to the right first',
      'Then to the left',
      'This is a pillar (rukn) of salah',
      'Intention to leave the prayer',
    ],
    arabicDua: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّه',
    transliteration: 'As-Salamu \'Alaykum wa Rahmatullah',
    translation: 'Peace and the mercy of Allah be upon you',
  ),

  // ── AFTER ───────────────────────────────────────────────────────────────────
  SalahStep(
    id: 'istighfar',
    arabicName: 'الِاسْتِغْفَار',
    englishName: 'Istighfar (Seeking Forgiveness)',
    phase: 'after',
    icon: Icons.volunteer_activism_outlined,
    shortDesc: 'Seek forgiveness three times',
    detailDesc:
        'Immediately after the Salam, say Astaghfirullah three times. '
        'Then recite the du\'a of Tahlil. This follows the Sunnah of the Prophet ﷺ '
        'as narrated in Sahih Muslim.',
    keyPoints: [
      'Say Astaghfirullah 3 times',
      'Then recite Allahumma Antas-Salam...',
      'Do not turn away immediately after salam',
    ],
    arabicDua:
        'أَسْتَغْفِرُ اللَّهَ ۝ أَسْتَغْفِرُ اللَّهَ ۝ أَسْتَغْفِرُ اللَّهَ ۝ اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَام',
    transliteration:
        'Astaghfirullah (x3). Allahumma Antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.',
    translation:
        'I seek forgiveness from Allah (x3). O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Majesty and Honor.',
  ),
  SalahStep(
    id: 'tasbih',
    arabicName: 'التَّسْبِيح وَالتَّحْمِيد',
    englishName: 'Tasbih & Tahmid (Glorification)',
    phase: 'after',
    icon: Icons.loop_rounded,
    shortDesc: 'Glorify Allah 33+33+34 times',
    detailDesc:
        'After Salah, count on the fingers or prayer beads: '
        'Subhanallah 33 times, Alhamdulillah 33 times, Allahu Akbar 34 times. '
        'This completes 100 and is among the greatest adhkar. '
        'Then recite Ayat al-Kursi for comprehensive protection.',
    keyPoints: [
      'Subhanallah × 33',
      'Alhamdulillah × 33',
      'Allahu Akbar × 34 (total = 100)',
      'Recite Ayat al-Kursi (Surah 2:255)',
      'Recite Surah Al-Ikhlas, Al-Falaq, An-Nas',
    ],
    arabicDua:
        'سُبْحَانَ اللَّهِ (٣٣) ۝ الْحَمْدُ لِلَّهِ (٣٣) ۝ اللَّهُ أَكْبَر (٣٤)',
    transliteration:
        'Subhanallah (33x), Alhamdulillah (33x), Allahu Akbar (34x)',
    translation:
        'Glory be to Allah (33), Praise be to Allah (33), Allah is the Greatest (34)',
  ),
  SalahStep(
    id: 'dua',
    arabicName: 'الدُّعَاء',
    englishName: 'Du\'a (Supplication)',
    phase: 'after',
    icon: Icons.record_voice_over_rounded,
    shortDesc: 'Raise hands and supplicate to Allah',
    detailDesc:
        'After the adhkar, raise your hands and make sincere du\'a to Allah. '
        'The time after Salah is among the times when du\'a is most accepted. '
        'Ask for forgiveness, guidance, health, blessings in this life and the next.',
    keyPoints: [
      'Supplicate in your own language if needed',
      'Begin with praise of Allah and salawat on the Prophet ﷺ',
      'Ask for the best of this life and the Hereafter',
      'End with Ameen',
      'The Prophet ﷺ said: "Du\'a is the essence of worship" (Tirmidhi)',
    ],
    arabicDua:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّار',
    transliteration:
        'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
    translation:
        'Our Lord, give us good in this world and good in the Hereafter, and protect us from the torment of the Fire.',
  ),
];

// ─── Salah Info Page ──────────────────────────────────────────────────────────
class SalahInfoPage extends StatelessWidget {
  const SalahInfoPage({super.key});

  List<SalahStep> _stepsForPhase(String phase) =>
      salahSteps.where((s) => s.phase == phase).toList();

  @override
  Widget build(BuildContext context) {
    final before = _stepsForPhase('before');
    final during = _stepsForPhase('during');
    final after = _stepsForPhase('after');

    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PhaseSection(
                  arabicLabel: 'قَبْلَ الصَّلَاة',
                  label: 'Before Salah',
                  color: const Color(0xFF1565C0),
                  bgColor: const Color(0xFFE3F2FD),
                  steps: before,
                ),
                const SizedBox(height: 8),
                _PhaseSection(
                  arabicLabel: 'فِي الصَّلَاة',
                  label: 'During Salah',
                  color: IslamicColors.deepGreen,
                  bgColor: IslamicColors.lightGreen,
                  steps: during,
                ),
                const SizedBox(height: 8),
                _PhaseSection(
                  arabicLabel: 'بَعْدَ الصَّلَاة',
                  label: 'After Salah',
                  color: const Color(0xFF6A1B9A),
                  bgColor: const Color(0xFFF3E5F5),
                  steps: after,
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
      title: const Text(
        'Salah Guide',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      backgroundColor: IslamicColors.deepGreen,
      foregroundColor: Colors.white,
      expandedHeight: 130,
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
                          'دَلِيلُ الصَّلَاة',
                          style: GoogleFonts.amiri(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${salahSteps.length} steps of prayer',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.self_improvement_rounded,
                    size: 44,
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

// ─── Phase section (before / during / after) ─────────────────────────────────
class _PhaseSection extends StatelessWidget {
  const _PhaseSection({
    required this.arabicLabel,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.steps,
  });

  final String arabicLabel;
  final String label;
  final Color color;
  final Color bgColor;
  final List<SalahStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // phase header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arabicLabel,
                    style: GoogleFonts.amiri(
                      fontSize: 15,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${steps.length} steps',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // step cards
        ...steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StepCard(
              step: entry.value,
              stepNumber: entry.key + 1,
              accentColor: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Single step card ─────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  const _StepCard({
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
                  child: Icon(step.icon, size: 20, color: accentColor),
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
                if (step.arabicDua != null) ...[
                  const SizedBox(height: 14),
                  _duaCard(color),
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

  Widget _duaCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: IslamicColors.lightGold,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Text(
                'Du\'a / Dhikr',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: IslamicColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: IslamicColors.gold, height: 1),
          const SizedBox(height: 16),
          // Arabic
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              step.arabicDua!,
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
          if (step.transliteration != null) ...[
            const SizedBox(height: 10),
            Text(
              step.transliteration!,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: IslamicColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
          if (step.translation != null) ...[
            const SizedBox(height: 8),
            Text(
              '"${step.translation!}"',
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
