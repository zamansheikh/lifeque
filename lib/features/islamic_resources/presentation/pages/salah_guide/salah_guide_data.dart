import 'package:flutter/material.dart';
import 'salah_step_model.dart';

// ─── Common/Reusable Steps ─────────────────────────────────────────────────────
const _niyyah = SalahStep(
  id: 'niyyah',
  arabicName: 'نِيَّة',
  englishName: 'Intention (Niyyah)',
  phase: 'before',
  icon: Icons.favorite_border_rounded,
  shortDesc: 'Make the intention in your heart',
  detailDesc:
      'Niyyah is the sincere intention in the heart to perform the prayer for the sake of Allah. '
      'It does not need to be uttered aloud — it is a matter of the heart. '
      'You should intend which prayer you are performing and that it is fard (obligatory) or sunnah.',
  keyPoints: [
    'Intention is in the heart, not the tongue',
    'Specify which salah you are performing',
    'Intend it purely for the sake of Allah',
    'Form the intention before starting Takbir',
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
);

const _qibla = SalahStep(
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
);

const _takbir = SalahStep(
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
);

const _qiyamFirstRak = SalahStep(
  id: 'qiyam_first',
  arabicName: 'الْقِيَام',
  englishName: 'Qiyam (First Rak\'ah)',
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: 'Stand upright and recite Al-Fatihah + Surah',
  detailDesc:
      'In Qiyam you stand upright, hands folded over the chest. '
      'Begin with the opening du\'a (Istiftah), then seek refuge (Ta\'awwudh), '
      'then recite Bismillah and Surah Al-Fatihah — which is obligatory in every rak\'ah. '
      'Follow it with another surah or a few verses.',
  keyPoints: [
    'Recite opening du\'a silently (Subhanakallahumma wa bihamdika...)',
    'Say A\'udhu billahi minash-shaytanir-rajim',
    'Say Bismillahir-rahmanir-rahim',
    'Recite Surah Al-Fatihah — obligatory in every rak\'ah',
    'Recite an additional surah',
  ],
  arabicDua:
      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
  transliteration:
      'Al-hamdu lillahi rabb il-\'alamin. Ar-rahman ir-rahim. Maliki yawm id-din. Iyyaka na\'budu wa iyyaka nasta\'in. Ihdinas-sirat al-mustaqim.',
  translation:
      'Praise be to Allah, Lord of the worlds. The Most Merciful, the Most Compassionate. Master of the Day of Judgment. It is You we worship and You alone we ask for help. Guide us to the straight path.',
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
      'Recite Bismillah and Surah Al-Fatihah — which is obligatory in every rak\'ah. '
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
      'Stand upright, hands folded over the chest. '
      'Recite Bismillah and Surah Al-Fatihah ONLY. Do not add another surah in the 3rd and 4th rak\'ah of obligatory (Fard) prayers.',
  keyPoints: [
    'Say Bismillahir-rahmanir-rahim',
    'Recite Surah Al-Fatihah',
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
      'Then, raise your hands to your earlobes saying "Allahu Akbar," fold them again, and recite Du\'a Qunut. '
      'After completing the Du\'a, say "Allahu Akbar" and go into Ruku\'.',
  keyPoints: [
    'Recite Surah Al-Fatihah and an additional Surah',
    'Say Allahu Akbar and raise hands to earlobes',
    'Fold hands again and recite Du\'a Qunut',
    'Say Allahu Akbar to go into Ruku\'',
  ],
  arabicDua:
      'اللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْر',
  transliteration:
      'Allahumma inna nasta\'inuka, wa nastaghfiruka, wa nu\'minu bika, wa natawakkalu \'alayka, wa nuthni \'alaykal-khayr',
  translation:
      'O Allah! We seek Your help and ask for Your forgiveness, and we believe in You and have trust in You, and we praise You in the best way.',
);

const _ruku = SalahStep(
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
    'Say tasbih at least 3 times',
  ],
  arabicDua: 'سُبْحَانَ رَبِّيَ الْعَظِيم',
  transliteration: 'Subhana Rabbiyal \'Azim',
  translation: 'Glory be to my Lord, the Most Great',
);

const _iktidal = SalahStep(
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
    'Stand still for a moment, then say the tahmid',
  ],
  arabicDua: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْد',
  transliteration: 'Sami\'Allahu liman hamidah. Rabbana wa lakal hamd.',
  translation:
      'Allah hears the one who praises Him. Our Lord, to You is all praise.',
);

