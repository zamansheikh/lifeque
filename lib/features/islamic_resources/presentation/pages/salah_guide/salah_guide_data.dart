import 'package:flutter/material.dart';
import 'salah_step_model.dart';

// ─── Constants for Purity/Conditions (Before Salah) ──────────────────────────
const _conditions = SalahStep(
  id: 'conditions',
  arabicName: 'شُرُوطُ الصَّلَاة',
  englishName: 'Essential Conditions (Shurut)',
  phase: 'before',
  icon: Icons.assignment_turned_in_outlined,
  shortDesc: 'Ensure time, awrah, purity, qibla, and niyyah',
  detailDesc:
      'You must fulfill these conditions before prayer begins. A deficiency in any of these renders the prayer void:\n'
      '• Time: Ensure the prayer time has entered.\n'
      '• Awrah: Cover your private areas appropriately.\n'
      '• Purity: Attain ritual purity (Wudu/Ghusl) and physical purity (body, clothes, spot of prayer).\n'
      '• Qibla: Face the Kaaba in Mecca.\n'
      '• Niyyah: Establish the specific intention in your heart.',
  keyPoints: [
    'Time must have entered properly',
    'Cover the Awrah completely',
    'Ensure Wudu/Ghusl is performed',
    'Body, clothes, and prayer spot must be free of impurities',
    'Face the Qibla (Kaaba)',
    'Intend the specific prayer in the heart',
  ],
);

const _wudu = SalahStep(
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
    'Say Bismillah and wash hands',
    'Rinse mouth and nose completely',
    'Wash the face and arms up to elbows',
    'Wipe the head and ears',
    'Wash feet up to and including ankles',
  ],
  duas: [
    SalahDua(
      arabic:
          'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration:
          'Ash-hadu alla ilaha illallahu wa ash-hadu anna Muhammadan \'abduhu wa rasoluhu',
      translation:
          'I testify that there is no god but Allah, and I testify that Muhammad is His slave and Messenger.',
    ),
  ],
);

const _qiblaNiyyah = SalahStep(
  id: 'qibla_niyyah',
  arabicName: 'اسْتِقْبَالُ الْقِبْلَة وَ النِّيَّة',
  englishName: 'Qibla & Niyyah',
  phase: 'before',
  icon: Icons.explore_outlined,
  shortDesc: 'Face Ka\'bah and intend in the heart',
  detailDesc:
      'Face the direction of the Ka\'bah in Mecca. If you knowingly face another direction, your prayer is invalid '
      'unless circumstances prevent it. Simultaneously, establish the Niyyah (intention) in your heart. '
      'It is not a verbal script. You must know specifically which prayer you are performing.',
  keyPoints: [
    'Face the Ka\'bah in Mecca (Qibla)',
    'Intention is in the heart, not verbalized',
    'Specify which salah you are performing (e.g., Fard Fajr)',
  ],
);

// ─── During Salah ─────────────────────────────────────────────────────────────
const _takbir = SalahStep(
  id: 'takbir',
  arabicName: 'تَكْبِيرَةُ الْإِحْرَام',
  englishName: 'Opening Takbir',
  phase: 'during',
  icon: Icons.record_voice_over_outlined,
  shortDesc: 'Say Allahu Akbar to enter prayer',
  detailDesc:
      'The Takbiratul Ihram inaugurates the prayer. '
      'Raise hands to shoulder level with fingertips reaching the level of ears. '
      'Place the right hand over the left hand on the chest (either placing right palm over left arm or gripping left wrist). '
      'Command your eyes to look only at the spot of prostration.',
  keyPoints: [
    'Say "Allahu Akbar"',
    'Raise palms to shoulder level, fingertips to ears',
    'Place right hand over left hand on the chest',
    'Look strictly at the spot of prostration',
  ],
  duas: [
    SalahDua(
      arabic: 'اللَّهُ أَكْبَر',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
    ),
  ],
);

