import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Someone a course of medicine belongs to — the user, a parent, a child.
///
/// Deliberately thin. This exists so a household sharing one phone can tell
/// whose 8 o'clock dose the reminder is for; it is not a medical record, and
/// nothing here should grow into one without a reason.
class CarePerson extends Equatable {
  const CarePerson({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final String id;
  final String name;
  final int colorValue;

  Color get color => Color(colorValue);

  /// First letter, for the avatar. Works for Bangla and Latin alike.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim().characters.first;

  CarePerson copyWith({String? name, int? colorValue}) => CarePerson(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  factory CarePerson.fromJson(Map<String, dynamic> json) => CarePerson(
    id: json['id'] as String,
    name: json['name'] as String,
    colorValue: json['colorValue'] as int,
  );

  /// The palette new people are drawn from, in order, so two people added one
  /// after another never look alike.
  static const List<int> palette = [
    0xFF3B82F6, // blue
    0xFF10B981, // green
    0xFFF59E0B, // amber
    0xFFEC4899, // pink
    0xFF8B5CF6, // violet
    0xFF06B6D4, // cyan
    0xFFEF4444, // red
    0xFF84CC16, // lime
  ];

  @override
  List<Object?> get props => [id, name, colorValue];
}