const _sujud1 = SalahStep(
  id: 'sujud1',
  arabicName: 'السُّجُود الْأَوَّل',
  englishName: 'First Sujud (Prostration)',
  phase: 'during',
  icon: Icons.person_outline_rounded,
  shortDesc: 'Prostrate on seven body parts',
  detailDesc:
      'Prostrate with seven bones touching the ground: forehead (with nose), two palms, '
      'two knees, and two sets of toes. The forehead should be placed firmly on the ground. '
      'Arms should not rest on the ground (elbows up, away from the body).',
  keyPoints: [
    'Seven body parts on ground: forehead+nose, 2 palms, 2 knees, toes',
    'Say tasbih at least 3 times',
  ],
  arabicDua: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
  transliteration: 'Subhana Rabbiyal A\'la',
  translation: 'Glory be to my Lord, the Most High',
);

const _jalsa = SalahStep(
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
    'Recite the sitting du\'a (Rabbighfirli)',
  ],
  arabicDua:
      'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي',
  transliteration:
      'Rabbighfirli war-hamni wajburni warfa\'ni warzuqni wahdinii wa\'afini wa\'fu \'anni',
  translation:
      'O Lord, forgive me, have mercy on me, restore me, raise me, provide for me, guide me, grant me wellbeing, and pardon me.',
);

const _sujud2 = SalahStep(
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
    'Say tasbih at least 3 times',
    'After this completes the rak\'ah',
  ],
  arabicDua: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
  transliteration: 'Subhana Rabbiyal A\'la',
  translation: 'Glory be to my Lord, the Most High',
);

const _firstTashahhud = SalahStep(
  id: 'tashahhud_first',
  arabicName: 'التَّشَهُّد الْأَوَّل',
  englishName: 'First Tashahhud',
  phase: 'during',
  icon: Icons.event_seat_outlined,
  shortDesc: 'Sit and recite At-Tahiyyat',
  detailDesc:
      'In a 3 or 4-Rak\'ah prayer, sit after the second rak\'ah. '
      'Recite the Tashahhud (At-Tahiyyat) only. Once completed, say "Allahu Akbar" and immediately stand up for the third rak\'ah.',
  keyPoints: [
    'Raise index finger during the Shahadah phrase',
    'Recite At-Tahiyyat only',
    'Stand up for the next rak\'ah immediately after finishing',
  ],
  arabicDua:
      'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
  transliteration:
      'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu \'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu \'alayna wa \'ala \'ibadillahis-salihin. Ash-hadu alla ilaha illallah wa ash-hadu anna Muhammadan \'abduhu wa rasoluhu.',
  translation:
      'All greetings, prayers and good words are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah and I bear witness that Muhammad is His slave and Messenger.',
);

const _finalTashahhud = SalahStep(
  id: 'tashahhud_final',
  arabicName: 'التَّشَهُّد الْأَخِير',
  englishName: 'Final Tashahhud & Salawat',
  phase: 'during',
  icon: Icons.event_seat_outlined,
  shortDesc: 'Sit and recite Tashahhud, Salawat & Du\'a',
  detailDesc:
      'In the final sitting, sit in the Tawarruk position (left thigh on ground). '
      'Recite the Tashahhud (At-Tahiyyat), followed by Salawat (Durood Ibrahim), '
      'and end with a closing du\'a (Du\'a Masura) before giving Salam.',
  keyPoints: [
    'Raise index finger during the Shahadah',
    'Recite At-Tahiyyat fully',
    'Recite Salawat (Durood Ibrahim)',
    'Recite a closing Du\'a (e.g. Rabbana Atina...)',
  ],
  arabicDua:
      'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
  transliteration:
      'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad, kama sallayta \'ala Ibrahima wa \'ala ali Ibrahim, innaka Hamidun Majid.',
  translation:
      'O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim; You are indeed Worthy of Praise, Full of Glory.',
);

const _salam = SalahStep(
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
  ],
  arabicDua: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّه',
  transliteration: 'As-Salamu \'Alaykum wa Rahmatullah',
  translation: 'Peace and the mercy of Allah be upon you',
);

const _tasbihAfter = SalahStep(
  id: 'tasbih_after',
  arabicName: 'الِاسْتِغْفَار وَالتَّسْبِيح',
  englishName: 'Istighfar & Tasbih',
  phase: 'after',
  icon: Icons.volunteer_activism_outlined,
  shortDesc: 'Seek forgiveness and glorify Allah',
  detailDesc:
      'Immediately after the Salam, say Astaghfirullah three times. '
      'Count on your fingers: Subhanallah 33 times, Alhamdulillah 33 times, Allahu Akbar 34 times.',
  keyPoints: [
    'Say Astaghfirullah 3 times',
    'Subhanallah × 33, Alhamdulillah × 33, Allahu Akbar × 34',
  ],
  arabicDua: 'أَسْتَغْفِرُ اللَّهَ (٣x)',
  transliteration: 'Astaghfirullah (x3)',
  translation: 'I seek forgiveness from Allah',
);

