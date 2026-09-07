import '../../core/services/navigation_service.dart';
import '../whats_new/presentation/whats_new_sheet.dart';
import 'daily_nudge.dart';

/// What the app may say on its way in, in order: the release notes after an
/// update, otherwise today's suggestion. Never both — one sheet on launch is
/// a greeting, two is a queue.
class LaunchPrompts {
  /// Queues the prompts for just after the app lands on its home screen.
  ///
  /// Called right after `context.go(...)`, when the splash's own context is on
  /// its way out — so it waits a beat and asks the navigator for the live one.
  /// The pause also reads better: the app appears first, then the sheet rises.
  static void scheduleAfterLaunch() {
    Future.delayed(const Duration(milliseconds: 700), () async {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      final showedNews = await WhatsNewSheet.maybeShow(context);
      if (showedNews || !context.mounted) return;
      await DailyNudge.maybeShow(context);
    });
  }
}