const _qiyamFirstRak = SalahStep(
  id: 'qiyam_first',
  arabicName: 'الْقِيَام',
  englishName: 'Qiyam (First Rak\'ah)',
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: 'Stand upright and recite Al-Fatihah + Surah',
  detailDesc:
      'Stand for obligatory prayers if physically able. '
      'Begin with Dua al-Istiftah. Then seek refuge and recite Al-Fatihah — this is a mandatory pillar. '
      'You must move your tongue and lips. Mere mental reading invalidates the recitation. '
      'Pause at the end of every verse. Then recite an optional Surah without pausing after Al-Fatihah.',
  keyPoints: [
    'Recite opening du\'a (Istiftah) silently',
    'Say A\'udhu billahi minash-shaytanir-rajim',
    'Recite Surah Al-Fatihah — moving lips and pausing at every verse',
    'Recite an additional surah directly after',
  ],
  duas: [
    SalahDua(
      arabic:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلَهَ غَيْرُكَ',
      transliteration:
          'Subhanaka Allahumma wa bihamdika, wa tabarakasmuka, wa ta\'ala jadduka, wa la ilaha ghayruka',
      translation:
          'Glory be to You, O Allah, and all praise is Yours. Blessed is Your name, high is Your majesty, and there is no deity besides You.',
    ),
    SalahDua(
      arabic:
          'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      transliteration:
          'Al-hamdu lillahi rabb il-\'alamin. Ar-rahman ir-rahim...',
      translation:
          'Praise be to Allah, Lord of the worlds. The Most Merciful, the Most Compassionate...',
    ),
  ],
);

const _qiyamSubsequentRakWithSurah = SalahStep(
  id: 'qiyam_second',
  arabicName: 'الْقِيَام',
  englishName: 'Qiyam (Second Rak\'ah)',
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: 'Stand upright and recite Al-Fatihah + Surah',
  detailDesc:
      'Stand upright, hands folded over the chest. '
      'Recite Bismillah and Surah Al-Fatihah — mandatory in every rak\'ah (moving lips and pausing at verses). '
      'Follow it with another surah or a few verses.',
  keyPoints: [
    'Say Bismillahir-rahmanir-rahim',
    'Recite Surah Al-Fatihah',
    'Recite an additional surah',
  ],
);

const _qiyamSubsequentRakFatihahOnly = SalahStep(
  id: 'qiyam_fatihah',
  arabicName: 'الْقِيَام',
  englishName: 'Qiyam (Third/Fourth Rak\'ah)',
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: 'Stand upright and recite Al-Fatihah only',
  detailDesc:
      'Stand upright, hands folded over the chest on the third/fourth rak\'ah. '
      'Recite Bismillah and Surah Al-Fatihah ONLY. Do not add another surah in the 3rd and 4th rak\'ah of Fard prayers.',
  keyPoints: [
    'Say Bismillahir-rahmanir-rahim',
    'Recite Surah Al-Fatihah (moving lips)',
    'Do not recite an additional surah (for Fard prayers)',
  ],
);

const _qiyamWitrThirdRak = SalahStep(
  id: 'qiyam_witr',
  arabicName: 'الْقِيَام وَالْقُنُوت',
  englishName: 'Qiyam & Qunut (Third Rak\'ah of Witr)',
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: 'Recite Al-Fatihah, a Surah, and Du\'a Qunut',
  detailDesc:
      'Stand upright. Recite Surah Al-Fatihah and an additional Surah. '
      'Then, raise your hands saying "Allahu Akbar," fold them again (or raise them in supplication), and recite Du\'a Qunut. '
      'After completing the Du\'a, say "Allahu Akbar" and go into Ruku\'.',
  keyPoints: [
    'Recite Surah Al-Fatihah and an additional Surah',
    'Say Allahu Akbar and optionally raise hands',
    'Recite Du\'a Qunut',
    'Say Allahu Akbar to go into Ruku\'',
  ],
  duas: [
    SalahDua(
      arabic:
          'اللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْر',
      transliteration:
          'Allahumma inna nasta\'inuka, wa nastaghfiruka, wa nu\'minu bika, wa natawakkalu \'alayka...',
      translation:
          'O Allah! We seek Your help and ask for Your forgiveness, and we believe in You and have trust in You...',
    ),
  ],
);

