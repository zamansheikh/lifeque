import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/custom_category.dart';

/// Manages user-created custom expense categories via SharedPreferences.
class CustomCategoryService {
  static const String _storageKey = 'custom_expense_categories';

  final SharedPreferences _prefs;

  CustomCategoryService(this._prefs);

  /// Get all custom categories.
  List<CustomCategory> getAll() {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => CustomCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new custom category. Returns false if name already exists.
  Future<bool> add(CustomCategory category) async {
    final existing = getAll();
    if (existing.any(
      (c) => c.name.toLowerCase() == category.name.toLowerCase(),
    )) {
      return false;
    }
    existing.add(category);
    return _save(existing);
  }

  /// Remove a custom category by name.
  Future<bool> remove(String name) async {
    final existing = getAll();
    existing.removeWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    return _save(existing);
  }

  /// Update an existing custom category.
  Future<bool> update(String oldName, CustomCategory updated) async {
    final existing = getAll();
    final index = existing.indexWhere(
      (c) => c.name.toLowerCase() == oldName.toLowerCase(),
    );
    if (index == -1) return false;
    existing[index] = updated;
    return _save(existing);
  }

  /// Find a custom category by name (case-insensitive).
  CustomCategory? findByName(String name) {
    final all = getAll();
    try {
      return all.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<bool> _save(List<CustomCategory> categories) {
    final jsonStr = jsonEncode(categories.map((c) => c.toJson()).toList());
    return _prefs.setString(_storageKey, jsonStr);
  }
}
