import 'package:flutter/material.dart';
import 'salah_step_model.dart';

// ─── Constants for Purity/Conditions (Before Salah) ──────────────────────────
const _conditions = SalahStep(
  id: 'conditions',
  arabicName: 'شُرُوطُ الصَّلَاة',
  name: LText('Essential Conditions (Shurut)', 'নামাজের শর্তসমূহ (শুরূত)'),
  phase: 'before',
  icon: Icons.assignment_turned_in_outlined,
  shortDesc: LText(
    'Ensure time, awrah, purity, qibla, and niyyah',
    'ওয়াক্ত, সতর, পবিত্রতা, কিবলা ও নিয়ত ঠিক করুন',
  ),
  detailDesc: LText(
    'You must fulfill these conditions before prayer begins. A deficiency in any of these renders the prayer void:\n• Time: Ensure the prayer time has entered.\n• Awrah: Cover your private areas appropriately.\n• Purity: Attain ritual purity (Wudu/Ghusl) and physical purity (body, clothes, spot of prayer).\n• Qibla: Face the Kaaba in Mecca.\n• Niyyah: Establish the specific intention in your heart.',
    'নামাজ শুরুর আগে এই শর্তগুলো পূরণ করতে হবে। এর কোনো একটিতে ঘাটতি থাকলে নামাজ শুদ্ধ হবে না:\n• ওয়াক্ত: নামাজের সময় হয়েছে কি না নিশ্চিত হোন।\n• সতর: শরীরের যে অংশ ঢাকা ফরজ তা যথাযথভাবে ঢাকুন।\n• পবিত্রতা: ওজু/গোসলের মাধ্যমে পবিত্রতা এবং শরীর, কাপড় ও নামাজের জায়গা নাপাকিমুক্ত রাখুন।\n• কিবলা: মক্কার কাবামুখী হোন।\n• নিয়ত: কোন নামাজ পড়ছেন তা মনে মনে ঠিক করুন।',
  ),
  keyPoints: [
    LText('Time must have entered properly', 'নামাজের ওয়াক্ত হয়ে থাকতে হবে'),
    LText('Cover the Awrah completely', 'সতর পুরোপুরি ঢাকতে হবে'),
    LText(
      'Ensure Wudu/Ghusl is performed',
      'ওজু/গোসল করা আছে কি না নিশ্চিত হোন',
    ),
    LText(
      'Body, clothes, and prayer spot must be free of impurities',
      'শরীর, কাপড় ও নামাজের জায়গা নাপাকিমুক্ত হতে হবে',
    ),
    LText('Face the Qibla (Kaaba)', 'কিবলামুখী (কাবামুখী) হোন'),
    LText(
      'Intend the specific prayer in the heart',
      'কোন নামাজ পড়ছেন তা মনে মনে নিয়ত করুন',
    ),
  ],
);

const _wudu = SalahStep(
  id: 'wudu',
  arabicName: 'الوُضُوء',
  name: LText('Wudu (Ablution)', 'ওজু'),
  phase: 'before',
  icon: Icons.water_drop_outlined,
  shortDesc: LText(
    'Purify with ritual ablution',
    'ওজুর মাধ্যমে পবিত্রতা অর্জন করুন',
  ),
  detailDesc: LText(
    'Wudu is the ritual purification with water that is required before performing Salah. Without wudu, the prayer is not valid.',
    'ওজু হলো পানি দিয়ে পবিত্রতা অর্জন, যা নামাজের আগে আবশ্যক। ওজু ছাড়া নামাজ শুদ্ধ হয় না।',
  ),
  keyPoints: [
    LText('Say Bismillah and wash hands', 'বিসমিল্লাহ বলে হাত ধুয়ে নিন'),
    LText('Rinse mouth and nose completely', 'কুলি করুন ও নাকে পানি দিন'),
    LText(
      'Wash the face and arms up to elbows',
      'মুখমণ্ডল ও কনুই পর্যন্ত দুই হাত ধুয়ে নিন',
    ),
    LText('Wipe the head and ears', 'মাথা ও কান মাসেহ করুন'),
    LText('Wash feet up to and including ankles', 'টাখনুসহ দুই পা ধুয়ে নিন'),
  ],
  duas: [
    SalahDua(
      arabic:
          'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration: LText(
        'Ash-hadu alla ilaha illallahu wa ash-hadu anna Muhammadan \'abduhu wa rasoluhu',
        'আশহাদু আল্লা ইলাহা ইল্লাল্লাহু ওয়া আশহাদু আন্না মুহাম্মাদান আবদুহু ওয়া রাসূলুহু',
      ),
      translation: LText(
        'I testify that there is no god but Allah, and I testify that Muhammad is His slave and Messenger.',
        'আমি সাক্ষ্য দিচ্ছি, আল্লাহ ছাড়া কোনো ইলাহ নেই এবং মুহাম্মদ ﷺ তাঁর বান্দা ও রাসূল।',
      ),
    ),
  ],
);

const _qiblaNiyyah = SalahStep(
  id: 'qibla_niyyah',
  arabicName: 'اسْتِقْبَالُ الْقِبْلَة وَ النِّيَّة',
  name: LText('Qibla & Niyyah', 'কিবলা ও নিয়ত'),
  phase: 'before',
  icon: Icons.explore_outlined,
  shortDesc: LText(
    'Face Ka\'bah and intend in the heart',
    'কাবামুখী হয়ে মনে মনে নিয়ত করুন',
  ),
  detailDesc: LText(
    'Face the direction of the Ka\'bah in Mecca. If you knowingly face another direction, your prayer is invalid unless circumstances prevent it. Simultaneously, establish the Niyyah (intention) in your heart. It is not a verbal script. You must know specifically which prayer you are performing.',
    'মক্কার কাবার দিকে মুখ করুন। জেনেবুঝে অন্য দিকে মুখ করলে নামাজ শুদ্ধ হবে না, তবে ওজরের কারণে ব্যতিক্রম আছে। একই সঙ্গে মনে মনে নিয়ত করুন। নিয়ত মুখে বলা কোনো নির্দিষ্ট বাক্য নয় — কোন নামাজ পড়ছেন তা মনে থাকাই যথেষ্ট।',
  ),
  keyPoints: [
    LText('Face the Ka\'bah in Mecca (Qibla)', 'মক্কার কাবামুখী হোন'),
    LText(
      'Intention is in the heart, not verbalized',
      'নিয়ত মনে মনে, মুখে বলা জরুরি নয়',
    ),
    LText(
      'Specify which salah you are performing (e.g., Fard Fajr)',
      'কোন নামাজ পড়ছেন তা নির্দিষ্ট করুন (যেমন ফজরের ফরজ)',
    ),
  ],
);

// ─── During Salah ─────────────────────────────────────────────────────────────
const _takbir = SalahStep(
  id: 'takbir',
  arabicName: 'تَكْبِيرَةُ الْإِحْرَام',
  name: LText('Opening Takbir', 'তাকবিরে তাহরিমা'),
  phase: 'during',
  icon: Icons.record_voice_over_outlined,
  shortDesc: LText(
    'Say Allahu Akbar to enter prayer',
    '‘আল্লাহু আকবার’ বলে নামাজ শুরু করুন',
  ),
  detailDesc: LText(
    'The Takbiratul Ihram inaugurates the prayer. Raise hands to shoulder level with fingertips reaching the level of ears. Place the right hand over the left hand on the chest (either placing right palm over left arm or gripping left wrist). Command your eyes to look only at the spot of prostration.',
    'তাকবিরে তাহরিমা দিয়েই নামাজ শুরু হয়। দুই হাত কাঁধ বরাবর ওঠান, আঙুলের ডগা কান পর্যন্ত পৌঁছাবে। এরপর ডান হাত বাম হাতের ওপরে বুকের ওপর রাখুন (ডান হাতের তালু বাম হাতের ওপর, অথবা বাম কব্জি ধরে)। দৃষ্টি কেবল সিজদার জায়গায় রাখুন।',
  ),
  keyPoints: [
    LText('Say "Allahu Akbar"', '‘আল্লাহু আকবার’ বলুন'),
    LText(
      'Raise palms to shoulder level, fingertips to ears',
      'হাত কাঁধ বরাবর ওঠান, আঙুলের ডগা কান পর্যন্ত',
    ),
    LText(
      'Place right hand over left hand on the chest',
      'ডান হাত বাম হাতের ওপর বুকে রাখুন',
    ),
    LText(
      'Look strictly at the spot of prostration',
      'দৃষ্টি কেবল সিজদার জায়গায় রাখুন',
    ),
  ],
  duas: [
    SalahDua(
      arabic: 'اللَّهُ أَكْبَر',
      transliteration: LText('Allahu Akbar', 'আল্লাহু আকবার'),
      translation: LText('Allah is the Greatest', 'আল্লাহ সবচেয়ে মহান'),
    ),
  ],
);

