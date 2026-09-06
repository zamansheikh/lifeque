import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/care_person.dart';

/// Stores the people a household keeps medicine for.
///
/// SharedPreferences rather than a table: this is a short list the user edits
/// by hand, never queried or joined, and keeping it out of the schema means no
/// migration every time the shape changes.
class CarePersonService {
  CarePersonService(this._prefs);

  static const String _storageKey = 'medicine_care_people';

  final SharedPreferences _prefs;

  List<CarePerson> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CarePerson.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  CarePerson? findById(String? id) {
    if (id == null) return null;
    for (final person in getAll()) {
      if (person.id == id) return person;
    }
    return null;
  }

  /// Adds a person under [name]. Returns the existing one if that name is
  /// already taken, so a double tap cannot create a duplicate.
  Future<CarePerson> add(String name) async {
    final trimmed = name.trim();
    final people = getAll();
    for (final person in people) {
      if (person.name.toLowerCase() == trimmed.toLowerCase()) return person;
    }
    final person = CarePerson(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      // Walk the palette so consecutive people are never the same colour.
      colorValue: CarePerson.palette[people.length % CarePerson.palette.length],
    );
    await _save([...people, person]);
    return person;
  }

  Future<void> rename(String id, String name) async {
    final people = getAll()
        .map((p) => p.id == id ? p.copyWith(name: name.trim()) : p)
        .toList();
    await _save(people);
  }

  Future<void> remove(String id) async {
    await _save(getAll().where((p) => p.id != id).toList());
  }

  Future<void> _save(List<CarePerson> people) async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(people.map((p) => p.toJson()).toList()),
    );
  }
}
