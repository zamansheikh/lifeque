import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'islamic_resources_page.dart';
import 'salah_guide/salah_step_model.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';

// ─── Data model ───────────────────────────────────────────────────────────────
class _Dua {
  final String arabicName;
  final LText name;
  final String arabicText;
  final LText transliteration;
  final LText translation;
  final LText? when;

  const _Dua({
    required this.arabicName,
    required this.name,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    this.when,
  });
}

class _DuaCategory {
  final String arabicLabel;
  final LText label;
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
    label: LText('During Salah', 'নামাজের ভেতরে'),
    color: IslamicColors.deepGreen,
    bgColor: IslamicColors.lightGreen,
    icon: Icons.self_improvement_rounded,
    duas: const [
      _Dua(
        arabicName: 'دُعَاء الِاسْتِفْتَاح',
        name: LText('Opening Du\'a (Istiftah)', 'দোয়ায়ে ইস্তিফতাহ'),
        when: LText(
          'Silent — after Opening Takbir',
          'চুপে চুপে — তাকবিরে তাহরিমার পর',
        ),
        arabicText:
            'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلٰهَ غَيْرُكَ',
        transliteration: LText(
          'Subhanakallahumma wa bihamdika wa tabarakasmuka wa ta\'ala jadduka wa la ilaha ghayruk.',
          'সুবহানাকাল্লাহুম্মা ওয়া বিহামদিকা ওয়া তাবারাকাসমুকা ওয়া তাআলা জাদ্দুকা ওয়া লা ইলাহা গাইরুক।',
        ),
        translation: LText(
          'How perfect You are O Allah, and I praise You. Blessed is Your Name and Exalted is Your Majesty. There is no god worthy of worship except You.',
          'হে আল্লাহ, আপনি কত পবিত্র! সমস্ত প্রশংসা আপনার। আপনার নাম বরকতময় ও আপনার মর্যাদা সুউচ্চ। আপনি ছাড়া ইবাদতের যোগ্য কোনো ইলাহ নেই।',
        ),
      ),
      _Dua(
        arabicName: 'ذِكْر الرُّكُوع',
        name: LText('Dhikr of Ruku\'', 'রুকুর তাসবিহ'),
        when: LText(
          'Repeated 3 times (minimum) in Ruku\'',
          'রুকুতে অন্তত ৩ বার',
        ),
        arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيم',
        transliteration: LText(
          'Subhana Rabbiyal \'Azim',
          'সুবহানা রাব্বিয়াল আজিম',
        ),
        translation: LText(
          'Glory be to my Lord, the Most Great',
          'আমার মহান প্রতিপালক পবিত্র',
        ),
      ),
      _Dua(
        arabicName: 'عِنْد الرَّفْع مِن الرُّكُوع',
        name: LText('Rising from Ruku\'', 'রুকু থেকে ওঠার দোয়া'),
        when: LText('While rising from bowing', 'রুকু থেকে ওঠার সময়'),
        arabicText:
            'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْدُ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيه',
        transliteration: LText(
          'Sami\'Allahu liman hamidah. Rabbana wa lakal hamd, hamdan kathiran tayyiban mubarakan fih.',
          'সামিআল্লাহু লিমান হামিদাহ। রাব্বানা ওয়া লাকাল হামদ, হামদান কাসিরান তাইয়্যিবান মুবারাকান ফিহ।',
        ),
        translation: LText(
          'Allah hears the one who praises Him. Our Lord, to You is all praise — abundant, pure, and blessed praise.',
          'যে আল্লাহর প্রশংসা করে আল্লাহ তার কথা শোনেন। হে আমাদের প্রতিপালক, সমস্ত প্রশংসা আপনারই — অজস্র, পবিত্র ও বরকতময় প্রশংসা।',
        ),
      ),
      _Dua(
        arabicName: 'ذِكْر السُّجُود',
        name: LText('Dhikr of Sujud', 'সিজদার তাসবিহ'),
        when: LText(
          'Repeated 3 times (minimum) in prostration',
          'সিজদায় অন্তত ৩ বার',
        ),
        arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
        transliteration: LText(
          'Subhana Rabbiyal A\'la',
          'সুবহানা রাব্বিয়াল আ‘লা',
        ),
        translation: LText(
          'Glory be to my Lord, the Most High',
          'আমার সুউচ্চ প্রতিপালক পবিত্র',
        ),
      ),
      _Dua(
        arabicName: 'دُعَاء بَيْن السَّجْدَتَيْن',
        name: LText('Du\'a between Sujuds', 'দুই সিজদার মাঝের দোয়া'),
        when: LText(
          'In the Jalsah (sitting between two prostrations)',
          'জালসায় (দুই সিজদার মাঝে বসে)',
        ),
        arabicText:
            'رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي',
        transliteration: LText(
          'Rabbighfirli, warhamni, wajburni, warfa\'ni, warzuqni, wahdinii, wa\'afini.',
          'রাব্বিগফিরলি, ওয়ারহামনি, ওয়াজবুরনি, ওয়ারফা‘নি, ওয়ারযুকনি, ওয়াহদিনি, ওয়া আফিনি।',
        ),
        translation: LText(
          'O Lord, forgive me, have mercy on me, restore me, raise me up, provide for me, guide me, and grant me wellbeing.',
          'হে আমার প্রতিপালক, আমাকে ক্ষমা করুন, দয়া করুন, আমার ঘাটতি পূরণ করুন, মর্যাদা বাড়িয়ে দিন, রিজিক দিন, হেদায়েত দিন এবং সুস্থতা দিন।',
        ),
      ),
    ],
  ),
  _DuaCategory(
    arabicLabel: 'بَعْدَ الصَّلَاة',
    label: LText('After Salah', 'নামাজের পরে'),
    color: const Color(0xFF6A1B9A),
    bgColor: const Color(0xFFF3E5F5),
    icon: Icons.volunteer_activism_rounded,
    duas: const [
      _Dua(
        arabicName: 'الِاسْتِغْفَار',
        name: LText('Istighfar (3 times)', 'ইস্তিগফার (৩ বার)'),
        when: LText(
          'Immediately after Salam — 3 times',
          'সালামের পরপরই — ৩ বার',
        ),
        arabicText: 'أَسْتَغْفِرُ اللَّه',
        transliteration: LText('Astaghfirullah', 'আস্তাগফিরুল্লাহ'),
        translation: LText(
          'I seek forgiveness from Allah',
          'আমি আল্লাহর কাছে ক্ষমা চাই',
        ),
      ),
      _Dua(
        arabicName: 'دُعَاء السَّلَام',
        name: LText('Peace Du\'a', 'শান্তির দোয়া'),
        when: LText('After the three istigfars', 'তিনবার ইস্তিগফারের পর'),
        arabicText:
            'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَام',
        transliteration: LText(
          'Allahumma Antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.',
          'আল্লাহুম্মা আনতাস সালাম ওয়া মিনকাস সালাম, তাবারাকতা ইয়া যাল জালালি ওয়াল ইকরাম।',
        ),
        translation: LText(
          'O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Majesty and Honor.',
          'হে আল্লাহ, আপনিই শান্তি এবং আপনার কাছ থেকেই শান্তি আসে। আপনি বরকতময়, হে মহিমা ও সম্মানের অধিকারী।',
        ),
      ),
      _Dua(
        arabicName: 'التَّسْبِيح وَالتَّحْمِيد',
        name: LText('Tasbih, Tahmid & Takbir', 'তাসবিহ, তাহমিদ ও তাকবির'),
        when: LText('33 + 33 + 34 = 100', '৩৩ + ৩৩ + ৩৪ = ১০০'),
        arabicText:
            'سُبْحَانَ اللَّهِ ×٣٣ ۝ الْحَمْدُ لِلَّهِ ×٣٣ ۝ اللَّهُ أَكْبَر ×٣٤',
        transliteration: LText(
          'Subhanallah (×33), Alhamdulillah (×33), Allahu Akbar (×34)',
          'সুবহানাল্লাহ (×৩৩), আলহামদুলিল্লাহ (×৩৩), আল্লাহু আকবার (×৩৪)',
        ),
        translation: LText(
          'Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (34 times).',
          'আল্লাহ পবিত্র (৩৩ বার), সমস্ত প্রশংসা আল্লাহর (৩৩ বার), আল্লাহ সবচেয়ে মহান (৩৪ বার)।',
        ),
      ),
      _Dua(
        arabicName: 'آيَة الْكُرْسِي',
        name: LText('Ayat al-Kursi', 'আয়াতুল কুরসি'),
        when: LText(
          'Once after every obligatory prayer — great protection',
          'প্রতি ফরজ নামাজের পর একবার — বড় হেফাজত',
        ),
        arabicText:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        transliteration: LText(
          'Allahu la ilaha illa huwal-hayyul-qayyum. La ta\'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa\'u \'indahu illa bi-idhnih. Ya\'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay\'im min \'ilmihi illa bima sha\'. Wasi\'a kursiyyuhus-samawati wal-ard. Wa la ya\'uduhu hifzuhuma. Wa huwal-\'aliyyul-\'azim.',
          'আল্লাহু লা ইলাহা ইল্লা হুয়াল হাইয়্যুল কাইয়্যুম। লা তা’খুযুহু সিনাতুঁও ওয়ালা নাউম। লাহু মা ফিস সামাওয়াতি ওয়া মা ফিল আরদ। মান যাল্লাযি ইয়াশফাউ ইনদাহু ইল্লা বিইযনিহ। ইয়া‘লামু মা বাইনা আইদিহিম ওয়া মা খালফাহুম। ওয়ালা ইউহিতুনা বিশাইইম মিন ইলমিহি ইল্লা বিমা শা-আ। ওয়াসিআ কুরসিয়্যুহুস সামাওয়াতি ওয়াল আরদ। ওয়ালা ইয়াউদুহু হিফযুহুমা। ওয়া হুয়াল আলিয়্যুল আযিম।',
        ),
        translation: LText(
          'Allah — there is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what lies before them and what is behind them, and they encompass nothing of His knowledge except what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great. (Surah al-Baqarah 2:255)',
          'আল্লাহ — তিনি ছাড়া কোনো ইলাহ নেই; তিনি চিরঞ্জীব, সবকিছুর ধারক। তন্দ্রা বা ঘুম তাঁকে স্পর্শ করে না। আসমান ও জমিনে যা কিছু আছে সবই তাঁর। কে আছে যে তাঁর অনুমতি ছাড়া তাঁর কাছে সুপারিশ করবে? তাদের সামনে ও পেছনে যা আছে সবই তিনি জানেন; আর তারা তাঁর জ্ঞানের কিছুই আয়ত্ত করতে পারে না, তিনি যতটুকু চান তা ছাড়া। তাঁর কুরসি আসমান ও জমিনজুড়ে বিস্তৃত; আর এ দুটির রক্ষণাবেক্ষণ তাঁকে ক্লান্ত করে না। তিনিই সর্বোচ্চ, মহান। (সূরা বাকারা ২:২৫৫)',
        ),
      ),
    ],
  ),
  _DuaCategory(
    arabicLabel: 'أَذْكَار الصَّبَاح وَالْمَسَاء',
    label: LText('Morning & Evening Adhkar', 'সকাল-সন্ধ্যার জিকির'),
    color: const Color(0xFFE65100),
    bgColor: const Color(0xFFFFF3E0),
    icon: Icons.wb_sunny_rounded,
    duas: const [
      _Dua(
        arabicName: 'سَيِّد الِاسْتِغْفَار',
        name: LText('Master of Seeking Forgiveness', 'সাইয়িদুল ইস্তিগফার'),
        when: LText(
          'Morning and Evening — once each',
          'সকাল ও সন্ধ্যায় — একবার করে',
        ),
        arabicText:
            'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
        transliteration: LText(
          'Allahumma anta Rabbi, la ilaha illa anta, khalaqtani wa ana \'abduka, wa ana \'ala \'ahdika wa wa\'dika mastata\'tu. A\'udhu bika min sharri ma sana\'tu. Abu\'u laka bi-ni\'matika \'alayya, wa abu\'u bi-dhanbi, faghfir li fa-innahu la yaghfirudh-dhunuba illa anta.',
          'আল্লাহুম্মা আনতা রাব্বি, লা ইলাহা ইল্লা আনতা, খালাকতানি ওয়া আনা আবদুকা, ওয়া আনা আলা আহদিকা ওয়া ওয়া‘দিকা মাসতাতা‘তু। আউযু বিকা মিন শাররি মা সানা‘তু। আবুউ লাকা বিনি‘মাতিকা আলাইয়্যা, ওয়া আবুউ বিযামবি, ফাগফির লি ফাইন্নাহু লা ইয়াগফিরুয যুনুবা ইল্লা আনতা।',
        ),
        translation: LText(
          'O Allah, You are my Lord. There is no god but You. You created me and I am Your servant, and I hold to Your covenant and Your promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge before You Your favour upon me, and I acknowledge my sin — so forgive me, for none forgives sins but You.',
          'হে আল্লাহ, আপনিই আমার প্রতিপালক। আপনি ছাড়া কোনো ইলাহ নেই। আপনি আমাকে সৃষ্টি করেছেন, আমি আপনার বান্দা। সাধ্যমতো আমি আপনার সঙ্গে করা অঙ্গীকার ও প্রতিশ্রুতিতে অটল আছি। আমি যা করেছি তার অনিষ্ট থেকে আপনার আশ্রয় চাই। আমার প্রতি আপনার নিয়ামত স্বীকার করছি এবং নিজের গুনাহও স্বীকার করছি — সুতরাং আমাকে ক্ষমা করুন, কারণ আপনি ছাড়া গুনাহ ক্ষমা করার কেউ নেই।',
        ),
      ),
      _Dua(
        arabicName: 'دُعَاء الصَّبَاح',
        name: LText('Morning Protection', 'সকালের হেফাজত'),
        when: LText('Morning — 3 times', 'সকালে — ৩ বার'),
        arabicText:
            'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيم',
        transliteration: LText(
          'Bismillahil-ladhi la yadurru ma\'asmihi shay\'un fil-ardi wala fis-sama\'i wa huwas-sami\'ul-\'alim.',
          'বিসমিল্লাহিল্লাযি লা ইয়াদুররু মা‘আসমিহি শাইউন ফিল আরদি ওয়ালা ফিস সামাই ওয়া হুয়াস সামিউল আলিম।',
        ),
        translation: LText(
          'In the name of Allah, with whose name nothing can cause harm on earth or in the heavens, and He is the All-Hearing, All-Knowing.',
          'আল্লাহর নামে, যাঁর নামের বরকতে জমিনে বা আসমানে কোনো কিছুই ক্ষতি করতে পারে না; তিনি সর্বশ্রোতা, সর্বজ্ঞ।',
        ),
      ),
      _Dua(
        arabicName: 'أذكار المساء',
        name: LText('Evening Remembrance', 'সন্ধ্যার জিকির'),
        when: LText('Evening — 3 times', 'সন্ধ্যায় — ৩ বার'),
        arabicText:
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَق',
        transliteration: LText(
          'A\'udhu bikalimAtillahit-tammati min sharri ma khalaq.',
          'আউযু বিকালিমাতিল্লাহিত তাম্মাতি মিন শাররি মা খালাক।',
        ),
        translation: LText(
          'I seek refuge in the perfect words of Allah from the evil of what He has created.',
          'আমি আল্লাহর পরিপূর্ণ কালামের আশ্রয় চাই তিনি যা সৃষ্টি করেছেন তার অনিষ্ট থেকে।',
        ),
      ),
    ],
  ),
  _DuaCategory(
    arabicLabel: 'أَدْعِيَة مُتَنَوِّعَة',
    label: LText('General Du\'as', 'সাধারণ দোয়া'),
    color: const Color(0xFF1565C0),
    bgColor: const Color(0xFFE3F2FD),
    icon: Icons.favorite_border_rounded,
    duas: const [
      _Dua(
        arabicName: 'دُعَاء الدُّنْيَا وَالآخِرَة',
        name: LText('Best of Both Worlds', 'দুনিয়া ও আখিরাতের কল্যাণ'),
        arabicText:
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّار',
        transliteration: LText(
          'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
          'রাব্বানা আতিনা ফিদ্দুনইয়া হাসানাতাও ওয়া ফিল আখিরাতি হাসানাতাও ওয়া কিনা আজাবান নার।',
        ),
        translation: LText(
          'Our Lord, give us good in this world and good in the Hereafter, and protect us from the torment of the Fire.',
          'হে আমাদের প্রতিপালক, আমাদের দুনিয়াতে কল্যাণ দিন, আখিরাতেও কল্যাণ দিন এবং জাহান্নামের আজাব থেকে রক্ষা করুন।',
        ),
      ),
      _Dua(
        arabicName: 'دُعَاء الثَّبَات',
        name: LText('Du\'a for Steadfastness', 'অবিচলতার দোয়া'),
        arabicText: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
        transliteration: LText(
          'Ya muqallibal-qulub, thabbit qalbi \'ala dinik.',
          'ইয়া মুকাল্লিবাল কুলুব, সাব্বিত কালবি আলা দিনিক।',
        ),
        translation: LText(
          'O Turner of hearts, make my heart firm upon Your religion.',
          'হে অন্তর পরিবর্তনকারী, আমার অন্তরকে আপনার দ্বীনের ওপর অবিচল রাখুন।',
        ),
      ),
      _Dua(
        arabicName: 'دُعَاء الهِدَايَة',
        name: LText('Du\'a for Guidance', 'হেদায়েতের দোয়া'),
        arabicText: 'اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي',
        transliteration: LText(
          'Allahummahdini wa saddidni.',
          'আল্লাহুম্মাহদিনি ওয়া সাদ্দিদনি।',
        ),
        translation: LText(
          'O Allah, guide me and keep me on the right path.',
          'হে আল্লাহ, আমাকে হেদায়েত দিন এবং সঠিক পথে অবিচল রাখুন।',
        ),
      ),
      _Dua(
        arabicName: 'دُعَاء الخَيْر',
        name: LText('Du\'a for All Good', 'সব কল্যাণের দোয়া'),
        arabicText:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
        transliteration: LText(
          'Allahumma inni as\'alukal-huda wat-tuqa wal-\'afafa wal-ghina.',
          'আল্লাহুম্মা ইন্নি আসআলুকাল হুদা ওয়াত তুকা ওয়াল আফাফা ওয়াল গিনা।',
        ),
        translation: LText(
          'O Allah, I ask You for guidance, piety, chastity, and self-sufficiency.',
          'হে আল্লাহ, আমি আপনার কাছে হেদায়েত, তাকওয়া, পবিত্রতা ও অভাবমুক্তি চাই।',
        ),
      ),
    ],
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class DuasAzkarPage extends StatefulWidget {
  const DuasAzkarPage({super.key});

  @override
  State<DuasAzkarPage> createState() => _DuasAzkarPageState();
}

class _DuasAzkarPageState extends State<DuasAzkarPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Categories reduced to the du'as matching the query, with empty ones
  /// dropped. Matching runs over both languages plus the Arabic, so someone
  /// reading in Bangla can still search by the name they know in English.
  List<_DuaCategory> _visibleCategories(BuildContext context) {
    if (_query.isEmpty) return _categories;
    final q = _query.toLowerCase();

    bool hit(_Dua d) => [
      d.arabicName,
      d.arabicText,
      d.name.en,
      d.name.bn,
      d.transliteration.en,
      d.transliteration.bn,
      d.translation.en,
      d.translation.bn,
      d.when?.en ?? '',
      d.when?.bn ?? '',
    ].any((t) => t.toLowerCase().contains(q));

    final out = <_DuaCategory>[];
    for (final cat in _categories) {
      // A hit on the category name keeps the whole category — searching
      // "after salah" should show that section, not nothing.
      final categoryHit =
          cat.label.en.toLowerCase().contains(q) ||
          cat.label.bn.contains(_query) ||
          cat.arabicLabel.contains(_query);
      final duas = categoryHit ? cat.duas : cat.duas.where(hit).toList();
      if (duas.isEmpty) continue;
      out.add(
        _DuaCategory(
          arabicLabel: cat.arabicLabel,
          label: cat.label,
          color: cat.color,
          bgColor: cat.bgColor,
          icon: cat.icon,
          duas: duas,
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final visible = _visibleCategories(context);
    final matches = visible.fold<int>(0, (n, c) => n + c.duas.length);

    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(child: _searchField(context, searching, matches)),
          if (searching && visible.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _empty(context))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DuaCategorySection(
                    category: visible[index],
                    // While searching, open every card — the point of a search
                    // is to see the du'a, not another row to tap.
                    startExpanded: searching,
                  ),
                  childCount: visible.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context, bool searching, int matches) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 1,
            shadowColor: Colors.black12,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14,
                color: IslamicColors.darkText,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: l.duaSearchHint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: IslamicColors.mutedText,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: IslamicColors.mutedText,
                ),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: l.duaSearchClear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: IslamicColors.mutedText,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (searching && matches > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8),
              child: Text(
                l.duaSearchResults(matches),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: IslamicColors.mutedText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: IslamicColors.mutedText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l.duaSearchEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: IslamicColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.duaSearchEmptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: IslamicColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      title: Text(
        L.of(context).resDuas,
        style: const TextStyle(
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
  const _DuaCategorySection({
    required this.category,
    this.startExpanded = false,
  });
  final _DuaCategory category;
  final bool startExpanded;

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
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        color: category.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      category.label.of(context),
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
                  L.of(context).duaCountLabel(category.duas.length),
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
        ...category.duas.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DuaCard(
              // Keyed on the dua so a card rebuilt under a new filter starts
              // from the right expansion state rather than inheriting one.
              key: ValueKey(e.value.arabicName + e.value.name.en),
              dua: e.value,
              position: e.key + 1,
              accentColor: category.color,
              startExpanded: startExpanded,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dua card ─────────────────────────────────────────────────────────────────
class _DuaCard extends StatefulWidget {
  const _DuaCard({
    super.key,
    required this.dua,
    required this.position,
    required this.accentColor,
    this.startExpanded = false,
  });
  final _Dua dua;

  /// Where this du'a falls in its category, from 1.
  final int position;
  final Color accentColor;
  final bool startExpanded;

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  late bool _expanded = widget.startExpanded;

  @override
  void didUpdateWidget(_DuaCard old) {
    super.didUpdateWidget(old);
    if (widget.startExpanded != old.startExpanded) {
      _expanded = widget.startExpanded;
    }
  }

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
                        N.of(widget.position),
                        style: TextStyle(
                          fontSize: 15,
                          color: widget.accentColor,
                          fontWeight: FontWeight.w800,
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
                          widget.dua.arabicName,
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            color: IslamicColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.dua.name.of(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.darkText,
                          ),
                        ),
                        if (widget.dua.when != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.dua.when!.of(context),
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
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        height: 2.2,
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
                          L.of(context).duaBadgeTransliteration,
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
                          widget.dua.transliteration.of(context),
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
                        child: Text(
                          L.of(context).duaBadgeMeaning,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: IslamicColors.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.dua.translation.of(context),
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
                            SnackBar(
                              content: Text(L.of(context).duaCopiedArabic),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: Text(
                          L.of(context).duaCopyArabic,
                          style: const TextStyle(fontSize: 12),
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