const _qiyamFirstRak = SalahStep(
  id: 'qiyam_first',
  arabicName: 'الْقِيَام',
  name: LText('Qiyam (First Rak\'ah)', 'কিয়াম (প্রথম রাকাত)'),
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: LText(
    'Stand upright and recite Al-Fatihah + Surah',
    'সোজা দাঁড়িয়ে সূরা ফাতিহা ও একটি সূরা পড়ুন',
  ),
  detailDesc: LText(
    'Stand for obligatory prayers if physically able. Begin with Dua al-Istiftah. Then seek refuge and recite Al-Fatihah — this is a mandatory pillar. You must move your tongue and lips. Mere mental reading invalidates the recitation. Pause at the end of every verse. Then recite an optional Surah without pausing after Al-Fatihah.',
    'সামর্থ্য থাকলে ফরজ নামাজ দাঁড়িয়ে পড়ুন। প্রথমে দোয়ায়ে ইস্তিফতাহ পড়ুন। এরপর আউযুবিল্লাহ পড়ে সূরা ফাতিহা পড়ুন — এটি নামাজের রুকন। জিহ্বা ও ঠোঁট নাড়াতে হবে; কেবল মনে মনে পড়লে কিরাত হয় না। প্রতিটি আয়াতের শেষে থামুন। এরপর অতিরিক্ত একটি সূরা পড়ুন।',
  ),
  keyPoints: [
    LText(
      'Recite opening du\'a (Istiftah) silently',
      'চুপে চুপে দোয়ায়ে ইস্তিফতাহ পড়ুন',
    ),
    LText(
      'Say A\'udhu billahi minash-shaytanir-rajim',
      'আউযুবিল্লাহি মিনাশ শাইতানির রাজিম পড়ুন',
    ),
    LText(
      'Recite Surah Al-Fatihah — moving lips and pausing at every verse',
      'সূরা ফাতিহা পড়ুন — ঠোঁট নাড়িয়ে, প্রতি আয়াতে থেমে',
    ),
    LText(
      'Recite an additional surah directly after',
      'এরপর সঙ্গে সঙ্গে আরেকটি সূরা পড়ুন',
    ),
  ],
  duas: [
    SalahDua(
      arabic:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلَهَ غَيْرُكَ',
      transliteration: LText(
        'Subhanaka Allahumma wa bihamdika, wa tabarakasmuka, wa ta\'ala jadduka, wa la ilaha ghayruka',
        'সুবহানাকা আল্লাহুম্মা ওয়া বিহামদিকা, ওয়া তাবারাকাসমুকা, ওয়া তাআলা জাদ্দুকা, ওয়া লা ইলাহা গাইরুকা',
      ),
      translation: LText(
        'Glory be to You, O Allah, and all praise is Yours. Blessed is Your name, high is Your majesty, and there is no deity besides You.',
        'হে আল্লাহ, আপনি পবিত্র, সমস্ত প্রশংসা আপনার। আপনার নাম বরকতময়, আপনার মর্যাদা সুউচ্চ, আর আপনি ছাড়া কোনো ইলাহ নেই।',
      ),
    ),
    SalahDua(
      arabic:
          'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      transliteration: LText(
        'Al-hamdu lillahi rabb il-\'alamin. Ar-rahman ir-rahim...',
        'আলহামদু লিল্লাহি রাব্বিল আলামিন। আর-রাহমানির রাহিম…',
      ),
      translation: LText(
        'Praise be to Allah, Lord of the worlds. The Most Merciful, the Most Compassionate...',
        'সমস্ত প্রশংসা বিশ্বজগতের প্রতিপালক আল্লাহর। তিনি পরম করুণাময়, অতি দয়ালু…',
      ),
    ),
  ],
);

const _qiyamSubsequentRakWithSurah = SalahStep(
  id: 'qiyam_second',
  arabicName: 'الْقِيَام',
  name: LText('Qiyam (Second Rak\'ah)', 'কিয়াম (দ্বিতীয় রাকাত)'),
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: LText(
    'Stand upright and recite Al-Fatihah + Surah',
    'সোজা দাঁড়িয়ে সূরা ফাতিহা ও একটি সূরা পড়ুন',
  ),
  detailDesc: LText(
    'Stand upright, hands folded over the chest. Recite Bismillah and Surah Al-Fatihah — mandatory in every rak\'ah (moving lips and pausing at verses). Follow it with another surah or a few verses.',
    'সোজা হয়ে দাঁড়ান, হাত বুকের ওপর বাঁধুন। বিসমিল্লাহ ও সূরা ফাতিহা পড়ুন — প্রতি রাকাতেই এটি আবশ্যক (ঠোঁট নাড়িয়ে, আয়াতে আয়াতে থেমে)। এরপর আরেকটি সূরা বা কয়েকটি আয়াত পড়ুন।',
  ),
  keyPoints: [
    LText(
      'Say Bismillahir-rahmanir-rahim',
      'বিসমিল্লাহির রাহমানির রাহিম পড়ুন',
    ),
    LText('Recite Surah Al-Fatihah', 'সূরা ফাতিহা পড়ুন'),
    LText('Recite an additional surah', 'অতিরিক্ত একটি সূরা পড়ুন'),
  ],
);

const _qiyamSubsequentRakFatihahOnly = SalahStep(
  id: 'qiyam_fatihah',
  arabicName: 'الْقِيَام',
  name: LText('Qiyam (Third/Fourth Rak\'ah)', 'কিয়াম (তৃতীয়/চতুর্থ রাকাত)'),
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: LText(
    'Stand upright and recite Al-Fatihah only',
    'সোজা দাঁড়িয়ে কেবল সূরা ফাতিহা পড়ুন',
  ),
  detailDesc: LText(
    'Stand upright, hands folded over the chest on the third/fourth rak\'ah. Recite Bismillah and Surah Al-Fatihah ONLY. Do not add another surah in the 3rd and 4th rak\'ah of Fard prayers.',
    'তৃতীয়/চতুর্থ রাকাতে সোজা দাঁড়িয়ে হাত বুকের ওপর বাঁধুন। শুধু বিসমিল্লাহ ও সূরা ফাতিহা পড়ুন। ফরজ নামাজের তৃতীয় ও চতুর্থ রাকাতে অতিরিক্ত সূরা পড়বেন না।',
  ),
  keyPoints: [
    LText(
      'Say Bismillahir-rahmanir-rahim',
      'বিসমিল্লাহির রাহমানির রাহিম পড়ুন',
    ),
    LText(
      'Recite Surah Al-Fatihah (moving lips)',
      'সূরা ফাতিহা পড়ুন (ঠোঁট নাড়িয়ে)',
    ),
    LText(
      'Do not recite an additional surah (for Fard prayers)',
      'ফরজ নামাজে অতিরিক্ত সূরা পড়বেন না',
    ),
  ],
);

