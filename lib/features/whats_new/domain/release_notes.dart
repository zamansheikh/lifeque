import 'package:flutter/material.dart';

/// One line of a release note, written in both languages beside each other.
///
/// Kept here rather than in the ARB bundles: release notes are append-only and
/// version-scoped, so putting each bullet through the translation files would
/// grow them for good with strings nobody reads after an update or two.
class ReleaseLine {
  const ReleaseLine(this.icon, this.en, this.bn);

  final IconData icon;
  final String en;
  final String bn;

  String of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'bn' ? bn : en;
}

class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.headlineEn,
    required this.headlineBn,
    required this.lines,
  });

  /// Matched against the running build's version name.
  final String version;
  final String headlineEn;
  final String headlineBn;
  final List<ReleaseLine> lines;

  String headline(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'bn'
      ? headlineBn
      : headlineEn;
}

/// Newest first. Add a new entry when the version in `pubspec.yaml` changes;
/// anything without an entry simply shows nothing.
const List<ReleaseNote> kReleaseNotes = [
  ReleaseNote(
    version: '2.3.0',
    headlineEn: 'Exact prayer times, and a lot more',
    headlineBn: 'নিখুঁত নামাজের সময়, আরও অনেক কিছু',
    lines: [
      ReleaseLine(
        Icons.mosque_rounded,
        'Prayer times worked out afresh: Dhuhr waits until zawal has passed, '
            'every time is rounded the safe way, and the Hijri and Bangla '
            'dates follow Bangladesh.',
        'নামাজের সময় নতুন করে হিসাব: যোহর শুরু হয় জাওয়াল পেরোলে, প্রতিটি '
            'সময় নিরাপদ দিকে গোল করা, আর হিজরি ও বাংলা তারিখ বাংলাদেশ অনুযায়ী।',
      ),
      ReleaseLine(
        Icons.nightlight_round,
        'Ramadan: sehri and iftar countdown, a fasting and taraweeh log, '
            'duas — and Islamic Foundation\'s district timetable if you '
            'want it.',
        'রমজান: সাহরি-ইফতারের কাউন্টডাউন, রোজা ও তারাবিহর হিসাব, দোয়া — আর চাইলে '
            'ইসলামিক ফাউন্ডেশনের জেলাভিত্তিক সময়সূচি।',
      ),
      ReleaseLine(
        Icons.restore_rounded,
        'Qaza: keep count of missed prayers and fasts, and make them up one '
            'tap at a time.',
        'কাযা: বাকি নামাজ ও রোজার হিসাব রাখুন, এক ট্যাপে আদায় করুন।',
      ),
      ReleaseLine(
        Icons.local_fire_department_rounded,
        'Habits with streaks, a 16-week history and daily reminders.',
        'অভ্যাস: টানা কতদিন, ১৬ সপ্তাহের ইতিহাস আর প্রতিদিনের রিমাইন্ডার।',
      ),
      ReleaseLine(
        Icons.handshake_rounded,
        'Lent & borrowed, and subscriptions that remind you before they '
            'renew.',
        'ধার-দেনার হিসাব, আর নবায়নের আগে মনে করিয়ে দেওয়া সাবস্ক্রিপশন।',
      ),
      ReleaseLine(
        Icons.task_alt_rounded,
        'Tasks, reminders and to-dos are one list now, and can repeat '
            'daily, weekly, monthly or yearly.',
        'কাজ, রিমাইন্ডার ও টু-ডু এখন এক তালিকায়, আর প্রতিদিন, সপ্তাহ, মাস বা '
            'বছরে পুনরাবৃত্তি করা যায়।',
      ),
      ReleaseLine(
        Icons.search_rounded,
        'One search for everything, a full backup you can restore, and '
            'study-timer sounds.',
        'সবকিছুতে এক খোঁজ, পুরো ব্যাকআপ ও রিস্টোর, আর পড়ার টাইমারে শব্দ।',
      ),
    ],
  ),
  ReleaseNote(
    version: '2.2.4',
    headlineEn: 'Wish cards, and widgets that behave',
    headlineBn: 'শুভেচ্ছা কার্ড, আর ঠিকঠাক উইজেট',
    lines: [
      ReleaseLine(
        Icons.cake_rounded,
        'Birthday wish cards: five designs, ready-made wishes in Bangla and '
            'English, your name on it, and a note of who you have wished.',
        'জন্মদিনের শুভেচ্ছা কার্ড: পাঁচটি ডিজাইন, বাংলা-ইংরেজি তৈরি শুভেচ্ছা, '
            'আপনার নাম, আর কাকে শুভেচ্ছা জানানো হয়েছে তার হিসাব।',
      ),
      ReleaseLine(
        Icons.ios_share_rounded,
        'Prayer-time share cards redesigned — a night-to-dawn skyline for '
            'the day, and a printable sheet for the month.',
        'নামাজের সময়ের শেয়ার কার্ড নতুন সাজে — দিনের জন্য রাত থেকে ভোরের '
            'আকাশ, আর মাসের জন্য ছাপার উপযোগী সময়সূচি।',
      ),
      ReleaseLine(
        Icons.widgets_rounded,
        'Widgets keep your language after a refresh, fit every cell size, '
            'and say "Next" when no waqt is running.',
        'উইজেট রিফ্রেশের পরও আপনার ভাষায় থাকে, যেকোনো আকারে ঠিকঠাক বসে, '
            'আর কোনো ওয়াক্ত না চললে "পরবর্তী" দেখায়।',
      ),
      ReleaseLine(
        Icons.notifications_active_rounded,
        'The alarm bell asks when to ring, remembers your choice, and a '
            'long-press applies it instantly.',
        'অ্যালার্মের ঘণ্টা কখন বাজবে জিজ্ঞেস করে, পছন্দ মনে রাখে, আর চেপে '
            'ধরলে সঙ্গে সঙ্গে সেট হয়ে যায়।',
      ),
      ReleaseLine(
        Icons.wb_twilight_rounded,
        'Ishraq, Awwabin and Tahajjud get their own countdown while their '
            'window is open.',
        'ইশরাক, আওয়াবিন ও তাহাজ্জুদের সময় চলাকালে তাদের নিজস্ব কাউন্টডাউন।',
      ),
      ReleaseLine(
        Icons.tips_and_updates_rounded,
        'Gentle suggestions when you open the app — a birthday to wish, a '
            'timetable worth sharing.',
        'অ্যাপ খুললে ছোট্ট পরামর্শ — কারও জন্মদিনে শুভেচ্ছা, বা শেয়ার করার '
            'মতো সময়সূচি।',
      ),
      ReleaseLine(
        Icons.account_balance_wallet_rounded,
        'The monthly budget shows what is left and a safe daily figure; '
            'the budget editor is simpler and fully in Bangla.',
        'মাসিক বাজেটে এখন কত বাকি আর দিনে কত খরচ করা যাবে তা দেখায়; বাজেট '
            'সম্পাদনা সহজ হয়েছে, পুরোটা বাংলায়।',
      ),
      ReleaseLine(
        Icons.schedule_rounded,
        'Time pickers are 12-hour with AM/PM, and dates typed on the '
            'keyboard are accepted in either digit set.',
        'সময় বাছাই এখন ১২ ঘণ্টার, AM/PM সহ; কিবোর্ডে লেখা তারিখ যেকোনো '
            'সংখ্যায় গ্রহণ করা হয়।',
      ),
    ],
  ),
  ReleaseNote(
    version: '2.0.0',
    headlineEn: 'The app now speaks Bangla',
    headlineBn: 'অ্যাপ এখন বাংলায়',
    lines: [
      ReleaseLine(
        Icons.translate_rounded,
        'Every screen reads in Bangla — text, numerals and a 12-hour clock.',
        'প্রতিটি পাতা এখন বাংলায় — লেখা, সংখ্যা ও ১২ ঘণ্টার ঘড়ি।',
      ),
      ReleaseLine(
        Icons.menu_book_rounded,
        'Learn: the salah guide, surahs and du\'as are fully translated, with '
            '12 surahs added from Al-Asr to An-Nas.',
        'শিখুন: নামাজের নির্দেশিকা, সূরা ও দোয়া সম্পূর্ণ অনূদিত; সূরা আসর '
            'থেকে নাস পর্যন্ত ১২টি সূরা যোগ হয়েছে।',
      ),
      ReleaseLine(
        Icons.front_hand_rounded,
        'A new section on Raf\' al-Yadain, with each school\'s position and '
            'the evidence for it.',
        'রফউল ইয়াদাইন নিয়ে নতুন অধ্যায় — প্রতিটি মাজহাবের মত ও দলিলসহ।',
      ),
      ReleaseLine(
        Icons.medication_rounded,
        'Medicines can be kept per person, added in fewer taps, and a missed '
            'dose is asked about instead of quietly written off.',
        'ওষুধ এখন আলাদা করে কার জন্য তা রাখা যায়, কম ট্যাপে যোগ হয়, আর মিস '
            'হওয়া ডোজ চুপচাপ বাদ না দিয়ে জিজ্ঞেস করা হয়।',
      ),
      ReleaseLine(
        Icons.receipt_long_rounded,
        'Expenses guess their category from the item name, in Bangla or '
            'English.',
        'খরচের নাম দেখে ক্যাটাগরি ধরে নেয় — বাংলা বা ইংরেজি, দুই ভাষাতেই।',
      ),
      ReleaseLine(
        Icons.widgets_rounded,
        'Home-screen widgets are in Bangla, in the app\'s own typeface.',
        'হোম স্ক্রিনের উইজেট বাংলায়, অ্যাপের নিজস্ব ফন্টে।',
      ),
    ],
  ),
];

/// The note for [version], or null when there is nothing to announce.
ReleaseNote? releaseNoteFor(String version) {
  for (final note in kReleaseNotes) {
    if (note.version == version) return note;
  }
  return null;
}
