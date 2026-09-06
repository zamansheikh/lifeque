import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/whats_new/data/whats_new_service.dart';
import 'package:lifeque/features/whats_new/domain/release_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<WhatsNewService> serviceWith(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  return WhatsNewService(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shows on a fresh install, then not again', () async {
    final service = await serviceWith({});
    expect(service.isFirstRun, isTrue);
    expect(service.shouldShow('2.0.0'), isTrue);

    await service.markSeen('2.0.0');
    expect(service.shouldShow('2.0.0'), isFalse);
  });

  test('shows once after an update, then stays quiet', () async {
    final service = await serviceWith({'whats_new_last_seen_version': '0.9.0'});
    expect(service.isFirstRun, isFalse);
    expect(service.shouldShow('2.0.0'), isTrue);

    await service.markSeen('2.0.0');
    expect(service.shouldShow('2.0.0'), isFalse);
  });

  test('stays quiet when the version has not moved', () async {
    final service = await serviceWith({'whats_new_last_seen_version': '2.0.0'});
    expect(service.shouldShow('2.0.0'), isFalse);
  });

  group('release notes', () {
    test('the newest note is for the version in pubspec', () {
      // Read rather than hard-coded: the sheet only shows when the note's
      // version matches the running build, so a bump that forgets the note
      // silently ships a release nobody is told about.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*(\d+\.\d+\.\d+)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1)!;

      expect(
        kReleaseNotes.first.version,
        version,
        reason: 'pubspec is $version — add a release note for it',
      );
      expect(releaseNoteFor(version), isNotNull);
    });

    test('an unknown version simply has nothing to say', () {
      expect(releaseNoteFor('9.9.9'), isNull);
    });

    test('every line is written in both languages', () {
      for (final note in kReleaseNotes) {
        expect(note.headlineEn, isNotEmpty);
        expect(note.headlineBn, isNotEmpty);
        for (final line in note.lines) {
          expect(
            line.en,
            isNotEmpty,
            reason: '${note.version} missing English',
          );
          expect(line.bn, isNotEmpty, reason: '${note.version} missing Bangla');
        }
      }
    });
  });
}
