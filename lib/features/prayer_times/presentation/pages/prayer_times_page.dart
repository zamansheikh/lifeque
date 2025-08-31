import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/salah_time_calculator.dart';
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
  String? _error;

  // Default coordinates for Bangladesh (Dhaka)
  double _latitude = 23.8103;
  double _longitude = 90.4125;
  String _locationName = 'Dhaka, Bangladesh';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _updatePrayerTimes();
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

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error =
              'Location services are disabled. Using default location (Dhaka, Bangladesh).';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error =
                'Location permission denied. Using default location (Dhaka, Bangladesh).';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Location permissions are permanently denied. Using default location (Dhaka, Bangladesh).';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationName = 'Current Location';
        });

        _updatePrayerTimes();
      } catch (e) {
        setState(() {
          _error =
              'Could not get current location. Using default location (Dhaka, Bangladesh).';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error requesting location permission: $e';
        _isLoading = false;
      });
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
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMethod = value;
              });
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
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMadhab = value;
              });
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
              Icon(Icons.location_on, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        ],
      ),
    );
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
