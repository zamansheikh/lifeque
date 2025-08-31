import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/salah_time_calculator.dart';
import '../../data/services/prayer_settings_service.dart';
import '../widgets/prayer_time_card.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/qibla_card.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  SalahTimeCalculator? _calculator;
  Timer? _timer;
  DateTime _selectedDate = DateTime.now();
  CalculationMethod _selectedMethod = CalculationMethod.karachi;
  Madhab _selectedMadhab = Madhab.hanafi;
  bool _isLoading = true;
  bool _isLocationUpdating = false; // Track background location updates
  String? _error;

  // Default coordinates for Bangladesh (Dhaka)
  double _latitude = 23.8103;
  double _longitude = 90.4125;
  String _locationName = 'Dhaka, Bangladesh';
  bool _isLocationFromGps = false;

  final PrayerSettingsService _settingsService = PrayerSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild to update the countdown
        });
      }
    });
  }

  Future<void> _loadSavedSettings() async {
    // Step 1: Quick load from saved data (if available)
    await _loadFromSavedData();

    // Step 2: Try to get current location in background and update if successful
    _updateLocationInBackground();
  }

  Future<void> _loadFromSavedData() async {
    try {
      // Load saved prayer settings
      _selectedMethod = await _settingsService.getCalculationMethod();
      _selectedMadhab = await _settingsService.getMadhab();

      // Try to load saved location first for immediate display
      final savedLocation = await _settingsService.getSavedLocation();
      if (savedLocation != null) {
        setState(() {
          _latitude = savedLocation.latitude;
          _longitude = savedLocation.longitude;
          _locationName = savedLocation.locationName;
          _isLocationFromGps = savedLocation.isFromGps;
          _error = null;
          _isLoading = false; // Show prayer times immediately
        });
        _updatePrayerTimes();
        debugPrint('✅ Fast load: Using saved location for immediate display');
      } else {
        // No saved location, need to get current location first
        debugPrint('ℹ️ No saved location found, getting current location...');
        setState(() => _isLoading = true);
        await _requestLocationPermission();
        if (!_isLocationFromGps) {
          // GPS failed and no saved location, use default
          setState(() {
            _error = 'No location found. Using default location (Dhaka, Bangladesh). Tap refresh to get your location.';
            _isLoading = false;
          });
        }
        _updatePrayerTimes();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading prayer settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocationInBackground() async {
    try {
      setState(() => _isLocationUpdating = true);
      debugPrint('🔄 Background: Attempting to get current GPS location...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Background: Location services disabled');
        setState(() => _isLocationUpdating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Background: Location permission denied');
          setState(() => _isLocationUpdating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Background: Location permissions permanently denied');
        setState(() => _isLocationUpdating = false);
        return;
      }

      // Get current position with timeout
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        // Check if location has changed significantly (>100m)
        double distance = Geolocator.distanceBetween(_latitude, _longitude, position.latitude, position.longitude);
        
        if (distance > 100) { // Only update if moved more than 100 meters
          // Save new GPS location
          await _settingsService.saveLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            locationName: 'Current Location',
            isFromGps: true,
          );

          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _locationName = 'Current Location';
            _isLocationFromGps = true;
            _error = null;
          });

          _updatePrayerTimes();
          debugPrint('✅ Background: Location updated from GPS (moved ${distance.toInt()}m)');
          
          // Show subtle notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 Location updated from GPS'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          debugPrint('ℹ️ Background: Location unchanged (${distance.toInt()}m), keeping current');
        }
      } catch (e) {
        debugPrint('❌ Background: Could not get current location: $e');
      }
    } catch (e) {
      debugPrint('❌ Background: Error updating location: $e');
    } finally {
      setState(() => _isLocationUpdating = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Get current position
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        // Save GPS location
        await _settingsService.saveLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: 'Current Location',
          isFromGps: true,
        );

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationName = 'Current Location';
          _isLocationFromGps = true;
          _error = null;
        });

        debugPrint('GPS location obtained: $_latitude, $_longitude');
      } catch (e) {
        debugPrint('Could not get current location: $e');
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }

  void _updatePrayerTimes() {
    try {
      _calculator = SalahTimeCalculator(
        latitude: _latitude,
        longitude: _longitude,
        date: _selectedDate,
        method: _selectedMethod,
        madhab: _selectedMadhab,
      );
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error calculating prayer times: $e';
        _isLoading = false;
      });
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Prayer Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calculation Method
                  const Text(
                    'Calculation Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildMethodDropdown(),
                  const SizedBox(height: 24),

                  // Madhab
                  const Text(
                    'Madhab (For Asr Calculation)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildMadhabDropdown(),
                  const SizedBox(height: 24),

                  // Location
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationCard(),
                  const SizedBox(height: 12),
                  _buildManualLocationButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CalculationMethod>(
          value: _selectedMethod,
          onChanged: (value) async {
            if (value != null) {
              setState(() {
                _selectedMethod = value;
              });
              await _settingsService.saveCalculationMethod(value);
              _updatePrayerTimes();
            }
          },
          items:
              [
                CalculationMethod.karachi,
                CalculationMethod.muslim_world_league,
                CalculationMethod.egyptian,
                CalculationMethod.umm_al_qura,
                CalculationMethod.dubai,
                CalculationMethod.kuwait,
                CalculationMethod.qatar,
                CalculationMethod.singapore,
                CalculationMethod.turkey,
                CalculationMethod.tehran,
              ].map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.displayName),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMadhabDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Madhab>(
          value: _selectedMadhab,
          onChanged: (value) async {
            if (value != null) {
              setState(() {
                _selectedMadhab = value;
              });
              await _settingsService.saveMadhab(value);
              _updatePrayerTimes();
            }
          },
          items: const [
            DropdownMenuItem(
              value: Madhab.hanafi,
              child: Text('Hanafi (Later Asr)'),
            ),
            DropdownMenuItem(
              value: Madhab.shafi,
              child: Text('Shafi (Earlier Asr)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isLocationFromGps ? Icons.my_location : Icons.location_on,
                color: _isLocationFromGps ? Colors.green : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _isLocationFromGps ? 'GPS Location' : 'Saved Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLocationFromGps
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isLocationUpdating ? null : _refreshLocation,
                icon: _isLocationUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                tooltip: _isLocationUpdating ? 'Updating...' : 'Refresh Location',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Latitude: ${_latitude.toStringAsFixed(4)}°',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            'Longitude: ${_longitude.toStringAsFixed(4)}°',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (!_isLocationFromGps) ...[
            const SizedBox(height: 8),
            Text(
              '💡 Tap refresh to get current GPS location',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLocationUpdating = true);
    
    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Getting your current location...'),
        duration: Duration(seconds: 1),
      ),
    );

    await _requestLocationPermission();
    
    setState(() => _isLocationUpdating = false);
    
    if (_isLocationFromGps) {
      _updatePrayerTimes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Location updated from GPS'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // If GPS failed, keep using saved location
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Could not get GPS location. Using saved location.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildManualLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showManualLocationDialog,
        icon: const Icon(Icons.edit_location),
        label: const Text('Set Location Manually'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _showManualLocationDialog() async {
    final latController = TextEditingController(text: _latitude.toString());
    final lngController = TextEditingController(text: _longitude.toString());
    final nameController = TextEditingController(text: _locationName);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Home, Office',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: '23.8103',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: '90.4125',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              final name = nameController.text.trim();

              if (lat != null && lng != null && name.isNotEmpty) {
                Navigator.pop(context, {
                  'latitude': lat,
                  'longitude': lng,
                  'name': name,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Save manual location
      await _settingsService.saveLocation(
        latitude: result['latitude'],
        longitude: result['longitude'],
        locationName: result['name'],
        isFromGps: false,
      );

      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationName = result['name'];
        _isLocationFromGps = false;
        _error = null;
      });

      _updatePrayerTimes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated manually'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Prayer Times',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings, size: 20, color: colorScheme.primary),
            ),
            onPressed: _showSettingsBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _updatePrayerTimes();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _updatePrayerTimes();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector
                    _buildDateSelector(),
                    const SizedBox(height: 20),

                    // Next Prayer Card
                    NextPrayerCard(calculator: _calculator!),
                    const SizedBox(height: 20),

                    // Prayer Times
                    _buildPrayerTimesList(),
                    const SizedBox(height: 20),

                    // Qibla Direction
                    QiblaCard(calculator: _calculator!),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
                _updatePrayerTimes();
              }
            },
            icon: const Icon(Icons.edit_calendar),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    if (_calculator == null) return const SizedBox();

    final prayerTimes = _calculator!.getPrayerTimesMap();
    final currentPrayer = _calculator!.getCurrentPrayer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prayer Times',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...prayerTimes.entries.map((entry) {
          // Skip Sunrise as it's not a prayer
          if (entry.key == 'Sunrise') return const SizedBox();

          final prayer = _getPrayerFromString(entry.key);
          final isActive = currentPrayer == prayer;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PrayerTimeCard(
              name: entry.key,
              time: entry.value,
              isActive: isActive,
            ),
          );
        }).toList(),
      ],
    );
  }

  Prayer _getPrayerFromString(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Prayer.fajr;
      case 'dhuhr':
        return Prayer.dhuhr;
      case 'asr':
        return Prayer.asr;
      case 'maghrib':
        return Prayer.maghrib;
      case 'isha':
        return Prayer.isha;
      default:
        return Prayer.none;
    }
  }
}
