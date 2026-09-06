# What's New sheet

Shows a short, illustrated summary of the release the first time the app runs
on a new version — and on a fresh install, where it doubles as an introduction.

## How it decides

`WhatsNewService` keeps the last version it announced in `SharedPreferences`
under `whats_new_last_seen_version`.

| Situation | Result |
| --- | --- |
| Fresh install, nothing recorded | Shows |
| Stored version differs from the running build | Shows |
| Stored version matches | Stays quiet |
| Opened by tapping a home-screen widget | Stays quiet — the user asked for that screen |

The version is recorded the moment the sheet is shown, and *also* for a build
that has no note at all. Without that second case the old version would stay
recorded and the next update would announce two releases at once.

## Adding a release

Add an entry to the top of `kReleaseNotes` in
`lib/features/whats_new/domain/release_notes.dart`, keyed by the version name
in `pubspec.yaml`:

```dart
ReleaseNote(
  version: '2.1.0',
  headlineEn: '…',
  headlineBn: '…',
  lines: [
    ReleaseLine(Icons.translate_rounded, 'English line', 'বাংলা লাইন'),
  ],
),
```

Both languages sit side by side in the same file rather than in the ARB
bundles. Release notes are append-only and version-scoped, so routing every
bullet through the translation files would grow them permanently with strings
nobody reads after an update or two.

A version with no entry simply shows nothing — the sheet is skipped and the
version recorded.

## The guard

`test/whats_new_service_test.dart` reads `pubspec.yaml` and asserts the newest
release note matches it. Bumping the version without adding a note would
otherwise ship a release with the announcement silently disabled, and nothing
would complain:

```
pubspec is 2.1.0 — add a release note for it
```

## Where it is triggered

Two entry points into the app, both scheduled ~700 ms after navigation so the
home screen appears first:

- `SplashScreen` — a normal launch straight to home
- `PermissionScreen.onPermissionsGranted` — the first run after onboarding

## Files

| Path | Role |
| --- | --- |
| `features/whats_new/domain/release_notes.dart` | The notes themselves |
| `features/whats_new/data/whats_new_service.dart` | Remembers what was shown |
| `features/whats_new/presentation/whats_new_sheet.dart` | The sheet, and `scheduleAfterLaunch()` |
