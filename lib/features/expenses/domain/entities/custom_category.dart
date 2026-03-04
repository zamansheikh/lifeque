import 'package:flutter/material.dart';

/// Represents a user-created custom expense category.
class CustomCategory {
  final String name;
  final int iconCodePoint;
  final int colorValue;

  const CustomCategory({
    required this.name,
    this.iconCodePoint = 0xe25a, // Icons.label_rounded
    this.colorValue = 0xFF7C3AED, // Purple default
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
  String get displayName => name;

  /// The key used for spending/budget matching.
  String get key => 'custom:$name';

  Map<String, dynamic> toJson() => {
    'name': name,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
  };

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe25a,
      colorValue: json['colorValue'] as int? ?? 0xFF7C3AED,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCategory &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  /// Predefined icon options for custom category creation.
  static const List<IconData> availableIcons = [
    Icons.label_rounded,
    Icons.home_rounded,
    Icons.pets_rounded,
    Icons.fitness_center_rounded,
    Icons.child_care_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_gas_station_rounded,
    Icons.phone_android_rounded,
    Icons.coffee_rounded,
    Icons.checkroom_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_rounded,
    Icons.local_laundry_service_rounded,
    Icons.build_rounded,
    Icons.brush_rounded,
    Icons.music_note_rounded,
    Icons.camera_alt_rounded,
    Icons.volunteer_activism_rounded,
    Icons.savings_rounded,
    Icons.local_parking_rounded,
  ];

  /// Predefined color options for custom category creation.
  static const List<Color> availableColors = [
    Color(0xFF7C3AED), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEF4444), // Red
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFD97706), // Amber
    Color(0xFF059669), // Emerald
    Color(0xFF6366F1), // Indigo
  ];
}
