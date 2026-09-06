import '../entities/expense_category.dart';

/// Guesses the category of an expense item from what it is called.
///
/// The dictionary is bilingual and unsorted by language on purpose: people
/// write their shopping list in whichever script is quicker at the till, and
/// often mix the two in one line ("২ kg চাল"). Matching is language-agnostic,
/// so a keyword only has to appear once in whichever form it is written.
///
/// The vocabulary leans Bangladeshi — CNG, লেগুনা, কাচ্চি, তিতাস, পল্লী বিদ্যুৎ —
/// because a generic English list guesses badly on a Dhaka grocery run.
class ExpenseCategorySuggester {
  ExpenseCategorySuggester._();

  /// Up to [limit] categories, best match first. Empty when nothing matches,
  /// which leaves the item on whatever the user already chose.
  static List<ExpenseCategory> suggest(String name, {int limit = 3}) {
    final text = name.toLowerCase().trim();
    if (text.isEmpty) return const [];

    // Split on anything that is not part of a word, so punctuation, units and
    // quantities ("2kg,চাল") do not swallow the word next to them. Marks have
    // to count as word characters: Bangla vowel signs are combining marks, not
    // letters, so without \p{M} "চাল" tokenises as ["চ", "ল"].
    final tokens = text
        .split(RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .toList();

    final scores = <ExpenseCategory, int>{};
    for (final entry in _keywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (!_matches(keyword, text, tokens)) continue;
        // A two-word phrase is a far stronger signal than a lone word, and
        // has to outweigh one: "বাসা ভাড়া" is rent, even though ভাড়া on its
        // own is a rickshaw fare and বাসা looks like বাস.
        score += keyword.contains(' ') ? _phraseWeight : 1;
      }
      if (score > 0) scores[entry.key] = score;
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final byScore = b.value.compareTo(a.value);
        // Ties resolve by enum order so the same input always suggests the
        // same thing, rather than whatever the map happened to iterate first.
        return byScore != 0 ? byScore : a.key.index.compareTo(b.key.index);
      });
    return ranked.take(limit).map((e) => e.key).toList();
  }

  /// Item names that begin with what has been typed so far, so the name can
  /// be completed with a tap instead of spelled out.
  ///
  /// Same-script matches come first: someone typing Bangla wants চাল before
  /// chal, even though both are in the dictionary.
  static List<({String name, ExpenseCategory category})> suggestNames(
    String query, {
    int limit = 6,
  }) {
    final typed = query.toLowerCase().trim();
    if (typed.length < 2) return const [];
    final typedIsBangla = _bengali.hasMatch(typed);

    final hits = <({String name, ExpenseCategory category, int rank})>[];
    final seen = <String>{};
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (keyword == typed || !keyword.startsWith(typed)) continue;
        if (!seen.add(keyword)) continue;
        final sameScript = _bengali.hasMatch(keyword) == typedIsBangla;
        hits.add((
          name: keyword,
          category: entry.key,
          // Shorter completions first — they are the likelier word — and the
          // reader's own script ahead of the other one.
          rank: (sameScript ? 0 : 1000) + keyword.length,
        ));
      }
    }

    hits.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      return byRank != 0 ? byRank : a.name.compareTo(b.name);
    });
    return hits
        .take(limit)
        .map((h) => (name: _titleCase(h.name), category: h.category))
        .toList();
  }

  /// Latin keywords are stored lower-case; put them back in sentence case so a
  /// tapped suggestion reads like something the user would have typed.
  static String _titleCase(String word) {
    if (word.isEmpty || _bengali.hasMatch(word)) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

  /// A keyword hits when it is a whole word in the name.
  ///
  /// Plain `contains` was the old rule and it misfired badly on short words:
  /// "steak" matched *tea*, "toilet paper" matched *oil*, "billboard" matched
  /// *bill*. The endings that do matter are handled per script — English takes
  /// plurals only, while Bangla allows any suffix, because its case endings
  /// attach straight to the noun (ডিম → ডিমের, বাজার → বাজারে).
  static bool _matches(String keyword, String text, List<String> tokens) {
    if (keyword.contains(' ')) return text.contains(keyword);
    final bangla = _bengali.hasMatch(keyword);
    for (final token in tokens) {
      if (token == keyword) return true;
      if (bangla) {
        if (keyword.length >= 3 && token.startsWith(keyword)) return true;
      } else if (token == '${keyword}s' || token == '${keyword}es') {
        return true;
      }
    }
    return false;
  }

  static const int _phraseWeight = 3;

  static final RegExp _bengali = RegExp(r'[\u0980-\u09FF]');

  static const Map<ExpenseCategory, List<String>> _keywords = {
    ExpenseCategory.groceries: [
      // staples
      'rice', 'chal', 'চাল', 'flour', 'atta', 'আটা', 'maida', 'ময়দা',
      'suji', 'সুজি', 'oil', 'soybean', 'সয়াবিন', 'mustard', 'সরিষা',
      'ghee', 'ঘি', 'sugar', 'চিনি', 'salt', 'লবণ', 'নুন',
      'lentil', 'dal', 'ডাল', 'মসুর', 'ছোলা', 'মুগ', 'বুট',
      'semai', 'সেমাই', 'noodles', 'নুডলস', 'pasta', 'পাস্তা',
      'vermicelli', 'চিড়া', 'মুড়ি', 'খই',
      // protein
      'egg', 'ডিম', 'milk', 'দুধ', 'fish', 'মাছ', 'ইলিশ', 'রুই', 'কাতলা',
      'তেলাপিয়া', 'পাঙ্গাস', 'চিংড়ি', 'শুঁটকি',
      'meat', 'মাংস', 'beef', 'গরু', 'mutton', 'খাসি', 'খাসির',
      'chicken', 'মুরগি', 'মুরগী', 'ব্রয়লার', 'কক',
      'curd', 'yogurt', 'দই', 'butter', 'মাখন', 'cheese', 'পনির',
      // produce
      'vegetable', 'সবজি', 'শাক', 'তরকারি', 'potato', 'আলু',
      'onion', 'পেঁয়াজ', 'পিয়াজ', 'garlic', 'রসুন', 'ginger', 'আদা',
      'tomato', 'টমেটো', 'brinjal', 'eggplant', 'বেগুন',
      'cucumber', 'শসা', 'carrot', 'গাজর', 'cabbage', 'বাঁধাকপি',
      'cauliflower', 'ফুলকপি', 'pumpkin', 'কুমড়া', 'লাউ', 'ঢেঁড়স',
      'করলা', 'মুলা', 'পটল', 'কাঁচামরিচ', 'ধনেপাতা', 'লেবু',
      'banana', 'কলা', 'mango', 'আম', 'apple', 'আপেল',
      'orange', 'কমলা', 'papaya', 'পেঁপে', 'আঙুর', 'পেয়ারা', 'তরমুজ',
      'fruit', 'ফল',
      // spice
      'spice', 'মসলা', 'মশলা', 'turmeric', 'হলুদ', 'chili', 'মরিচ',
      'cumin', 'জিরা', 'coriander', 'ধনে', 'এলাচ', 'দারুচিনি', 'তেজপাতা',
      // pantry & household
      'biscuit', 'বিস্কুট', 'bread', 'পাউরুটি', 'jam', 'জ্যাম',
      'honey', 'মধু', 'ketchup', 'সস', 'vinegar', 'সিরকা',
      'grocery', 'groceries', 'মুদি', 'bazar', 'bazaar', 'বাজার',
      'soap', 'সাবান', 'shampoo', 'শ্যাম্পু', 'detergent', 'ডিটারজেন্ট',
      'সার্ফ', 'toothpaste', 'টুথপেস্ট', 'brush', 'ব্রাশ',
      'tissue', 'টিস্যু', 'napkin', 'ন্যাপকিন', 'ঝাড়ু', 'মশার',
    ],
    ExpenseCategory.food: [
      'restaurant',
      'রেস্টুরেন্ট',
      'রেস্তোরাঁ',
      'hotel',
      'হোটেল',
      'cafe',
      'ক্যাফে',
      'canteen',
      'ক্যান্টিন',
      'food',
      'খাবার',
      'খাওয়া',
      'dinner',
      'রাতের খাবার',
      'lunch',
      'দুপুরের খাবার',
      'breakfast',
      'নাশতা',
      'নাস্তা',
      'iftar',
      'ইফতার',
      'sehri',
      'সেহরি',
      'সাহরি',
      'coffee',
      'কফি',
      'tea',
      'চা',
      'snack',
      'স্ন্যাকস',
      'burger',
      'বার্গার',
      'pizza',
      'পিজ্জা',
      'পিৎজা',
      'biryani',
      'biriyani',
      'বিরিয়ানি',
      'kacchi',
      'কাচ্চি',
      'tehari',
      'তেহারি',
      'khichuri',
      'খিচুড়ি',
      'polao',
      'পোলাও',
      'kabab',
      'kebab',
      'কাবাব',
      'shawarma',
      'শর্মা',
      'roll',
      'রোল',
      'singara',
      'সিঙ্গারা',
      'samosa',
      'সমুচা',
      'puri',
      'পুরি',
      'paratha',
      'পরোটা',
      'ruti',
      'রুটি',
      'chotpoti',
      'চটপটি',
      'fuchka',
      'phuchka',
      'ফুচকা',
      'cake',
      'কেক',
      'pastry',
      'পেস্ট্রি',
      'juice',
      'জুস',
      'শরবত',
      'borhani',
      'বোরহানি',
      'lassi',
      'লাচ্ছি',
      'ice cream',
      'আইসক্রিম',
      'dessert',
      'sweets',
      'মিষ্টি',
      'chomchom',
      'চমচম',
      'rosogolla',
      'রসগোল্লা',
      'jilapi',
      'জিলাপি',
      'foodpanda',
      'ফুডপান্ডা',
      'takeaway',
      'পার্সেল',
    ],
    ExpenseCategory.transport: [
      'bus',
      'বাস',
      'rickshaw',
      'রিকশা',
      'রিক্সা',
      'cng',
      'সিএনজি',
      'taxi',
      'ট্যাক্সি',
      'uber',
      'উবার',
      'pathao',
      'পাঠাও',
      'leguna',
      'লেগুনা',
      'tempo',
      'টেম্পো',
      'auto',
      'অটো',
      'fare',
      'ভাড়া',
      'train',
      'ট্রেন',
      'launch',
      'লঞ্চ',
      'ferry',
      'ফেরি',
      'metro',
      'মেট্রো',
      'metrorail',
      'মেট্রোরেল',
      'flight',
      'ফ্লাইট',
      'বিমান',
      'plane',
      'প্লেন',
      'fuel',
      'petrol',
      'পেট্রোল',
      'octane',
      'অকটেন',
      'diesel',
      'ডিজেল',
      'gas fill',
      'bike',
      'বাইক',
      'motorcycle',
      'মোটরসাইকেল',
      'car',
      'গাড়ি',
      'parking',
      'পার্কিং',
      'toll',
      'টোল',
      'travel',
      'যাতায়াত',
      'ভ্রমণ',
    ],
    ExpenseCategory.utilities: [
      'electricity',
      'বিদ্যুৎ',
      'বিদ্যুত',
      'কারেন্ট',
      'current bill',
      'desco',
      'ডেসকো',
      'palli bidyut',
      'পল্লী বিদ্যুৎ',
      'water',
      'পানি',
      'wasa',
      'ওয়াসা',
      'gas',
      'গ্যাস',
      'titas',
      'তিতাস',
      'সিলিন্ডার',
      'cylinder',
      'internet',
      'ইন্টারনেট',
      'wifi',
      'ওয়াইফাই',
      'broadband',
      'ব্রডব্যান্ড',
      'phone',
      'ফোন',
      'mobile',
      'মোবাইল',
      'recharge',
      'রিচার্জ',
      'flexiload',
      'ফ্লেক্সিলোড',
      'sim',
      'সিম',
      'data',
      'ডাটা',
      'মিনিট',
      'dish',
      'ডিশ',
      'cable',
      'ক্যাবল',
      'bill',
      'বিল',
      'service charge',
      'সার্ভিস চার্জ',
    ],
    ExpenseCategory.entertainment: [
      'movie',
      'মুভি',
      'cinema',
      'সিনেমা',
      'হল',
      'theatre',
      'নাটক',
      'game',
      'গেম',
      'গেমিং',
      'toy',
      'খেলনা',
      'novel',
      'উপন্যাস',
      'comic',
      'কমিক',
      'ticket',
      'টিকিট',
      'concert',
      'কনসার্ট',
      'show',
      'শো',
      'netflix',
      'নেটফ্লিক্স',
      'youtube',
      'ইউটিউব',
      'spotify',
      'subscription',
      'সাবস্ক্রিপশন',
      'club',
      'ক্লাব',
      'park',
      'পার্ক',
      'zoo',
      'চিড়িয়াখানা',
      'picnic',
      'পিকনিক',
      'tour',
      'বেড়ানো',
      'outing',
      'ঘোরাঘুরি',
      'মেলা',
    ],
    ExpenseCategory.healthcare: [
      'medicine',
      'ওষুধ',
      'ঔষধ',
      'medical',
      'মেডিকেল',
      'doctor',
      'ডাক্তার',
      'চিকিৎসা',
      'clinic',
      'ক্লিনিক',
      'hospital',
      'হাসপাতাল',
      'health',
      'স্বাস্থ্য',
      'pharmacy',
      'ফার্মেসি',
      'ফার্মেসী',
      'capsule',
      'ক্যাপসুল',
      'tablet',
      'ট্যাবলেট',
      'syrup',
      'সিরাপ',
      'injection',
      'ইনজেকশন',
      'saline',
      'স্যালাইন',
      'test',
      'টেস্ট',
      'checkup',
      'চেকআপ',
      'রক্ত পরীক্ষা',
      'xray',
      'এক্সরে',
      'ultrasound',
      'আল্ট্রাসনো',
      'dentist',
      'দাঁতের',
      'vaccine',
      'ভ্যাকসিন',
      'টিকা',
      'bandage',
      'ব্যান্ডেজ',
      'mask',
      'মাস্ক',
      'ambulance',
      'অ্যাম্বুলেন্স',
    ],
    ExpenseCategory.education: [
      'tuition',
      'টিউশন',
      'টিউশনি',
      'coaching',
      'কোচিং',
      'school',
      'স্কুল',
      'college',
      'কলেজ',
      'university',
      'বিশ্ববিদ্যালয়',
      'ভার্সিটি',
      'madrasa',
      'মাদ্রাসা',
      'course',
      'কোর্স',
      'class',
      'ক্লাস',
      'exam',
      'পরীক্ষা',
      'admission',
      'ভর্তি',
      'fees',
      'ফি',
      'form',
      'ফরম',
      'book',
      'বই',
      'textbook',
      'পাঠ্যবই',
      'guide',
      'গাইড',
      'pen',
      'কলম',
      'pencil',
      'পেন্সিল',
      'khata',
      'খাতা',
      'notebook',
      'নোটবুক',
      'eraser',
      'রাবার',
      'scale',
      'স্কেল',
      'stationery',
      'stationary',
      'স্টেশনারি',
      'photocopy',
      'ফটোকপি',
      'print',
      'প্রিন্ট',
      'library',
      'লাইব্রেরি',
      'uniform',
      'ইউনিফর্ম',
    ],
    ExpenseCategory.shopping: [
      'shirt',
      'শার্ট',
      'tshirt',
      'টিশার্ট',
      'pant',
      'pants',
      'প্যান্ট',
      'trouser',
      'jeans',
      'জিন্স',
      'shoes',
      'জুতা',
      'জুতো',
      'sandal',
      'স্যান্ডেল',
      'dress',
      'ড্রেস',
      'জামা',
      'saree',
      'sari',
      'শাড়ি',
      'panjabi',
      'punjabi',
      'পাঞ্জাবি',
      'salwar',
      'সালোয়ার',
      'kameez',
      'কামিজ',
      'ওড়না',
      'হিজাব',
      'clothes',
      'clothing',
      'কাপড়',
      'পোশাক',
      'fashion',
      'ফ্যাশন',
      'bag',
      'ব্যাগ',
      'watch',
      'ঘড়ি',
      'belt',
      'বেল্ট',
      'cap',
      'টুপি',
      'jewellery',
      'jewelry',
      'গহনা',
      'cosmetics',
      'প্রসাধনী',
      'lipstick',
      'লিপস্টিক',
      'perfume',
      'পারফিউম',
      'আতর',
      'gift',
      'গিফট',
      'উপহার',
      'furniture',
      'ফার্নিচার',
      'আসবাব',
      'charger',
      'চার্জার',
      'headphone',
      'হেডফোন',
      'earphone',
      'ইয়ারফোন',
      'laptop',
      'ল্যাপটপ',
      'electronics',
      'ইলেকট্রনিক্স',
      'towel',
      'তোয়ালে',
      'blanket',
      'কম্বল',
      'bedsheet',
      'চাদর',
    ],
    ExpenseCategory.bills: [
      'rent',
      'house rent',
      'বাড়ি ভাড়া',
      'বাসা ভাড়া',
      'দোকান ভাড়া',
      'emi',
      'ইএমআই',
      'installment',
      'কিস্তি',
      'loan',
      'লোন',
      'ঋণ',
      'mortgage',
      'বন্ধক',
      'insurance',
      'বীমা',
      'ইন্স্যুরেন্স',
      'tax',
      'ট্যাক্স',
      'কর',
      'vat',
      'ভ্যাট',
      'fine',
      'জরিমানা',
      'penalty',
      'donation',
      'দান',
      'চাঁদা',
      'zakat',
      'যাকাত',
      'জাকাত',
      'sadaqah',
      'সদকা',
      'ফিতরা',
      'charity',
    ],
  };
}
