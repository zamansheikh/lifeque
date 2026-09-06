// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class LBn extends L {
  LBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'LifeQue';

  @override
  String get navTasks => 'কাজ';

  @override
  String get navTodoList => 'করণীয় তালিকা';

  @override
  String get navReminders => 'রিমাইন্ডার';

  @override
  String get navBirthdays => 'জন্মদিন';

  @override
  String get navExpenses => 'খরচের হিসাব';

  @override
  String get navMedicines => 'ওষুধ';

  @override
  String get navPrayerTimes => 'নামাজের সময়';

  @override
  String get navStudyTimer => 'পড়ার টাইমার';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get drawerTagline => 'আপনার ব্যক্তিগত জীবন-সহকারী';

  @override
  String get commonSave => 'সংরক্ষণ';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonMore => 'আরও';

  @override
  String get commonDone => 'সম্পন্ন';

  @override
  String get commonToday => 'আজ';

  @override
  String get commonTomorrow => 'আগামীকাল';

  @override
  String get commonYesterday => 'গতকাল';

  @override
  String get commonNow => 'এখন';

  @override
  String get commonOff => 'বন্ধ';

  @override
  String get commonNone => 'নেই';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsSectionGeneral => 'সাধারণ';

  @override
  String get settingsSectionApp => 'অ্যাপ';

  @override
  String get settingsSectionLegal => 'আইনগত';

  @override
  String get settingsNavigationOrder => 'মেনুর ক্রম';

  @override
  String settingsNavigationOrderSubtitle(String page) {
    return 'হোম: $page';
  }

  @override
  String get settingsLanguage => 'ভাষা';

  @override
  String get settingsCheckUpdates => 'আপডেট দেখুন';

  @override
  String get settingsCheckUpdatesSubtitle => 'নতুন সংস্করণ এসেছে কি না দেখুন';

  @override
  String get settingsAbout => 'লাইফকিউ সম্পর্কে';

  @override
  String get settingsAboutSubtitle => 'সংস্করণ, নির্মাতা ও লিংক';

  @override
  String get settingsPrivacy => 'গোপনীয়তা নীতি';

  @override
  String get settingsPrivacySubtitle => 'আপনার তথ্য কীভাবে ব্যবহার করি';

  @override
  String get settingsTerms => 'ব্যবহারের শর্তাবলি';

  @override
  String get settingsTermsSubtitle => 'অ্যাপ ব্যবহারের শর্ত';

  @override
  String get settingsMadeBy => '❤️ দিয়ে তৈরি — জামান শেখ';

  @override
  String get navOrderTitle => 'মেনুর ক্রম';

  @override
  String get navOrderSubtitle => 'সাজাতে টেনে আনুন। প্রথমটিই হোম পেজ।';

  @override
  String navOrderHomePage(String page) {
    return 'হোম পেজ:  $page';
  }

  @override
  String get navOrderHomeBadge => 'হোম পেজ';

  @override
  String get navOrderSave => 'ক্রম সংরক্ষণ';

  @override
  String get navOrderSaved => 'মেনুর ক্রম সংরক্ষিত হয়েছে';

  @override
  String languageComingSoon(String language) {
    return '$language · শীঘ্রই আসছে';
  }

  @override
  String languageSet(String language) {
    return 'ভাষা $language করা হয়েছে';
  }

  @override
  String languageSavedPending(String language) {
    return '$language সংরক্ষিত হয়েছে। অনুবাদ যুক্ত না হওয়া পর্যন্ত অ্যাপ ইংরেজিতেই থাকবে।';
  }
}
