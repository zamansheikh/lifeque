import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/whats_new/domain/release_notes.dart';

/// pubspec.yaml is the one hand-typed version. Everything that repeats it
/// must agree, or the bump is not finished.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec)!;
  final name = match.group(1)!;
  final build = match.group(2)!;

  test('the newest release note is for the pubspec version', () {
    expect(
      kReleaseNotes.first.version,
      name,
      reason: 'pubspec is $name — add or retarget the release note',
    );
  });

  test(
    'the docs carry the pubspec version (dart run tool/sync_version.dart)',
    () {
      final privacy = File('docs/privacy-policy.html').readAsStringSync();
      final index = File('docs/index.html').readAsStringSync();
      expect(
        RegExp(
          r'<span id="app-version">([^<]*)</span>',
        ).firstMatch(privacy)?.group(1),
        '$name+$build',
      );
      expect(
        RegExp(
          r'<span class="pill" id="app-version">([^<]*)</span>',
        ).firstMatch(index)?.group(1),
        'VERSION $name',
      );
    },
  );

  test('native builds do not hard-code a version of their own', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('versionName = flutter.versionName'));
    expect(gradle, contains('versionCode = flutter.versionCode'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains(r'$(FLUTTER_BUILD_NAME)'));
    expect(plist, contains(r'$(FLUTTER_BUILD_NUMBER)'));
  });
}