const _qiyamWitrThirdRak = SalahStep(
  id: 'qiyam_witr',
  arabicName: 'الْقِيَام وَالْقُنُوت',
  name: LText(
    'Qiyam & Qunut (Third Rak\'ah of Witr)',
    'কিয়াম ও কুনুত (বিতরের তৃতীয় রাকাত)',
  ),
  phase: 'during',
  icon: Icons.accessibility_new_rounded,
  shortDesc: LText(
    'Recite Al-Fatihah, a Surah, and Du\'a Qunut',
    'সূরা ফাতিহা, একটি সূরা ও দোয়া কুনুত পড়ুন',
  ),
  detailDesc: LText(
    'Stand upright. Recite Surah Al-Fatihah and an additional Surah. Then, raise your hands saying "Allahu Akbar," fold them again (or raise them in supplication), and recite Du\'a Qunut. After completing the Du\'a, say "Allahu Akbar" and go into Ruku\'.',
    'সোজা হয়ে দাঁড়ান। সূরা ফাতিহা ও একটি সূরা পড়ুন। এরপর ‘আল্লাহু আকবার’ বলে হাত ওঠান, আবার হাত বাঁধুন (অথবা দোয়ার ভঙ্গিতে হাত ওঠান) এবং দোয়া কুনুত পড়ুন। দোয়া শেষে ‘আল্লাহু আকবার’ বলে রুকুতে যান।',
  ),
  keyPoints: [
    LText(
      'Recite Surah Al-Fatihah and an additional Surah',
      'সূরা ফাতিহা ও একটি অতিরিক্ত সূরা পড়ুন',
    ),
    LText(
      'Say Allahu Akbar and optionally raise hands',
      '‘আল্লাহু আকবার’ বলুন, চাইলে হাত ওঠান',
    ),
    LText('Recite Du\'a Qunut', 'দোয়া কুনুত পড়ুন'),
    LText(
      'Say Allahu Akbar to go into Ruku\'',
      '‘আল্লাহু আকবার’ বলে রুকুতে যান',
    ),
  ],
  duas: [
    SalahDua(
      arabic:
          'اللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْر',
      transliteration: LText(
        'Allahumma inna nasta\'inuka, wa nastaghfiruka, wa nu\'minu bika, wa natawakkalu \'alayka...',
        'আল্লাহুম্মা ইন্না নাস্তাঈনুকা ওয়া নাস্তাগফিরুকা, ওয়া নুমিনু বিকা ওয়া নাতাওয়াক্কালু আলাইকা…',
      ),
      translation: LText(
        'O Allah! We seek Your help and ask for Your forgiveness, and we believe in You and have trust in You...',
        'হে আল্লাহ! আমরা আপনার সাহায্য চাই, আপনার কাছে ক্ষমা চাই, আপনার ওপর ঈমান আনি ও ভরসা করি…',
      ),
    ),
  ],
);

const _ruku = SalahStep(
  id: 'ruku',
  arabicName: 'الرُّكُوع',
  name: LText('Ruku\' (Bowing)', 'রুকু'),
  phase: 'during',
  icon: Icons.airline_seat_flat_angled_rounded,
  shortDesc: LText('Bow with hands on knees', 'হাঁটুতে হাত রেখে রুকু করুন'),
  detailDesc: LText(
    'Say "Allahu Akbar" *while* moving (Takbir of movement). Keep your back straight (horizontal) and head level. Place palms on knees with fingers spread wide. Look at the spot of prostration or between the feet.',
    'নড়ার সময়েই ‘আল্লাহু আকবার’ বলুন। পিঠ সোজা ও সমান রাখুন, মাথা পিঠ বরাবর থাকবে। আঙুল ছড়িয়ে দুই হাতের তালু হাঁটুর ওপর রাখুন। দৃষ্টি সিজদার জায়গায় বা দুই পায়ের মাঝে রাখুন।',
  ),
  keyPoints: [
    LText(
      'Say Allahu Akbar while moving down',
      'নিচে নামার সময় ‘আল্লাহু আকবার’ বলুন',
    ),
    LText(
      'Back straight, horizontal with the head',
      'পিঠ সোজা, মাথা পিঠ বরাবর',
    ),
    LText(
      'Palms grip knees, fingers spread wide',
      'আঙুল ছড়িয়ে হাতের তালু দিয়ে হাঁটু ধরুন',
    ),
    LText(
      'Say tasbih at least once (preferably 3x)',
      'অন্তত একবার তাসবিহ পড়ুন (তিনবার উত্তম)',
    ),
  ],
  duas: [
    SalahDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيم',
      transliteration: LText(
        'Subhana Rabbiyal \'Azim',
        'সুবহানা রাব্বিয়াল আজিম',
      ),
      translation: LText(
        'Glory be to my Lord, the Most Great',
        'আমার মহান প্রতিপালক পবিত্র',
      ),
    ),
  ],
);

const _iktidal = SalahStep(
  id: 'iktidal',
  arabicName: 'الِاعْتِدَال',
  name: LText('I\'tidal (Rising from Ruku\')', 'ইতিদাল (রুকু থেকে ওঠা)'),
  phase: 'during',
  icon: Icons.height_rounded,
  shortDesc: LText(
    'Rise fully upright, praising Allah',
    'আল্লাহর প্রশংসা করতে করতে সোজা হয়ে দাঁড়ান',
  ),
  detailDesc: LText(
    'Rise from Ruku\' saying "Sami\'allahu liman hamidah" while rising. Once standing straight, say "Rabbana lakal hamd". Returning hands to chest or leaving at sides are both acceptable scholarly views.',
    '‘সামিআল্লাহু লিমান হামিদাহ’ বলতে বলতে রুকু থেকে উঠুন। সোজা হয়ে দাঁড়ানোর পর ‘রাব্বানা লাকাল হামদ’ বলুন। এ সময় হাত বুকে বাঁধা বা পাশে ছেড়ে রাখা — উভয় মতই আলেমদের কাছে গ্রহণযোগ্য।',
  ),
  keyPoints: [
    LText(
      'Say Tasmee\' while rising up',
      'ওঠার সময় ‘সামিআল্লাহু লিমান হামিদাহ’ বলুন',
    ),
    LText('Stand fully straight', 'পুরোপুরি সোজা হয়ে দাঁড়ান'),
    LText(
      'Say Tahmid once fully upright',
      'সোজা হয়ে দাঁড়িয়ে ‘রাব্বানা লাকাল হামদ’ বলুন',
    ),
  ],
  duas: [
    SalahDua(
      arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْد',
      transliteration: LText(
        'Sami\'Allahu liman hamidah. Rabbana wa lakal hamd.',
        'সামিআল্লাহু লিমান হামিদাহ। রাব্বানা ওয়া লাকাল হামদ।',
      ),
      translation: LText(
        'Allah hears the one who praises Him. Our Lord, to You is all praise.',
        'যে আল্লাহর প্রশংসা করে আল্লাহ তার কথা শোনেন। হে আমাদের প্রতিপালক, সমস্ত প্রশংসা আপনারই।',
      ),
    ),
  ],
);

const _sujud1 = SalahStep(
  id: 'sujud1',
  arabicName: 'السُّجُود الْأَوَّل',
  name: LText('First Sujud (Prostration)', 'প্রথম সিজদা'),
  phase: 'during',
  icon: Icons.person_outline_rounded,
  shortDesc: LText('Prostrate on seven limbs', 'সাত অঙ্গের ওপর সিজদা করুন'),
  detailDesc: LText(
    'Say "Allahu Akbar" while descending. Land on hands first to avoid descending like a camel. Seven limbs must remain touching: Forehead+Nose (as one), Two Hands (palms flat towards Qibla), Two Knees, Two Sets of Toes (erect, facing Qibla). Keep forearms off the floor in a "winged" position, stomach away from thighs.',
    'নামার সময় ‘আল্লাহু আকবার’ বলুন। উটের মতো না বসে আগে হাত মাটিতে রাখুন। সাতটি অঙ্গ মাটিতে লেগে থাকতে হবে: কপাল ও নাক (একসঙ্গে), দুই হাতের তালু (কিবলামুখী), দুই হাঁটু এবং দুই পায়ের আঙুল (খাড়া, কিবলামুখী)। বাহু মাটিতে বিছিয়ে দেবেন না, পেট উরু থেকে আলাদা রাখুন।',
  ),
  keyPoints: [
    LText('Land on hands first', 'আগে হাত মাটিতে রাখুন'),
    LText(
      'Seven limbs must touch the ground constantly',
      'সাতটি অঙ্গ সবসময় মাটিতে লেগে থাকবে',
    ),
    LText(
      'Do not rest forearms on the floor (winged arms)',
      'বাহু মাটিতে বিছিয়ে দেবেন না',
    ),
    LText(
      'Say tasbih at least once (preferably 3x)',
      'অন্তত একবার তাসবিহ পড়ুন (তিনবার উত্তম)',
    ),
  ],
  duas: [
    SalahDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: LText(
        'Subhana Rabbiyal A\'la',
        'সুবহানা রাব্বিয়াল আ‘লা',
      ),
      translation: LText(
        'Glory be to my Lord, the Most High',
        'আমার সুউচ্চ প্রতিপালক পবিত্র',
      ),
    ),
  ],
);

