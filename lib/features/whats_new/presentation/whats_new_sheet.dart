import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/local_numbers.dart';
import '../../../core/services/navigation_service.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../data/whats_new_service.dart';
import '../domain/release_notes.dart';

/// The "what changed" sheet, shown once after an update.
class WhatsNewSheet extends StatelessWidget {
  const WhatsNewSheet({super.key, required this.note});

  final ReleaseNote note;

  /// Shows the notes if this build has some the user has not seen.
  ///
  /// Safe to call from anywhere on the way into the app: it decides for itself
  /// whether there is anything to say, and does nothing on a fresh install.
  static Future<void> maybeShow(BuildContext context) async {
    final service = WhatsNewService(di.sl<SharedPreferences>());
    final info = await PackageInfo.fromPlatform();
    final version = info.version;

    if (!service.shouldShow(version)) return;

    final note = releaseNoteFor(version);
    // Mark it seen either way: a build with no note should not leave the old
    // version recorded, or the next update would show two versions of news.
    await service.markSeen(version);
    if (note == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatsNewSheet(note: note),
    );
  }

  /// Queues the sheet for just after the app lands on its home screen.
  ///
  /// Called right after `context.go(...)`, when the splash's own context is on
  /// its way out — so it waits a beat and asks the navigator for the live one.
  /// The pause also reads better: the app appears first, then the sheet rises.
  static void scheduleAfterLaunch() {
    Future.delayed(const Duration(milliseconds: 700), () {
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null && context.mounted) maybeShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.whatsNewTitle,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note.headline(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l.whatsNewVersion(N.digits(note.version)),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              itemCount: note.lines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _Line(line: note.lines[i]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, 10, 22, media.padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l.whatsNewGotIt,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final ReleaseLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(line.icon, size: 17, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line.of(context),
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