const _ruku = SalahStep(
  id: 'ruku',
  arabicName: 'الرُّكُوع',
  englishName: 'Ruku\' (Bowing)',
  phase: 'during',
  icon: Icons.airline_seat_flat_angled_rounded,
  shortDesc: 'Bow with hands on knees',
  detailDesc:
      'Say "Allahu Akbar" *while* moving (Takbir of movement). '
      'Keep your back straight (horizontal) and head level. Place palms on knees with fingers spread wide. '
      'Look at the spot of prostration or between the feet.',
  keyPoints: [
    'Say Allahu Akbar while moving down',
    'Back straight, horizontal with the head',
    'Palms grip knees, fingers spread wide',
    'Say tasbih at least once (preferably 3x)',
  ],
  duas: [
    SalahDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيم',
      transliteration: 'Subhana Rabbiyal \'Azim',
      translation: 'Glory be to my Lord, the Most Great',
    ),
  ],
);

const _iktidal = SalahStep(
  id: 'iktidal',
  arabicName: 'الِاعْتِدَال',
  englishName: 'I\'tidal (Rising from Ruku\')',
  phase: 'during',
  icon: Icons.height_rounded,
  shortDesc: 'Rise fully upright, praising Allah',
  detailDesc:
      'Rise from Ruku\' saying "Sami\'allahu liman hamidah" while rising. '
      'Once standing straight, say "Rabbana lakal hamd". '
      'Returning hands to chest or leaving at sides are both acceptable scholarly views.',
  keyPoints: [
    'Say Tasmee\' while rising up',
    'Stand fully straight',
    'Say Tahmid once fully upright',
  ],
  duas: [
    SalahDua(
      arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْد',
      transliteration: 'Sami\'Allahu liman hamidah. Rabbana wa lakal hamd.',
      translation:
          'Allah hears the one who praises Him. Our Lord, to You is all praise.',
    ),
  ],
);

const _sujud1 = SalahStep(
  id: 'sujud1',
  arabicName: 'السُّجُود الْأَوَّل',
  englishName: 'First Sujud (Prostration)',
  phase: 'during',
  icon: Icons.person_outline_rounded,
  shortDesc: 'Prostrate on seven limbs',
  detailDesc:
      'Say "Allahu Akbar" while descending. '
      'Land on hands first to avoid descending like a camel. '
      'Seven limbs must remain touching: Forehead+Nose (as one), Two Hands (palms flat towards Qibla), '
      'Two Knees, Two Sets of Toes (erect, facing Qibla). '
      'Keep forearms off the floor in a "winged" position, stomach away from thighs.',
  keyPoints: [
    'Land on hands first',
    'Seven limbs must touch the ground constantly',
    'Do not rest forearms on the floor (winged arms)',
    'Say tasbih at least once (preferably 3x)',
  ],
  duas: [
    SalahDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: 'Subhana Rabbiyal A\'la',
      translation: 'Glory be to my Lord, the Most High',
    ),
  ],
);

const _jalsa = SalahStep(
  id: 'jalsa',
  arabicName: 'الْجَلْسَة',
  englishName: 'Jalsah (Sitting Between Sujuds)',
  phase: 'during',
  icon: Icons.event_seat_rounded,
  shortDesc: 'Sit in Iftirash between prostrations',
  detailDesc:
      'Rise and sit on your left foot while keeping the right foot erect (Iftirash). '
      'You must say "Rabbighfirli" in this brief sitting pause.',
  keyPoints: [
    'Sit on the left foot (Iftirash)',
    'Keep right foot erect with toes pointing to Qibla',
    'Recite the forgiveness du\'a',
  ],
  duas: [
    SalahDua(
      arabic: 'رَبِّ اغْفِرْ لِي (٢x)',
      transliteration: 'Rabbighfirli (x2)',
      translation: 'Lord, forgive me (x2)',
    ),
    SalahDua(
      arabic:
          'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي',
      transliteration:
          'Rabbighfirli war-hamni wajburni warfa\'ni warzuqni wahdinii wa\'afini wa\'fu \'anni',
      translation:
          'O Lord, forgive me, have mercy on me, restore me, raise me, provide for me, guide me, grant me wellbeing, and pardon me.',
    ),
  ],
);

