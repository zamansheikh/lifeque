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
    version: '1.0.0',
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