const _jalsa = SalahStep(
  id: 'jalsa',
  arabicName: 'الْجَلْسَة',
  name: LText('Jalsah (Sitting Between Sujuds)', 'জালসা (দুই সিজদার মাঝে বসা)'),
  phase: 'during',
  icon: Icons.event_seat_rounded,
  shortDesc: LText(
    'Sit in Iftirash between prostrations',
    'দুই সিজদার মাঝে ইফতিরাশ অবস্থায় বসুন',
  ),
  detailDesc: LText(
    'Rise and sit on your left foot while keeping the right foot erect (Iftirash). You must say "Rabbighfirli" in this brief sitting pause.',
    'উঠে বাম পায়ের ওপর বসুন, ডান পা খাড়া রাখুন (ইফতিরাশ)। এই সংক্ষিপ্ত বসায় ‘রাব্বিগফিরলি’ বলতে হবে।',
  ),
  keyPoints: [
    LText('Sit on the left foot (Iftirash)', 'বাম পায়ের ওপর বসুন (ইফতিরাশ)'),
    LText(
      'Keep right foot erect with toes pointing to Qibla',
      'ডান পা খাড়া রাখুন, আঙুল কিবলামুখী',
    ),
    LText('Recite the forgiveness du\'a', 'ক্ষমা প্রার্থনার দোয়া পড়ুন'),
  ],
  duas: [
    SalahDua(
      arabic: 'رَبِّ اغْفِرْ لِي (٢x)',
      transliteration: LText('Rabbighfirli (x2)', 'রাব্বিগফিরলি (২ বার)'),
      translation: LText(
        'Lord, forgive me (x2)',
        'হে আমার প্রতিপালক, আমাকে ক্ষমা করুন (২ বার)',
      ),
    ),
    SalahDua(
      arabic:
          'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي',
      transliteration: LText(
        'Rabbighfirli war-hamni wajburni warfa\'ni warzuqni wahdinii wa\'afini wa\'fu \'anni',
        'রাব্বিগফিরলি ওয়ারহামনি ওয়াজবুরনি ওয়ারফা‘নি ওয়ারযুকনি ওয়াহদিনি ওয়া আফিনি ওয়া‘ফু আন্নি',
      ),
      translation: LText(
        'O Lord, forgive me, have mercy on me, restore me, raise me, provide for me, guide me, grant me wellbeing, and pardon me.',
        'হে আমার প্রতিপালক, আমাকে ক্ষমা করুন, দয়া করুন, আমার ঘাটতি পূরণ করুন, মর্যাদা বাড়িয়ে দিন, রিজিক দিন, হেদায়েত দিন, সুস্থতা দিন এবং আমাকে মাফ করুন।',
      ),
    ),
  ],
);

const _sujud2 = SalahStep(
  id: 'sujud2',
  arabicName: 'السُّجُود الثَّانِي',
  name: LText('Second Sujud', 'দ্বিতীয় সিজদা'),
  phase: 'during',
  icon: Icons.person_outline_rounded,
  shortDesc: LText(
    'Prostrate a second time on seven limbs',
    'সাত অঙ্গের ওপর দ্বিতীয়বার সিজদা করুন',
  ),
  detailDesc: LText(
    'Perform the second prostration exactly like the first. Ensure all seven limbs remain grounded. Lifting a foot or hand to adjust clothing invalidates the prostration.',
    'প্রথম সিজদার মতোই দ্বিতীয় সিজদা করুন। সাতটি অঙ্গই মাটিতে লেগে থাকতে হবে। কাপড় ঠিক করতে গিয়ে পা বা হাত ওঠালে সিজদা শুদ্ধ হবে না।',
  ),
  keyPoints: [
    LText(
      'Ensure all 7 limbs touch throughout',
      'পুরো সময় সাতটি অঙ্গই মাটিতে থাকবে',
    ),
    LText('Do not rest forearms on the floor', 'বাহু মাটিতে বিছিয়ে দেবেন না'),
    LText('Say tasbih 3x', 'তিনবার তাসবিহ পড়ুন'),
  ],
  duas: [
    SalahDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: LText(
        'Subhana Rabbiyal A\'la',
        'সুবহানা রাব্বিয়াল আ‘লা',
      ),
      translation: LText(
        'Glory be to my Lord, the Most High',
        'আমার সুউচ্চ প্রতিপালক পবিত্র',
      ),
    ),
  ],
);

const _jalsatIstiraha = SalahStep(
  id: 'jalsat_istiraha',
  arabicName: 'جَلْسَةُ الِاسْتِرَاحَة',
  name: LText(
    'Jalsat al-Istiraha (Pause of Rest)',
    'জালসাতুল ইস্তিরাহা (বিশ্রামের বসা)',
  ),
  phase: 'during',
  icon: Icons.hourglass_empty_rounded,
  shortDesc: LText(
    'Brief pause before standing up',
    'দাঁড়ানোর আগে সামান্য বিশ্রাম',
  ),
  detailDesc: LText(
    'In Rak\'ahs where you will stand up immediately after (like the 1st or 3rd Rak\'ah), there is a Sunnah to briefly sit in the Iftirash position after the second Sujud, just for a moment, before rising up to stand for the next Rak\'ah.',
    'যেসব রাকাতের পর সঙ্গে সঙ্গে দাঁড়াতে হয় (যেমন ১ম বা ৩য় রাকাত), সেখানে দ্বিতীয় সিজদার পর মুহূর্তের জন্য ইফতিরাশ অবস্থায় বসা সুন্নত, তারপর পরের রাকাতের জন্য উঠে দাঁড়ান।',
  ),
  keyPoints: [
    LText(
      'Brief pause sitting down after second prostration',
      'দ্বিতীয় সিজদার পর মুহূর্তের জন্য বসুন',
    ),
    LText(
      'Done before rising to the 2nd or 4th Rak\'ah',
      '২য় বা ৪র্থ রাকাতে ওঠার আগে করা হয়',
    ),
  ],
);

const _firstTashahhud = SalahStep(
  id: 'tashahhud_first',
  arabicName: 'التَّشَهُّد الْأَوَّل',
  name: LText('First Tashahhud', 'প্রথম তাশাহহুদ'),
  phase: 'during',
  icon: Icons.event_seat_outlined,
  shortDesc: LText('Sit and recite At-Tahiyyat', 'বসে আত্তাহিয়্যাতু পড়ুন'),
  detailDesc: LText(
    'In a 3 or 4-Rak\'ah prayer, sit after the second rak\'ah in Iftirash (sit on left foot). Point the index finger toward the Qibla and move/wiggle it throughout the testimony. Recite the At-Tahiyyat only. Then say "Allahu Akbar" and stand up.',
    '৩ বা ৪ রাকাতের নামাজে দ্বিতীয় রাকাতের পর ইফতিরাশ অবস্থায় বসুন (বাম পায়ের ওপর)। শাহাদাতের সময় তর্জনী কিবলার দিকে তুলে নাড়াতে থাকুন। শুধু আত্তাহিয়্যাতু পড়ুন। এরপর ‘আল্লাহু আকবার’ বলে দাঁড়িয়ে যান।',
  ),
  keyPoints: [
    LText('Sit in Iftirash', 'ইফতিরাশ অবস্থায় বসুন'),
    LText(
      'Form a circle with thumb/middle finger, or a fist',
      'বৃদ্ধাঙ্গুলি ও মধ্যমা দিয়ে বৃত্ত করুন, অথবা মুঠো করুন',
    ),
    LText(
      'Point and wiggle index finger toward Qibla',
      'তর্জনী কিবলার দিকে তুলে নাড়ান',
    ),
    LText(
      'Recite At-Tahiyyat and stand up',
      'আত্তাহিয়্যাতু পড়ে দাঁড়িয়ে যান',
    ),
  ],
  duas: [
    SalahDua(
      arabic:
          'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration: LText(
        'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu \'alayka ayyuhan-nabiyyu...',
        'আত্তাহিয়্যাতু লিল্লাহি ওয়াস সালাওয়াতু ওয়াত তাইয়্যিবাত। আসসালামু আলাইকা আইয়্যুহান নাবিয়্যু…',
      ),
      translation: LText(
        'All greetings, prayers and good words are for Allah. Peace be upon you, O Prophet...',
        'সমস্ত সম্মান, নামাজ ও পবিত্র কাজ আল্লাহর জন্য। হে নবি, আপনার ওপর শান্তি বর্ষিত হোক…',
      ),
    ),
  ],
);