const _sujud2 = SalahStep(
  id: 'sujud2',
  arabicName: 'السُّجُود الثَّانِي',
  englishName: 'Second Sujud',
  phase: 'during',
  icon: Icons.person_outline_rounded,
  shortDesc: 'Prostrate a second time on seven limbs',
  detailDesc:
      'Perform the second prostration exactly like the first. Ensure all seven limbs remain grounded. '
      'Lifting a foot or hand to adjust clothing invalidates the prostration.',
  keyPoints: [
    'Ensure all 7 limbs touch throughout',
    'Do not rest forearms on the floor',
    'Say tasbih 3x',
  ],
  duas: [
    SalahDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: 'Subhana Rabbiyal A\'la',
      translation: 'Glory be to my Lord, the Most High',
    ),
  ],
);

const _jalsatIstiraha = SalahStep(
  id: 'jalsat_istiraha',
  arabicName: 'جَلْسَةُ الِاسْتِرَاحَة',
  englishName: 'Jalsat al-Istiraha (Pause of Rest)',
  phase: 'during',
  icon: Icons.hourglass_empty_rounded,
  shortDesc: 'Brief pause before standing up',
  detailDesc:
      'In Rak\'ahs where you will stand up immediately after (like the 1st or 3rd Rak\'ah), '
      'there is a Sunnah to briefly sit in the Iftirash position after the second Sujud, '
      'just for a moment, before rising up to stand for the next Rak\'ah.',
  keyPoints: [
    'Brief pause sitting down after second prostration',
    'Done before rising to the 2nd or 4th Rak\'ah',
  ],
);

const _firstTashahhud = SalahStep(
  id: 'tashahhud_first',
  arabicName: 'التَّشَهُّد الْأَوَّل',
  englishName: 'First Tashahhud',
  phase: 'during',
  icon: Icons.event_seat_outlined,
  shortDesc: 'Sit and recite At-Tahiyyat',
  detailDesc:
      'In a 3 or 4-Rak\'ah prayer, sit after the second rak\'ah in Iftirash (sit on left foot). '
      'Point the index finger toward the Qibla and move/wiggle it throughout the testimony. '
      'Recite the At-Tahiyyat only. Then say "Allahu Akbar" and stand up.',
  keyPoints: [
    'Sit in Iftirash',
    'Form a circle with thumb/middle finger, or a fist',
    'Point and wiggle index finger toward Qibla',
    'Recite At-Tahiyyat and stand up',
  ],
  duas: [
    SalahDua(
      arabic:
          'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration:
          'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu \'alayka ayyuhan-nabiyyu...',
      translation:
          'All greetings, prayers and good words are for Allah. Peace be upon you, O Prophet...',
    ),
  ],
);

const _finalTashahhud = SalahStep(
  id: 'tashahhud_final',
  arabicName: 'التَّشَهُّد الْأَخِير',
  englishName: 'Final Tashahhud & Protections',
  phase: 'during',
  icon: Icons.event_seat_outlined,
  shortDesc: 'Sit in Tawarruk, recite Tashahhud, Salawat & Du\'a',
  detailDesc:
      'In the final sitting of a multi-Rakah prayer, use the Tawarruk position '
      '(sit on left hip, tuck left foot under right leg, right foot erect). '
      'Point and wiggle the index finger. Recite At-Tahiyyat, Salawat, and crucially: '
      'seek refuge from the 4 trials before giving Salam.',
  keyPoints: [
    'Sit in Tawarruk position',
    'Point and wiggle the index finger',
    'Recite At-Tahiyyat and Salawat (Durood)',
    'Seek refuge from Hellfire, Grave, Life/Death trials, and Dajjal',
  ],
  duas: [
    SalahDua(
      arabic:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      transliteration:
          'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad, kama sallayta \'ala Ibrahima...',
      translation:
          'O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim...',
    ),
    SalahDua(
      arabic:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ، وَمِنْ عَذَابِ الْقَبْرِ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ',
      transliteration:
          'Allahumma inni a\'udhu bika min \'adhabi Jahannam, wa min \'adhabil-qabr, wa min fitnatil-mahya wal-mamat, wa min sharri fitnatil-masihid-dajjal.',
      translation:
          'O Allah, I seek refuge with You from the punishment of Hellfire, from the punishment of the grave, from the trials of life and death, and from the evil trial of the False Messiah (Dajjal).',
    ),
  ],
);

