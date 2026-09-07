// Copies the version from pubspec.yaml into every file that has to state it
// but cannot read it at runtime — the static docs pages.
//
//   dart run tool/sync_version.dart
//
// pubspec.yaml is the one place a version is typed by hand. The Android and
// iOS builds read it through Flutter, the About sheet and What's New read it
// through package_info at runtime, and this script stamps it into the docs.
// test/version_consistency_test.dart fails when anything drifts, so a bump
// that forgets this step is caught before release.
import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('pubspec.yaml has no "version: x.y.z+n" line');
    exit(1);
  }
  final name = match.group(1)!;
  final build = match.group(2)!;
  final today = _longDate(DateTime.now());

  final edits = <String, List<(RegExp, String)>>{
    'docs/privacy-policy.html': [
      (
        RegExp(r'(<span id="app-version">)[^<]*(</span>)'),
        '\${1}$name+$build\${2}',
      ),
      (RegExp(r'(<span id="last-updated">)[^<]*(</span>)'), '\${1}$today\${2}'),
    ],
    'docs/index.html': [
      (
        RegExp(r'(<span class="pill" id="app-version">)[^<]*(</span>)'),
        '\${1}VERSION $name\${2}',
      ),
    ],
  };

  var changed = 0;
  edits.forEach((path, rules) {
    final file = File(path);
    var text = file.readAsStringSync();
    final before = text;
    for (final (pattern, replacement) in rules) {
      if (!pattern.hasMatch(text)) {
        stderr.writeln('$path: marker not found for $pattern');
        exit(1);
      }
      text = text.replaceFirstMapped(
        pattern,
        (m) => replacement
            .replaceAll(r'${1}', m.group(1)!)
            .replaceAll(r'${2}', m.group(2)!),
      );
    }
    if (text != before) {
      file.writeAsStringSync(text);
      changed++;
    }
  });
  stdout.writeln('version $name+$build — $changed file(s) updated');
}

String _longDate(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