const _finalTashahhud = SalahStep(
  id: 'tashahhud_final',
  arabicName: 'التَّشَهُّد الْأَخِير',
  name: LText(
    'Final Tashahhud & Protections',
    'শেষ তাশাহহুদ ও আশ্রয় প্রার্থনা',
  ),
  phase: 'during',
  icon: Icons.event_seat_outlined,
  shortDesc: LText(
    'Sit in Tawarruk, recite Tashahhud, Salawat & Du\'a',
    'তাওয়াররুক অবস্থায় বসে তাশাহহুদ, দরুদ ও দোয়া পড়ুন',
  ),
  detailDesc: LText(
    'In the final sitting of a multi-Rakah prayer, use the Tawarruk position (sit on left hip, tuck left foot under right leg, right foot erect). Point and wiggle the index finger. Recite At-Tahiyyat, Salawat, and crucially: seek refuge from the 4 trials before giving Salam.',
    'একাধিক রাকাতের নামাজের শেষ বৈঠকে তাওয়াররুক অবস্থায় বসুন (বাম নিতম্বের ওপর বসে বাম পা ডান পায়ের নিচ দিয়ে বের করে দিন, ডান পা খাড়া)। তর্জনী তুলে নাড়ান। আত্তাহিয়্যাতু ও দরুদ পড়ুন এবং সালামের আগে চারটি ফিতনা থেকে আশ্রয় চান।',
  ),
  keyPoints: [
    LText('Sit in Tawarruk position', 'তাওয়াররুক অবস্থায় বসুন'),
    LText('Point and wiggle the index finger', 'তর্জনী তুলে নাড়ান'),
    LText(
      'Recite At-Tahiyyat and Salawat (Durood)',
      'আত্তাহিয়্যাতু ও দরুদ পড়ুন',
    ),
    LText(
      'Seek refuge from Hellfire, Grave, Life/Death trials, and Dajjal',
      'জাহান্নাম, কবরের আজাব, জীবন-মৃত্যুর ফিতনা ও দাজ্জাল থেকে আশ্রয় চান',
    ),
  ],
  duas: [
    SalahDua(
      arabic:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      transliteration: LText(
        'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad, kama sallayta \'ala Ibrahima...',
        'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদিন ওয়া আলা আলি মুহাম্মাদ, কামা সাল্লাইতা আলা ইবরাহিম…',
      ),
      translation: LText(
        'O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim...',
        'হে আল্লাহ, মুহাম্মদ ﷺ ও তাঁর পরিবারের ওপর রহমত বর্ষণ করুন, যেমন আপনি ইবরাহিম (আ.)-এর ওপর করেছিলেন…',
      ),
    ),
    SalahDua(
      arabic:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ، وَمِنْ عَذَابِ الْقَبْرِ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ',
      transliteration: LText(
        'Allahumma inni a\'udhu bika min \'adhabi Jahannam, wa min \'adhabil-qabr, wa min fitnatil-mahya wal-mamat, wa min sharri fitnatil-masihid-dajjal.',
        'আল্লাহুম্মা ইন্নি আউযু বিকা মিন আজাবি জাহান্নাম, ওয়া মিন আজাবিল কাবর, ওয়া মিন ফিতনাতিল মাহইয়া ওয়াল মামাত, ওয়া মিন শাররি ফিতনাতিল মাসিহিদ দাজ্জাল।',
      ),
      translation: LText(
        'O Allah, I seek refuge with You from the punishment of Hellfire, from the punishment of the grave, from the trials of life and death, and from the evil trial of the False Messiah (Dajjal).',
        'হে আল্লাহ, আমি আপনার কাছে আশ্রয় চাই জাহান্নামের শাস্তি থেকে, কবরের শাস্তি থেকে, জীবন ও মৃত্যুর ফিতনা থেকে এবং দাজ্জালের ফিতনার অনিষ্ট থেকে।',
      ),
    ),
  ],
);

const _salam = SalahStep(
  id: 'salam',
  arabicName: 'التَّسْلِيم',
  name: LText('Salam (Closing)', 'সালাম (নামাজ শেষ)'),
  phase: 'during',
  icon: Icons.waving_hand_outlined,
  shortDesc: LText(
    'Simultaneous head turn and Salam',
    'মাথা ঘোরানোর সঙ্গেই সালাম ফেরান',
  ),
  detailDesc: LText(
    'Conclude by saying the Salam to the right and then the left. Technical Requirement: The movement of the head must be simultaneous with the speech. Do not say the phrase then turn, or turn then say the phrase. Your cheek should be visible. Do not wave or move your hands.',
    'ডানে ও পরে বামে সালাম ফিরিয়ে নামাজ শেষ করুন। খেয়াল রাখুন: মাথা ঘোরানো ও সালাম বলা একসঙ্গে হতে হবে — আগে বলে পরে ঘোরানো বা আগে ঘুরিয়ে পরে বলা নয়। গাল যেন পেছন থেকে দেখা যায়। হাত নাড়াবেন না।',
  ),
  keyPoints: [
    LText(
      'Turn head right simultaneously while saying Salam',
      'সালাম বলতে বলতেই ডানে মাথা ঘোরান',
    ),
    LText(
      'Turn head left simultaneously while saying Salam',
      'সালাম বলতে বলতেই বামে মাথা ঘোরান',
    ),
    LText('Do not move/wave hands', 'হাত নাড়াবেন না'),
  ],
  duas: [
    SalahDua(
      arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّه',
      transliteration: LText(
        'As-Salamu \'Alaykum wa Rahmatullah',
        'আসসালামু আলাইকুম ওয়া রাহমাতুল্লাহ',
      ),
      translation: LText(
        'Peace and the mercy of Allah be upon you',
        'আপনার ওপর শান্তি ও আল্লাহর রহমত বর্ষিত হোক',
      ),
    ),
  ],
);