const _salam = SalahStep(
  id: 'salam',
  arabicName: 'التَّسْلِيم',
  englishName: 'Salam (Closing)',
  phase: 'during',
  icon: Icons.waving_hand_outlined,
  shortDesc: 'Simultaneous head turn and Salam',
  detailDesc:
      'Conclude by saying the Salam to the right and then the left. '
      'Technical Requirement: The movement of the head must be simultaneous with the speech. '
      'Do not say the phrase then turn, or turn then say the phrase. '
      'Your cheek should be visible. Do not wave or move your hands.',
  keyPoints: [
    'Turn head right simultaneously while saying Salam',
    'Turn head left simultaneously while saying Salam',
    'Do not move/wave hands',
  ],
  duas: [
    SalahDua(
      arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّه',
      transliteration: 'As-Salamu \'Alaykum wa Rahmatullah',
      translation: 'Peace and the mercy of Allah be upon you',
    ),
  ],
);

// ─── Vital Warnings ───────────────────────────────────────────────────────────
const _vitalWarnings = SalahStep(
  id: 'vital_warnings',
  arabicName: 'تَحْذِيرَاتٌ هَامَّة',
  englishName: 'Vital Warnings & Common Mistakes',
  phase: 'after',
  icon: Icons.warning_amber_rounded,
  shortDesc: 'Things to avoid during your prayer',
  detailDesc:
      '• Recitation Validity: You must move your tongue and lips. Silent mental scanning invalidates prayer.\n'
      '• Racing the Imam: Never anticipate the Imam. Do not bend your back until his forehead touches the ground.\n'
      '• Closing Eyes: Pray with eyes open unless avoiding an extreme distraction.\n'
      '• Incomplete Sujud: Lifting feet or failing to touch your nose to the ground invalidates Sujud.\n'
      '• Submissiveness (Khushu): Do not lose the spirit of worship over technical obsessions.',
  keyPoints: [
    'Move tongue and lips during recitation',
    'Follow the Imam, never preempt him',
    'Keep eyes open, looking at prostration point',
    'Keep 7 limbs on the ground in Sujud',
  ],
);

// ─── Base arrays ──────────────────────────────────────────────────────────────
const _baseStartSteps = [_conditions, _wudu, _qiblaNiyyah];
const _baseRakStepsWithSurahAndIstiraha = [
  _takbir,
  _qiyamFirstRak,
  _ruku,
  _iktidal,
  _sujud1,
  _jalsa,
  _sujud2,
  _jalsatIstiraha,
];
const _baseRakStepsWithSurahOnly = [
  _qiyamSubsequentRakWithSurah,
  _ruku,
  _iktidal,
  _sujud1,
  _jalsa,
  _sujud2,
];
const _baseRakStepsFatihahOnlyWithIstiraha = [
  _qiyamSubsequentRakFatihahOnly,
  _ruku,
  _iktidal,
  _sujud1,
  _jalsa,
  _sujud2,
  _jalsatIstiraha,
];
const _baseRakStepsFatihahOnly = [
  _qiyamSubsequentRakFatihahOnly,
  _ruku,
  _iktidal,
  _sujud1,
  _jalsa,
  _sujud2,
];
const _baseEndSteps = [_finalTashahhud, _salam, _vitalWarnings];

