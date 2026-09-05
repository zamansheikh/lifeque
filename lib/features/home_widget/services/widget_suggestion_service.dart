import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four home-screen widgets a user can pin, in the order we offer them.
enum PinnableWidget {
  currentWaqt(
    'Current waqt',
    'The running prayer, its window and a live countdown.',
    'com.programmernexus.lifeque.PrayerTimesWidgetProvider',
  ),
  mosqueJamaat(
    'Mosque jamaat',
    "Your mosque's congregation times, in Bangla.",
    'com.programmernexus.lifeque.MosqueTimesWidgetProvider',
  ),
  dayMap(
    'Prayer day map',
    'The whole day on one track, with prohibited windows.',
    'com.programmernexus.lifeque.DayTimelineWidgetProvider',
  ),
  slimBar(
    'Slim bar',
    'One line: next prayer and time remaining.',
    'com.programmernexus.lifeque.SlimBarWidgetProvider',
  );

  final String title;
  final String description;
  final String provider;

  const PinnableWidget(this.title, this.description, this.provider);
}

/// Decides when to offer the home-screen widget, and remembers the answer.
///
/// The prompt is worth showing exactly once, right after the user has set a
/// location — before that the widget has nothing to display, and nagging past
/// a decline is what makes these prompts obnoxious.
class WidgetSuggestionService {
  static const _dismissedKey = 'widget_suggestion_dismissed_v1';
  static const _pinnedKey = 'widget_suggestion_pinned_v1';

  static final WidgetSuggestionService instance = WidgetSuggestionService._();
  WidgetSuggestionService._();

  /// Whether this device's launcher supports one-tap pinning at all.
  /// Android 8+ only, and some launchers still opt out.
  Future<bool> get isSupported async {
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// True when we should offer the widget: the user has a location set, the
  /// launcher supports pinning, and they haven't already said no or yes.
  Future<bool> shouldSuggest({required bool hasLocation}) async {
    if (!hasLocation) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return false;
    if (prefs.getBool(_pinnedKey) ?? false) return false;

    // Already has one on the home screen? Then there is nothing to suggest.
    try {
      final installed = await HomeWidget.getInstalledWidgets();
      if (installed.isNotEmpty) {
        await markPinned();
        return false;
      }
    } catch (_) {
      // Older launchers can fail this query; fall through and still offer.
    }
    return isSupported;
  }

  /// Ask the launcher to pin [widget]. The system shows its own confirmation,
  /// so a success here means "asked", not "placed".
  Future<void> pin(PinnableWidget widget) async {
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: widget.provider,
    );
    await markPinned();
  }

  Future<void> markPinned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinnedKey, true);
  }

  /// "Not now" — don't ask again unasked. The More tab still offers it.
  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }
}