// ─── Vital Warnings ───────────────────────────────────────────────────────────
const _vitalWarnings = SalahStep(
  id: 'vital_warnings',
  arabicName: 'تَحْذِيرَاتٌ هَامَّة',
  name: LText(
    'Vital Warnings & Common Mistakes',
    'গুরুত্বপূর্ণ সতর্কতা ও সাধারণ ভুল',
  ),
  phase: 'after',
  icon: Icons.warning_amber_rounded,
  shortDesc: LText(
    'Things to avoid during your prayer',
    'নামাজে যেসব ভুল এড়িয়ে চলবেন',
  ),
  detailDesc: LText(
    '• Recitation Validity: You must move your tongue and lips. Silent mental scanning invalidates prayer.\n• Racing the Imam: Never anticipate the Imam. Do not bend your back until his forehead touches the ground.\n• Closing Eyes: Pray with eyes open unless avoiding an extreme distraction.\n• Incomplete Sujud: Lifting feet or failing to touch your nose to the ground invalidates Sujud.\n• Submissiveness (Khushu): Do not lose the spirit of worship over technical obsessions.',
    '• কিরাত: জিহ্বা ও ঠোঁট নাড়াতে হবে। কেবল মনে মনে পড়লে নামাজ শুদ্ধ হয় না।\n• ইমামের আগে যাওয়া: কখনো ইমামের আগে যাবেন না। ইমামের কপাল মাটিতে না পৌঁছানো পর্যন্ত পিঠ ঝোঁকাবেন না।\n• চোখ বন্ধ করা: বড় ধরনের অমনোযোগ এড়ানো ছাড়া চোখ খোলা রেখেই নামাজ পড়ুন।\n• অসম্পূর্ণ সিজদা: পা ওঠালে বা নাক মাটিতে না লাগালে সিজদা শুদ্ধ হয় না।\n• খুশু: নিয়মকানুনের খুঁটিনাটিতে ব্যস্ত হয়ে ইবাদতের মূল ভাব হারাবেন না।',
  ),
  keyPoints: [
    LText(
      'Move tongue and lips during recitation',
      'কিরাতের সময় জিহ্বা ও ঠোঁট নাড়ান',
    ),
    LText(
      'Follow the Imam, never preempt him',
      'ইমামকে অনুসরণ করুন, কখনো আগে যাবেন না',
    ),
    LText(
      'Keep eyes open, looking at prostration point',
      'চোখ খোলা রাখুন, দৃষ্টি সিজদার জায়গায়',
    ),
    LText(
      'Keep 7 limbs on the ground in Sujud',
      'সিজদায় সাতটি অঙ্গ মাটিতে রাখুন',
    ),
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
    title: LText('2 Rak\'ahs Prayer', '২ রাকাত নামাজ'),
    subtitle: LText(
      'Fajr Fard, Sunnah prayers, Nafl',
      'ফজরের ফরজ, সুন্নত ও নফল',
    ),
    arabicTitle: 'صلاة ركعتين',
    icon: Icons.looks_two_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: LText('First Rak\'ah', 'প্রথম রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: LText('Second Rak\'ah', 'দ্বিতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: _baseRakStepsWithSurahOnly,
      ),
      const SalahSection(
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '3_rakah_maghrib',
    title: LText('3 Rak\'ahs (Maghrib)', '৩ রাকাত (মাগরিব)'),
    subtitle: LText('Maghrib Fard prayer', 'মাগরিবের ফরজ নামাজ'),
    arabicTitle: 'صلاة المغرب ٣ ركعات',
    icon: Icons.looks_3_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: LText('First Rak\'ah', 'প্রথম রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: LText('Second Rak\'ah', 'দ্বিতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [..._baseRakStepsWithSurahOnly, _firstTashahhud],
      ),
      const SalahSection(
        title: LText('Third Rak\'ah', 'তৃতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّالِثَة',
        steps: _baseRakStepsFatihahOnly,
      ),
      const SalahSection(
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '4_rakah',
    title: LText('4 Rak\'ahs Prayer', '৪ রাকাত নামাজ'),
    subtitle: LText(
      'Dhuhr, Asr, Isha Fard & Sunnah',
      'জোহর, আসর ও এশার ফরজ ও সুন্নত',
    ),
    arabicTitle: 'صلاة ٤ ركعات',
    icon: Icons.looks_4_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: LText('First Rak\'ah', 'প্রথম রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: LText('Second Rak\'ah', 'দ্বিতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [..._baseRakStepsWithSurahOnly, _firstTashahhud],
      ),
      const SalahSection(
        title: LText('Third Rak\'ah', 'তৃতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّالِثَة',
        steps: _baseRakStepsFatihahOnlyWithIstiraha,
      ),
      const SalahSection(
        title: LText('Fourth Rak\'ah', 'চতুর্থ রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الرَّابِعَة',
        steps: _baseRakStepsFatihahOnly,
      ),
      const SalahSection(
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '3_rakah_witr',
    title: LText('3 Rak\'ahs Witr', '৩ রাকাত বিতর'),
    subtitle: LText('Witr prayer after Isha', 'এশার পর বিতর নামাজ'),
    arabicTitle: 'صلاة الوتر ٣ ركعات',
    icon: Icons.nightlight_round,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: LText('First Rak\'ah', 'প্রথম রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: _baseRakStepsWithSurahAndIstiraha,
      ),
      const SalahSection(
        title: LText('Second Rak\'ah', 'দ্বিতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [..._baseRakStepsWithSurahOnly, _firstTashahhud],
      ),
      const SalahSection(
        title: LText('Third Rak\'ah (Witr)', 'তৃতীয় রাকাত (বিতর)'),
        arabicTitle: 'الرَّكْعَةُ الثَّالِثَة',
        steps: [_qiyamWitrThirdRak, _ruku, _iktidal, _sujud1, _jalsa, _sujud2],
      ),
      const SalahSection(
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),
  SalahTypeData(
    id: '1_rakah_witr',
    title: LText('1 Rak\'ah Witr', '১ রাকাত বিতর'),
    subtitle: LText('Short Witr prayer', 'সংক্ষিপ্ত বিতর নামাজ'),
    arabicTitle: 'صلاة الوتر ركعة',
    icon: Icons.mode_night_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      const SalahSection(
        title: LText('First Rak\'ah (Witr)', 'প্রথম রাকাত (বিতর)'),
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
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
    ],
  ),

  // ─── Funeral Prayer (Janazah) ─────────────────────────────────────────
  SalahTypeData(
    id: 'janazah',
    title: LText('Salat al-Janazah', 'জানাজার নামাজ'),
    subtitle: LText(
      'Funeral prayer — 4 Takbirs, no Ruku\' / Sujud',
      'জানাজার নামাজ — ৪ তাকবির, রুকু-সিজদা নেই',
    ),
    arabicTitle: 'صلاة الجنازة',
    icon: Icons.mosque_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: [_conditions, _qiblaNiyyah],
      ),
      SalahSection(
        title: LText('First Takbir', 'প্রথম তাকবির'),
        arabicTitle: 'التَّكْبِيرَةُ الْأُولَى',
        steps: [
          SalahStep(
            id: 'janazah_takbir1',
            arabicName: 'التَّكْبِيرَةُ الْأُولَى',
            name: LText(
              '1st Takbir — Recite Al-Fatihah',
              '১ম তাকবির — সূরা ফাতিহা',
            ),
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: LText(
              'Say Allahu Akbar, then recite Al-Fatihah',
              '‘আল্লাহু আকবার’ বলে সূরা ফাতিহা পড়ুন',
            ),
            detailDesc: LText(
              'Say "Allahu Akbar" raising both hands. Then recite Surah Al-Fatihah silently.',
              'দুই হাত উঠিয়ে ‘আল্লাহু আকবার’ বলুন। এরপর চুপে চুপে সূরা ফাতিহা পড়ুন।',
            ),
            keyPoints: [
              LText(
                'Say Allahu Akbar and raise hands',
                '‘আল্লাহু আকবার’ বলে হাত ওঠান',
              ),
              LText(
                'Recite Al-Fatihah silently',
                'চুপে চুপে সূরা ফাতিহা পড়ুন',
              ),
            ],
          ),
        ],
      ),
      SalahSection(
        title: LText('Second Takbir', 'দ্বিতীয় তাকবির'),
        arabicTitle: 'التَّكْبِيرَةُ الثَّانِيَة',
        steps: [
          SalahStep(
            id: 'janazah_takbir2',
            arabicName: 'التَّكْبِيرَةُ الثَّانِيَة',
            name: LText(
              '2nd Takbir — Salawat upon the Prophet ﷺ',
              '২য় তাকবির — নবিজি ﷺ-এর ওপর দরুদ',
            ),
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: LText(
              'Say Allahu Akbar, then send Salawat',
              '‘আল্লাহু আকবার’ বলে দরুদ পড়ুন',
            ),
            detailDesc: LText(
              'Say "Allahu Akbar" (without raising hands). Then recite the Ibrahimi Salawat, i.e. "Allahumma salli \'ala Muhammad..." exactly as in the last sitting of regular salah.',
              'হাত না উঠিয়ে ‘আল্লাহু আকবার’ বলুন। এরপর দরুদে ইবরাহিম পড়ুন — সাধারণ নামাজের শেষ বৈঠকে যেভাবে পড়েন ঠিক সেভাবে।',
            ),
            keyPoints: [
              LText('Say Allahu Akbar', '‘আল্লাহু আকবার’ বলুন'),
              LText(
                'Recite the full Ibrahimi Salawat',
                'সম্পূর্ণ দরুদে ইবরাহিম পড়ুন',
              ),
            ],
            duas: [
              SalahDua(
                arabic:
                    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
                transliteration: LText(
                  'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad...',
                  'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদিন ওয়া আলা আলি মুহাম্মাদ…',
                ),
                translation: LText(
                  'O Allah, send prayers upon Muhammad and his family...',
                  'হে আল্লাহ, মুহাম্মদ ﷺ ও তাঁর পরিবারের ওপর রহমত বর্ষণ করুন…',
                ),
              ),
            ],
          ),
        ],
      ),
      SalahSection(
        title: LText('Third Takbir', 'তৃতীয় তাকবির'),
        arabicTitle: 'التَّكْبِيرَةُ الثَّالِثَة',
        steps: [
          SalahStep(
            id: 'janazah_takbir3',
            arabicName: 'التَّكْبِيرَةُ الثَّالِثَة',
            name: LText(
              '3rd Takbir — Du\'a for the Deceased',
              '৩য় তাকবির — মৃতের জন্য দোয়া',
            ),
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: LText(
              'Say Allahu Akbar, then make du\'a',
              '‘আল্লাহু আকবার’ বলে দোয়া করুন',
            ),
            detailDesc: LText(
              'Say "Allahu Akbar". Then make du\'a for the deceased. There are several authentic du\'as for this.',
              '‘আল্লাহু আকবার’ বলুন। এরপর মৃত ব্যক্তির জন্য দোয়া করুন। এ বিষয়ে একাধিক সহিহ দোয়া রয়েছে।',
            ),
            keyPoints: [
              LText('Say Allahu Akbar', '‘আল্লাহু আকবার’ বলুন'),
              LText(
                'Recite a du\'a for the deceased sincerely',
                'আন্তরিকভাবে মৃতের জন্য দোয়া পড়ুন',
              ),
            ],
            duas: [
              SalahDua(
                arabic:
                    'اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ وَعَافِهِ وَاعْفُ عَنْهُ، وَأَكْرِمْ نُزُلَهُ وَوَسِّعْ مُدْخَلَهُ، وَاغْسِلْهُ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ',
                transliteration: LText(
                  'Allahummaghfir lahu warhamhu wa \'afihi wa\'fu \'anhu, wa akrim nuzulahu wa wassi\' mudkhalahu...',
                  'আল্লাহুম্মাগফির লাহু ওয়ারহামহু ওয়া আফিহি ওয়া‘ফু আনহু, ওয়া আকরিম নুযুলাহু ওয়া ওয়াসসি‘ মুদখালাহু…',
                ),
                translation: LText(
                  'O Allah, forgive him, have mercy on him, grant him ease and pardon him. Honour his resting place and expand his entry; wash him with water, snow and hail.',
                  'হে আল্লাহ, তাকে ক্ষমা করুন, তার ওপর দয়া করুন, তাকে নিরাপত্তা দিন ও মাফ করে দিন। তার অবস্থানকে সম্মানিত করুন ও প্রবেশপথ প্রশস্ত করুন; পানি, বরফ ও শিলা দিয়ে তাকে ধুয়ে দিন।',
                ),
              ),
              SalahDua(
                arabic:
                    'اللَّهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَشَاهِدِنَا وَغَائِبِنَا وَصَغِيرِنَا وَكَبِيرِنَا وَذَكَرِنَا وَأُنْثَانَا',
                transliteration: LText(
                  'Allahummaghfir lihayyina wa mayyitina, wa shahidina wa gha\'ibina, wa sagheerina wa kabeerina, wa dhakarina wa unthana.',
                  'আল্লাহুম্মাগফির লিহাইয়িনা ওয়া মাইয়িতিনা, ওয়া শাহিদিনা ওয়া গায়িবিনা, ওয়া সাগিরিনা ওয়া কাবিরিনা, ওয়া যাকারিনা ওয়া উনসানা।',
                ),
                translation: LText(
                  'O Allah, forgive our living and our dead, those present among us and those absent, our young and our old, our males and our females.',
                  'হে আল্লাহ, আমাদের জীবিত ও মৃত, উপস্থিত ও অনুপস্থিত, ছোট ও বড়, পুরুষ ও নারী — সবাইকে ক্ষমা করুন।',
                ),
              ),
            ],
          ),
        ],
      ),
      SalahSection(
        title: LText('Fourth Takbir', 'চতুর্থ তাকবির'),
        arabicTitle: 'التَّكْبِيرَةُ الرَّابِعَة',
        steps: [
          SalahStep(
            id: 'janazah_takbir4',
            arabicName: 'التَّكْبِيرَةُ الرَّابِعَة وَالتَّسْلِيم',
            name: LText('4th Takbir & Salam', '৪র্থ তাকবির ও সালাম'),
            phase: 'during',
            icon: Icons.waving_hand_outlined,
            shortDesc: LText(
              'Say Allahu Akbar, then give Salam',
              '‘আল্লাহু আকবার’ বলে সালাম ফেরান',
            ),
            detailDesc: LText(
              'Say "Allahu Akbar" once more. You may make a brief du\'a. Then conclude with one Salam to the right.',
              'আরেকবার ‘আল্লাহু আকবার’ বলুন। চাইলে সংক্ষিপ্ত দোয়া করুন। এরপর ডানে একবার সালাম ফিরিয়ে শেষ করুন।',
            ),
            keyPoints: [
              LText('Say Allahu Akbar', '‘আল্লাহু আকবার’ বলুন'),
              LText(
                'Optionally make a short du\'a',
                'চাইলে সংক্ষিপ্ত দোয়া করুন',
              ),
              LText('Give one Salam to the right', 'ডানে একবার সালাম ফেরান'),
            ],
            duas: [
              SalahDua(
                arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّه',
                transliteration: LText(
                  'As-Salamu \'Alaykum wa Rahmatullah',
                  'আসসালামু আলাইকুম ওয়া রাহমাতুল্লাহ',
                ),
                translation: LText(
                  'Peace and the mercy of Allah be upon you.',
                  'আপনার ওপর শান্তি ও আল্লাহর রহমত বর্ষিত হোক।',
                ),
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
    title: LText('Eid Prayer', 'ঈদের নামাজ'),
    subtitle: LText(
      '2 Rak\'ahs with extra Takbirs',
      'অতিরিক্ত তাকবিরসহ ২ রাকাত',
    ),
    arabicTitle: 'صلاة العيد',
    icon: Icons.celebration_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      SalahSection(
        title: LText('First Rak\'ah', 'প্রথম রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: [
          SalahStep(
            id: 'eid_takbirs_1',
            arabicName: 'تَكْبِيرَاتُ الْإِحْرَامِ وَالزَّوَائِد',
            name: LText(
              'Opening Takbir + 7 Extra Takbirs',
              'তাকবিরে তাহরিমা + অতিরিক্ত ৭ তাকবির',
            ),
            phase: 'during',
            icon: Icons.record_voice_over_outlined,
            shortDesc: LText(
              'Say opening Takbir, followed by 7 extra Takbirs',
              'তাকবিরে তাহরিমার পর অতিরিক্ত ৭ তাকবির বলুন',
            ),
            detailDesc: LText(
              'Say the Takbiratul Ihram, then say "Allahu Akbar" 7 additional times, raising your hands with each one. After the extra Takbirs, seek refuge and recite Al-Fatihah and a Surah (Surah Al-A\'la is Sunnah).',
              'তাকবিরে তাহরিমা বলুন, এরপর প্রতিবার হাত উঠিয়ে আরও ৭ বার ‘আল্লাহু আকবার’ বলুন। অতিরিক্ত তাকবিরের পর আউযুবিল্লাহ পড়ে সূরা ফাতিহা ও একটি সূরা পড়ুন (সূরা আ‘লা পড়া সুন্নত)।',
            ),
            keyPoints: [
              LText('Opening Takbir (Takbiratul Ihram)', 'তাকবিরে তাহরিমা'),
              LText(
                '7 additional Takbirs with hands raised',
                'হাত উঠিয়ে অতিরিক্ত ৭ তাকবির',
              ),
              LText('Recite Al-Fatihah', 'সূরা ফাতিহা পড়ুন'),
              LText(
                'Recite Surah Al-A\'la or another Surah',
                'সূরা আ‘লা বা অন্য কোনো সূরা পড়ুন',
              ),
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
        title: LText('Second Rak\'ah', 'দ্বিতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [
          SalahStep(
            id: 'eid_takbirs_2',
            arabicName: 'خَمْسُ تَكْبِيرَاتٍ زَائِدَة',
            name: LText(
              'Qiyam + 5 Extra Takbirs',
              'কিয়াম + অতিরিক্ত ৫ তাকবির',
            ),
            phase: 'during',
            icon: Icons.accessibility_new_rounded,
            shortDesc: LText(
              'Say 5 extra Takbirs then recite Al-Fatihah + Surah',
              'অতিরিক্ত ৫ তাকবির বলে সূরা ফাতিহা ও একটি সূরা পড়ুন',
            ),
            detailDesc: LText(
              'Upon standing, say "Allahu Akbar" 5 additional times raising your hands with each. Then recite Al-Fatihah and a Surah (Surah Al-Ghashiyah is Sunnah).',
              'দাঁড়ানোর পর প্রতিবার হাত উঠিয়ে আরও ৫ বার ‘আল্লাহু আকবার’ বলুন। এরপর সূরা ফাতিহা ও একটি সূরা পড়ুন (সূরা গাশিয়াহ পড়া সুন্নত)।',
            ),
            keyPoints: [
              LText(
                '5 additional Takbirs with hands raised',
                'হাত উঠিয়ে অতিরিক্ত ৫ তাকবির',
              ),
              LText('Recite Al-Fatihah', 'সূরা ফাতিহা পড়ুন'),
              LText(
                'Recite Surah Al-Ghashiyah or another Surah',
                'সূরা গাশিয়াহ বা অন্য কোনো সূরা পড়ুন',
              ),
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
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: [_finalTashahhud, _salam],
      ),
    ],
  ),

  // ─── Tarawih / Tahajjud ───────────────────────────────────────────────
  SalahTypeData(
    id: 'tarawih',
    title: LText('Tarawih / Tahajjud', 'তারাবিহ / তাহাজ্জুদ'),
    subtitle: LText(
      '2 Rak\'ahs at a time, with long Qiyam',
      'দুই রাকাত করে, দীর্ঘ কিয়ামসহ',
    ),
    arabicTitle: 'صلاة التراويح / التهجد',
    icon: Icons.dark_mode_rounded,
    sections: [
      const SalahSection(
        title: LText('Before Salah', 'নামাজের আগে'),
        arabicTitle: 'قَبْلَ الصَّلَاة',
        steps: _baseStartSteps,
      ),
      SalahSection(
        title: LText('First Rak\'ah', 'প্রথম রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الْأُولَى',
        steps: [
          _takbir,
          SalahStep(
            id: 'tarawih_qiyam1',
            arabicName: 'الْقِيَام',
            name: LText('Qiyam — Long Recitation', 'কিয়াম — দীর্ঘ কিরাত'),
            phase: 'during',
            icon: Icons.accessibility_new_rounded,
            shortDesc: LText(
              'Stand and recite Al-Fatihah + a long portion of Quran',
              'দাঁড়িয়ে সূরা ফাতিহা ও কুরআনের দীর্ঘ অংশ পড়ুন',
            ),
            detailDesc: LText(
              'After the opening du\'a, recite Al-Fatihah followed by a long portion of the Quran. Tarawih and Tahajjud are characterised by lengthing the recitation in Qiyam as much as is comfortable.',
              'দোয়ায়ে ইস্তিফতাহর পর সূরা ফাতিহা এবং তারপর কুরআনের দীর্ঘ অংশ পড়ুন। তারাবিহ ও তাহাজ্জুদের বৈশিষ্ট্যই হলো কিয়ামে যতটা সহজ হয় ততটা দীর্ঘ কিরাত পড়া।',
            ),
            keyPoints: [
              LText(
                'Recite opening Istiftah du\'a',
                'দোয়ায়ে ইস্তিফতাহ পড়ুন',
              ),
              LText(
                'Recite Al-Fatihah + a long Surah or several shorter Surahs',
                'সূরা ফাতিহার পর একটি দীর্ঘ সূরা বা কয়েকটি ছোট সূরা পড়ুন',
              ),
              LText(
                'Lengthen the standing as much as comfortable',
                'যতটা সহজ হয় ততটা দীর্ঘ সময় দাঁড়ান',
              ),
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
        title: LText('Second Rak\'ah', 'দ্বিতীয় রাকাত'),
        arabicTitle: 'الرَّكْعَةُ الثَّانِيَة',
        steps: [
          SalahStep(
            id: 'tarawih_qiyam2',
            arabicName: 'الْقِيَام',
            name: LText('Qiyam — Long Recitation', 'কিয়াম — দীর্ঘ কিরাত'),
            phase: 'during',
            icon: Icons.accessibility_new_rounded,
            shortDesc: LText(
              'Stand and recite Al-Fatihah + a long portion of Quran',
              'দাঁড়িয়ে সূরা ফাতিহা ও কুরআনের দীর্ঘ অংশ পড়ুন',
            ),
            detailDesc: LText(
              'Recite Al-Fatihah followed by a continuation of the Quran. Then proceed to Ruku\' and Sujud as normal.',
              'সূরা ফাতিহার পর কুরআনের পরবর্তী অংশ পড়ুন। এরপর স্বাভাবিক নিয়মে রুকু ও সিজদা করুন।',
            ),
            keyPoints: [
              LText(
                'Recite Al-Fatihah + another long portion',
                'সূরা ফাতিহার পর আরেকটি দীর্ঘ অংশ পড়ুন',
              ),
              LText(
                'Proceed to Ruku\' and Sujud normally',
                'স্বাভাবিক নিয়মে রুকু ও সিজদা করুন',
              ),
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
        title: LText('After Salah', 'নামাজের পরে'),
        arabicTitle: 'بَعْدَ الصَّلَاة',
        steps: _baseEndSteps,
      ),
      SalahSection(
        title: LText('Note', 'লক্ষণীয়'),
        arabicTitle: 'مُلَاحَظَة',
        steps: [
          SalahStep(
            id: 'tarawih_note',
            arabicName: 'مُلَاحَظَة',
            name: LText('Repeat in Sets of 2', 'দুই রাকাত করে পুনরাবৃত্তি'),
            phase: 'after',
            icon: Icons.info_outline_rounded,
            shortDesc: LText(
              'Pray in sets of 2 Rak\'ahs, then finish with Witr',
              'দুই রাকাত করে পড়ুন, শেষে বিতর পড়ুন',
            ),
            detailDesc: LText(
              'Tarawih is prayed in sets of 2 Rak\'ahs. After every 2 Rak\'ahs, give Salam and start a new set. You may pray 8, 12, or 20 Rak\'ahs. Always conclude the night prayer with Witr (1 or 3 Rak\'ahs).',
              'তারাবিহ দুই রাকাত করে পড়া হয়। প্রতি দুই রাকাত পর সালাম ফিরিয়ে নতুন করে শুরু করুন। ৮, ১২ বা ২০ রাকাত পড়তে পারেন। রাতের নামাজ সবসময় বিতর (১ বা ৩ রাকাত) দিয়ে শেষ করুন।',
            ),
            keyPoints: [
              LText('Pray in sets of 2', 'দুই রাকাত করে পড়ুন'),
              LText(
                'Give Salam between each set',
                'প্রতি সেটের পর সালাম ফেরান',
              ),
              LText('Conclude with Witr prayer', 'বিতর নামাজ দিয়ে শেষ করুন'),
            ],
          ),
        ],
      ),
    ],
  ),
];