// ─── Exported Data Arrays ──────────────────────────────────────────────────
final List<SalahTypeData> salahTypesData = [
  SalahTypeData(
    id: '2_rakah',
    title: '2 Rak\'ahs Prayer',
    subtitle: 'Fajr Fard, Sunnah prayers, Nafl',
    arabicTitle: 'صلاة ركعتين',
    icon: Icons.looks_two_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: 'First Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: 'Second Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: _baseRakStepsWithSurahOnly,
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '3_rakah_maghrib',
    title: '3 Rak\'ahs (Maghrib)',
    subtitle: 'Maghrib Fard prayer',
    arabicTitle: 'صلاة المغرب ٣ ركعات',
    icon: Icons.looks_3_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: 'First Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: 'Second Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [..._baseRakStepsWithSurahOnly, _firstTashahhud],
      ),
      const SalahSection(
        title: 'Third Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّالِثَة',
        steps: _baseRakStepsFatihahOnly,
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '4_rakah',
    title: '4 Rak\'ahs Prayer',
    subtitle: 'Dhuhr, Asr, Isha Fard & Sunnah',
    arabicTitle: 'صلاة ٤ ركعات',
    icon: Icons.looks_4_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: 'First Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: 'Second Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [..._baseRakStepsWithSurahOnly, _firstTashahhud],
      ),
      const SalahSection(
        title: 'Third Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّالِثَة',
        steps: _baseRakStepsFatihahOnlyWithIstiraha,
      ),
      const SalahSection(
        title: 'Fourth Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الرَّابِعَة',
        steps: _baseRakStepsFatihahOnly,
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '3_rakah_witr',
    title: '3 Rak\'ahs Witr',
    subtitle: 'Witr prayer after Isha',
    arabicTitle: 'صلاة الوتر ٣ ركعات',
    icon: Icons.nightlight_round,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: 'First Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: 'Second Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [..._baseRakStepsWithSurahOnly, _firstTashahhud],
      ),
      const SalahSection(
        title: 'Third Rak\'ah (Witr)',
        arabicTitle: 'الرَّكْعَةُ الثَّالِثَة',
        steps: [_qiyamWitrThirdRak, _ruku, _iktidal, _sujud1, _jalsa, _sujud2],
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '1_rakah_witr',
    title: '1 Rak\'ah Witr',
    subtitle: 'Short Witr prayer',
    arabicTitle: 'صلاة الوتر ركعة',
    icon: Icons.mode_night_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: 'First Rak\'ah (Witr)',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: [
          _takbir,
          _qiyamWitrThirdRak,
          _ruku,
          _iktidal,
          _sujud1,
          _jalsa,
          _sujud2,
        ],
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),

  // ─── Funeral Prayer (Janazah) ─────────────────────────────────────────
  SalahTypeData(
    id: 'janazah',
    title: 'Salat al-Janazah',
    subtitle: 'Funeral prayer — 4 Takbirs, no Ruku\' / Sujud',
    arabicTitle: 'صلاة الجنازة',
    icon: Icons.mosque_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: [_conditions, _qiblaNiyyah],
      ),
      SalahSection(
        title: 'First Takbir',
        arabicTitle: 'التَّكْبِيرَةُ الْأُولَى',
        steps: [
          SalahStep(
            id: 'janazah_takbir1',
            arabicName: 'التَّكْبِيرَةُ الْأُولَى',
            englishName: '1st Takbir — Recite Al-Fatihah',
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: 'Say Allahu Akbar, then recite Al-Fatihah',
            detailDesc:
                'Say "Allahu Akbar" raising both hands. Then recite Surah Al-Fatihah silently.',
            keyPoints: [
              'Say Allahu Akbar and raise hands',
              'Recite Al-Fatihah silently',
            ],
          ),
        ],
      ),
      SalahSection(
        title: 'Second Takbir',
        arabicTitle: 'التَّكْبِيرَةُ الثَّانِيَة',
        steps: [
          SalahStep(
            id: 'janazah_takbir2',
            arabicName: 'التَّكْبِيرَةُ الثَّانِيَة',
            englishName: '2nd Takbir — Salawat upon the Prophet ﷺ',
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: 'Say Allahu Akbar, then send Salawat',
            detailDesc:
                'Say "Allahu Akbar" (without raising hands). Then recite the Ibrahimi Salawat, '
                'i.e. "Allahumma salli \'ala Muhammad..." exactly as in the last sitting of regular salah.',
            keyPoints: ['Say Allahu Akbar', 'Recite the full Ibrahimi Salawat'],
            duas: [
              SalahDua(
                arabic:
                    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
                transliteration:
                    'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad...',
                translation:
                    'O Allah, send prayers upon Muhammad and his family...',
              ),
            ],
          ),
        ],
      ),
      SalahSection(
        title: 'Third Takbir',
        arabicTitle: 'التَّكْبِيرَةُ الثَّالِثَة',
        steps: [
          SalahStep(
            id: 'janazah_takbir3',
            arabicName: 'التَّكْبِيرَةُ الثَّالِثَة',
            englishName: '3rd Takbir — Du\'a for the Deceased',
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: 'Say Allahu Akbar, then make du\'a',
            detailDesc:
                'Say "Allahu Akbar". Then make du\'a for the deceased. '
                'There are several authentic du\'as for this.',
            keyPoints: [
              'Say Allahu Akbar',
              'Recite a du\'a for the deceased sincerely',
            ],
            duas: [
              SalahDua(
                arabic:
                    'اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ وَعَافِهِ وَاعْفُ عَنْهُ، وَأَكْرِمْ نُزُلَهُ وَوَسِّعْ مُدْخَلَهُ، وَاغْسِلْهُ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ',
                transliteration:
                    'Allahummaghfir lahu warhamhu wa \'afihi wa\'fu \'anhu, wa akrim nuzulahu wa wassi\' mudkhalahu...',
                translation:
                    'O Allah, forgive him, have mercy on him, grant him ease and pardon him. Honour his resting place and expand his entry; wash him with water, snow and hail.',
              ),
              SalahDua(
                arabic:
                    'اللَّهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَشَاهِدِنَا وَغَائِبِنَا وَصَغِيرِنَا وَكَبِيرِنَا وَذَكَرِنَا وَأُنْثَانَا',
                transliteration:
                    'Allahummaghfir lihayyina wa mayyitina, wa shahidina wa gha\'ibina, wa sagheerina wa kabeerina, wa dhakarina wa unthana.',
                translation:
                    'O Allah, forgive our living and our dead, those present among us and those absent, our young and our old, our males and our females.',
              ),
            ],
          ),
        ],
      ),
      SalahSection(
        title: 'Fourth Takbir',
        arabicTitle: 'التَّكْبِيرَةُ الرَّابِعَة',
        steps: [
          SalahStep(
            id: 'janazah_takbir4',
            arabicName: 'التَّكْبِيرَةُ الرَّابِعَة وَالتَّسْلِيم',
            englishName: '4th Takbir & Salam',
            phase: 'during',
            icon: Icons.waving_hand_outlined,
            shortDesc: 'Say Allahu Akbar, then give Salam',
            detailDesc:
                'Say "Allahu Akbar" once more. You may make a brief du\'a. '
                'Then conclude with one Salam to the right.',
            keyPoints: [
              'Say Allahu Akbar',
              'Optionally make a short du\'a',
              'Give one Salam to the right',
            ],
            duas: [
              SalahDua(
                arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّه',
                transliteration: 'As-Salamu \'Alaykum wa Rahmatullah',
                translation: 'Peace and the mercy of Allah be upon you.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // ─── Eid Prayer ──────────────────────────────────────────────────────
  SalahTypeData(
    id: 'eid',
    title: 'Eid Prayer',
    subtitle: '2 Rak\'ahs with extra Takbirs',
    arabicTitle: 'صلاة العيد',
    icon: Icons.celebration_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      SalahSection(
        title: 'First Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: [
          SalahStep(
            id: 'eid_takbirs_1',
            arabicName: 'تَكْبِيرَاتُ الْإِحْرَامِ وَالزَّوَائِد',
            englishName: 'Opening Takbir + 7 Extra Takbirs',
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: 'Say opening Takbir, followed by 7 extra Takbirs',
            detailDesc:
                'Say the Takbiratul Ihram, then say "Allahu Akbar" 7 additional times, '
                'raising your hands with each one. After the extra Takbirs, seek refuge '
                'and recite Al-Fatihah and a Surah (Surah Al-A\'la is Sunnah).',
            keyPoints: [
              'Opening Takbir (Takbiratul Ihram)',
              '7 additional Takbirs with hands raised',
              'Recite Al-Fatihah',
              'Recite Surah Al-A\'la or another Surah',
            ],
          ),
          _ruku,
          _iktidal,
          _sujud1,
          _jalsa,
          _sujud2,
          _jalsatIstiraha,
        ],
      ),
      SalahSection(
        title: 'Second Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [
          SalahStep(
            id: 'eid_takbirs_2',
            arabicName: 'خَمْسُ تَكْبِيرَاتٍ زَائِدَة',
            englishName: 'Qiyam + 5 Extra Takbirs',
            phase: 'during',
            icon: Icons.accessibility_new_rounded,
            shortDesc: 'Say 5 extra Takbirs then recite Al-Fatihah + Surah',
            detailDesc:
                'Upon standing, say "Allahu Akbar" 5 additional times raising your hands '
                'with each. Then recite Al-Fatihah and a Surah (Surah Al-Ghashiyah is Sunnah).',
            keyPoints: [
              '5 additional Takbirs with hands raised',
              'Recite Al-Fatihah',
              'Recite Surah Al-Ghashiyah or another Surah',
            ],
          ),
          _ruku,
          _iktidal,
          _sujud1,
          _jalsa,
          _sujud2,
        ],
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: [_finalTashahhud, _salam],
      ),
    ],
  ),

  // ─── Tarawih / Tahajjud ───────────────────────────────────────────────
  SalahTypeData(
    id: 'tarawih',
    title: 'Tarawih / Tahajjud',
    subtitle: '2 Rak\'ahs at a time, with long Qiyam',
    arabicTitle: 'صلاة التراويح / التهجد',
    icon: Icons.dark_mode_rounded,
    sections: [
      const SalahSection(
        title: 'Before Salah',
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      SalahSection(
        title: 'First Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: [
          _takbir,
          SalahStep(
            id: 'tarawih_qiyam1',
            arabicName: 'الْقِيَام',
            englishName: 'Qiyam — Long Recitation',
            phase: 'during',
            icon: Icons.accessibility_new_rounded,
            shortDesc: 'Stand and recite Al-Fatihah + a long portion of Quran',
            detailDesc:
                'After the opening du\'a, recite Al-Fatihah followed by a long '
                'portion of the Quran. Tarawih and Tahajjud are characterised by lengthing '
                'the recitation in Qiyam as much as is comfortable.',
            keyPoints: [
              'Recite opening Istiftah du\'a',
              'Recite Al-Fatihah + a long Surah or several shorter Surahs',
              'Lengthen the standing as much as comfortable',
            ],
          ),
          _ruku,
          _iktidal,
          _sujud1,
          _jalsa,
          _sujud2,
          _jalsatIstiraha,
        ],
      ),
      SalahSection(
        title: 'Second Rak\'ah',
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [
          SalahStep(
            id: 'tarawih_qiyam2',
            arabicName: 'الْقِيَام',
            englishName: 'Qiyam — Long Recitation',
            phase: 'during',
            icon: Icons.accessibility_new_rounded,
            shortDesc: 'Stand and recite Al-Fatihah + a long portion of Quran',
            detailDesc:
                'Recite Al-Fatihah followed by a continuation of the Quran. '
                'Then proceed to Ruku\' and Sujud as normal.',
            keyPoints: [
              'Recite Al-Fatihah + another long portion',
              'Proceed to Ruku\' and Sujud normally',
            ],
          ),
          _ruku,
          _iktidal,
          _sujud1,
          _jalsa,
          _sujud2,
        ],
      ),
      const SalahSection(
        title: 'After Salah',
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
      SalahSection(
        title: 'Note',
        arabicTitle: 'مُلَاحَظَة',
        steps: [
          SalahStep(
            id: 'tarawih_note',
            arabicName: 'مُلَاحَظَة',
            englishName: 'Repeat in Sets of 2',
            phase: 'after',
            icon: Icons.info_outline_rounded,
            shortDesc: 'Pray in sets of 2 Rak\'ahs, then finish with Witr',
            detailDesc:
                'Tarawih is prayed in sets of 2 Rak\'ahs. After every 2 Rak\'ahs, '
                'give Salam and start a new set. You may pray 8, 12, or 20 Rak\'ahs. '
                'Always conclude the night prayer with Witr (1 or 3 Rak\'ahs).',
            keyPoints: [
              'Pray in sets of 2',
              'Give Salam between each set',
              'Conclude with Witr prayer',
            ],
          ),
        ],
      ),
    ],
  ),
];