const _baseStartSteps = [_niyyah, _wudu, _qibla, _takbir];
const _baseRakStepsWithSurah = [
  _qiyamSubsequentRakWithSurah,
  _ruku,
  _iktidal,
  _sujud1,
  _jalsa,
  _sujud2,
];
const _baseRakStepsFatihahOnly = [
  _qiyamSubsequentRakFatihahOnly,
  _ruku,
  _iktidal,
  _sujud1,
  _jalsa,
  _sujud2,
];
const _baseEndSteps = [_finalTashahhud, _salam, _tasbihAfter];

// ─── Exported Data Arrays ──────────────────────────────────────────────────
final List<SalahTypeData> salahTypesData = [
  SalahTypeData(
    id: '2_rakah',
    title: '2 Rak\'ahs Prayer',
    subtitle: 'Fajr Fard, Sunnah prayers, Nafl',
    arabicTitle: 'صلاة ركعتين',
    icon: Icons.looks_two_rounded,
    steps: [
      ..._baseStartSteps,
      _qiyamFirstRak, _ruku, _iktidal, _sujud1, _jalsa, _sujud2, // Rak'ah 1
      ..._baseRakStepsWithSurah, // Rak'ah 2
      ..._baseEndSteps, // Ending
    ],
  ),
  SalahTypeData(
    id: '3_rakah_maghrib',
    title: '3 Rak\'ahs (Maghrib)',
    subtitle: 'Maghrib Fard prayer',
    arabicTitle: 'صلاة المغرب ٣ ركعات',
    icon: Icons.looks_3_rounded,
    steps: [
      ..._baseStartSteps,
      _qiyamFirstRak, _ruku, _iktidal, _sujud1, _jalsa, _sujud2, // Rak'ah 1
      ..._baseRakStepsWithSurah, // Rak'ah 2
      _firstTashahhud,
      ..._baseRakStepsFatihahOnly, // Rak'ah 3 (no surah)
      ..._baseEndSteps, // Ending
    ],
  ),
  SalahTypeData(
    id: '4_rakah',
    title: '4 Rak\'ahs Prayer',
    subtitle: 'Dhuhr, Asr, Isha Fard & Sunnah',
    arabicTitle: 'صلاة ٤ ركعات',
    icon: Icons.looks_4_rounded,
    steps: [
      ..._baseStartSteps,
      _qiyamFirstRak, _ruku, _iktidal, _sujud1, _jalsa, _sujud2, // Rak'ah 1
      ..._baseRakStepsWithSurah, // Rak'ah 2
      _firstTashahhud,
      ..._baseRakStepsFatihahOnly, // Rak'ah 3
      ..._baseRakStepsFatihahOnly, // Rak'ah 4
      ..._baseEndSteps, // Ending
    ],
  ),
  SalahTypeData(
    id: '3_rakah_witr',
    title: '3 Rak\'ahs Witr',
    subtitle: 'Witr prayer after Isha',
    arabicTitle: 'صلاة الوتر ٣ ركعات',
    icon: Icons.nightlight_round,
    steps: [
      ..._baseStartSteps,
      _qiyamFirstRak, _ruku, _iktidal, _sujud1, _jalsa, _sujud2, // Rak'ah 1
      ..._baseRakStepsWithSurah, // Rak'ah 2
      _firstTashahhud,
      _qiyamWitrThirdRak,
      _ruku,
      _iktidal,
      _sujud1,
      _jalsa,
      _sujud2, // Rak'ah 3 (witr qiyam)
      ..._baseEndSteps, // Ending
    ],
  ),
  SalahTypeData(
    id: '1_rakah_witr',
    title: '1 Rak\'ah Witr',
    subtitle: 'Short Witr prayer',
    arabicTitle: 'صلاة الوتر ركعة',
    icon: Icons.mode_night_rounded,
    steps: [
      ..._baseStartSteps,
      _qiyamWitrThirdRak, // Rak'ah 1 (witr qiyam with dua qunut)
      _ruku, _iktidal, _sujud1, _jalsa, _sujud2,
      ..._baseEndSteps, // Ending
    ],
  ),
];
