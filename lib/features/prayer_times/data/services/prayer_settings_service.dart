import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';

class PrayerSettingsService {
  static const String _latitudeKey = 'prayer_latitude';
  static const String _longitudeKey = 'prayer_longitude';
  static const String _locationNameKey = 'prayer_location_name';
  static const String _calculationMethodKey = 'prayer_calculation_method';
  static const String _madhabKey = 'prayer_madhab';
  static const String _isLocationFromGpsKey = 'prayer_is_location_from_gps';

  static PrayerSettingsService? _instance;
  SharedPreferences? _prefs;

  static PrayerSettingsService get instance {
    _instance ??= PrayerSettingsService._();
    return _instance!;
  }

  PrayerSettingsService._();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Location methods
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
    required String locationName,
    bool isFromGps = false,
  }) async {
    await init();
    await _prefs!.setDouble(_latitudeKey, latitude);
    await _prefs!.setDouble(_longitudeKey, longitude);
    await _prefs!.setString(_locationNameKey, locationName);
    await _prefs!.setBool(_isLocationFromGpsKey, isFromGps);
  }

  Future<LocationData?> getSavedLocation() async {
    await init();
    final latitude = _prefs!.getDouble(_latitudeKey);
    final longitude = _prefs!.getDouble(_longitudeKey);
    final locationName = _prefs!.getString(_locationNameKey);
    final isFromGps = _prefs!.getBool(_isLocationFromGpsKey) ?? false;

    if (latitude != null && longitude != null && locationName != null) {
      return LocationData(
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        isFromGps: isFromGps,
      );
    }
    return null;
  }

  Future<bool> hasLocationData() async {
    await init();
    return _prefs!.containsKey(_latitudeKey) &&
        _prefs!.containsKey(_longitudeKey) &&
        _prefs!.containsKey(_locationNameKey);
  }

  // Prayer settings methods
  Future<void> saveCalculationMethod(CalculationMethod method) async {
    await init();
    await _prefs!.setString(_calculationMethodKey, method.name);
  }

  Future<CalculationMethod> getCalculationMethod() async {
    await init();
    final methodName = _prefs!.getString(_calculationMethodKey);
    if (methodName != null) {
      return _getCalculationMethodFromName(methodName);
    }
    return CalculationMethod.karachi; // Default
  }

  Future<void> saveMadhab(Madhab madhab) async {
    await init();
    await _prefs!.setString(_madhabKey, madhab.name);
  }

  Future<Madhab> getMadhab() async {
    await init();
    final madhabName = _prefs!.getString(_madhabKey);
    if (madhabName != null) {
      return madhabName == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    }
    return Madhab.hanafi; // Default
  }

  // Clear all prayer data
  Future<void> clearAllData() async {
    await init();
    await _prefs!.remove(_latitudeKey);
    await _prefs!.remove(_longitudeKey);
    await _prefs!.remove(_locationNameKey);
    await _prefs!.remove(_calculationMethodKey);
    await _prefs!.remove(_madhabKey);
    await _prefs!.remove(_isLocationFromGpsKey);
  }

  // Helper method to convert method name to enum
  CalculationMethod _getCalculationMethodFromName(String name) {
    switch (name.toLowerCase()) {
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league;
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'turkey':
        return CalculationMethod.turkey;
      case 'tehran':
        return CalculationMethod.tehran;
      case 'moon_sighting_committee':
        return CalculationMethod.moon_sighting_committee;
      case 'north_america':
        return CalculationMethod.north_america;
      default:
        return CalculationMethod.karachi;
    }
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isFromGps;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.isFromGps,
  });

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, name: $locationName, isFromGps: $isFromGps)';
  }
}
