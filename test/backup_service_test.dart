import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _freshDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 10,
      singleInstance: false,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT NOT NULL, '
          'isCompleted INTEGER NOT NULL DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE medicines (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
        );
      },
    ),
  );
  return db;
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late SharedPreferences prefs;
  late BackupService service;
  final created = DateTime.utc(2026, 10, 27, 9, 30);

  setUp(() async {
    db = await _freshDb();
    SharedPreferences.setMockInitialValues({
      'app_language_code': 'bn',
      'prayer_alarms_enabled': true,
      'prayer_calculation_method': 2,
      'prayer_latitude': 23.81,
      'prayer_alarms': ['{"prayerName":"Fajr"}'],
      // Belongs to this phone, never to a backup:
      '__alarm_id__1000': '{"id":1000}',
      'study_session_v2': '{"running":true}',
      'medicine_notification_ids': '[1,2]',
    });
    prefs = await SharedPreferences.getInstance();
    service = BackupService(
      database: () async => db,
      prefs: () async => prefs,
      appVersion: '2.2.4+37',
      now: () => created,
    );
    await db.insert('tasks', {'id': 't1', 'title': 'Pay rent'});
    await db.insert('tasks', {'id': 't2', 'title': 'Ammu birthday'});
    await db.insert('medicines', {'id': 'm1', 'name': 'Napa'});
  });

  tearDown(() => db.close());

  test('a round trip brings everything back, with types intact', () async {
    final json = await service.export();

    // The phone changes after the backup...
    await db.delete('tasks');
    await db.insert('tasks', {'id': 'x', 'title': 'Made later'});
    await db.delete('medicines');
    await prefs.setString('app_language_code', 'en');
    await prefs.setString('later_setting', 'only on the phone');
    await prefs.remove('prayer_latitude');

    await service.restore(json);

    final tasks = await db.query('tasks', orderBy: 'id');
    expect(tasks.map((r) => r['title']), ['Pay rent', 'Ammu birthday']);
    expect((await db.query('medicines')).single['name'], 'Napa');

    expect(prefs.getString('app_language_code'), 'bn');
    expect(prefs.getBool('prayer_alarms_enabled'), isTrue);
    expect(prefs.getInt('prayer_calculation_method'), 2);
    expect(prefs.getDouble('prayer_latitude'), 23.81);
    expect(prefs.getStringList('prayer_alarms'), ['{"prayerName":"Fajr"}']);
    expect(prefs.containsKey('later_setting'), isFalse, reason: 'replaced');
  });

  test('device-only settings are neither exported nor overwritten', () async {
    final json = await service.export();
    final settings =
        (jsonDecode(json) as Map<String, dynamic>)['settings'] as Map;
    expect(settings.keys, isNot(contains('__alarm_id__1000')));
    expect(settings.keys, isNot(contains('study_session_v2')));
    expect(settings.keys, isNot(contains('medicine_notification_ids')));

    await prefs.setString('study_session_v2', '{"running":"now"}');
    await service.restore(json);
    expect(prefs.getString('study_session_v2'), '{"running":"now"}');
    expect(prefs.getString('__alarm_id__1000'), '{"id":1000}');
  });

  test('the summary says what is inside before restoring', () async {
    final summary = service.inspect(await service.export());
    expect(summary.rowsIn('tasks'), 2);
    expect(summary.rowsIn('medicines'), 1);
    expect(summary.appVersion, '2.2.4+37');
    expect(summary.createdAt.toUtc(), created);
    expect(summary.settings, 5);
    expect(service.fileName(), 'lifeque-backup-2026-10-27.json');
  });

  test('other files are refused without touching anything', () async {
    for (final bad in [
      'not json at all',
      '{"hello": "world"}',
      jsonEncode({'app': 'other', 'format': 1, 'settings': {}, 'tables': {}}),
    ]) {
      expect(
        () => service.restore(bad),
        throwsA(
          isA<BackupException>().having(
            (e) => e.problem,
            'problem',
            BackupProblem.notABackup,
          ),
        ),
      );
    }
    expect(await db.query('tasks'), hasLength(2));
  });

  test('a backup from a newer format is refused', () {
    final newer = jsonEncode({
      'app': 'lifeque',
      'format': BackupService.formatVersion + 1,
      'settings': {},
      'tables': {},
    });
    expect(
      () => service.inspect(newer),
      throwsA(
        isA<BackupException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.tooNew,
        ),
      ),
    );
  });

  test('schema differences between versions are tolerated', () async {
    final data = jsonDecode(await service.export()) as Map<String, dynamic>;
    final tables = data['tables'] as Map<String, dynamic>;
    // A newer app's extra column, an older app's missing column, and a
    // table this version does not have.
    tables['tasks'] = [
      {'id': 'n1', 'title': 'From another version', 'colorTag': 'red'},
    ];
    tables['habits'] = [
      {'id': 'h1'},
    ];

    await service.restore(jsonEncode(data));
    final row = (await db.query('tasks')).single;
    expect(row['title'], 'From another version');
    expect(row['isCompleted'], 0, reason: 'missing column takes its default');
  });

  test(
    'a failed write leaves data and settings exactly as they were',
    () async {
      final data = jsonDecode(await service.export()) as Map<String, dynamic>;
      (data['tables'] as Map<String, dynamic>)['tasks'] = [
        {'id': 'ok', 'title': 'fine'},
        {'id': 'bad'}, // title is NOT NULL
      ];
      (data['settings'] as Map<String, dynamic>)['app_language_code'] = {
        't': 's',
        'v': 'en',
      };

      await expectLater(
        service.restore(jsonEncode(data)),
        throwsA(
          isA<BackupException>().having(
            (e) => e.problem,
            'problem',
            BackupProblem.writeFailed,
          ),
        ),
      );
      final titles = (await db.query(
        'tasks',
        orderBy: 'id',
      )).map((r) => r['title']);
      expect(titles, ['Pay rent', 'Ammu birthday']);
      expect(prefs.getString('app_language_code'), 'bn');
    },
  );
}
