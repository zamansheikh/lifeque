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
    expect(service.shouldShow('1.0.0'), isTrue);

    await service.markSeen('1.0.0');
    expect(service.shouldShow('1.0.0'), isFalse);
  });

  test('shows once after an update, then stays quiet', () async {
    final service = await serviceWith({'whats_new_last_seen_version': '0.9.0'});
    expect(service.isFirstRun, isFalse);
    expect(service.shouldShow('1.0.0'), isTrue);

    await service.markSeen('1.0.0');
    expect(service.shouldShow('1.0.0'), isFalse);
  });

  test('stays quiet when the version has not moved', () async {
    final service = await serviceWith({'whats_new_last_seen_version': '1.0.0'});
    expect(service.shouldShow('1.0.0'), isFalse);
  });

  group('release notes', () {
    test('this build has a note, and it matches pubspec', () {
      expect(releaseNoteFor('1.0.0'), isNotNull);
      expect(kReleaseNotes.first.version, '1.0.0');
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
