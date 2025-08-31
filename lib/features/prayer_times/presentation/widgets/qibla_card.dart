import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../../core/utils/salah_time_calculator.dart';

class QiblaCard extends StatefulWidget {
  final SalahTimeCalculator calculator;

  const QiblaCard({super.key, required this.calculator});

  @override
  State<QiblaCard> createState() => _QiblaCardState();
}

class _QiblaCardState extends State<QiblaCard>
    with SingleTickerProviderStateMixin {
  double? _compassDirection;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasCompass = false;
  bool _isCompassLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initCompass() async {
    try {
      // Start listening to compass events directly
      _compassSubscription = FlutterCompass.events?.listen(
        (CompassEvent event) {
          if (mounted) {
            setState(() {
              _compassDirection = event.heading;
              _hasCompass = true;
              _isCompassLoading = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Compass error: $error');
          setState(() {
            _hasCompass = false;
            _isCompassLoading = false;
          });
        },
      );

      // Set timeout for compass detection
      Timer(const Duration(seconds: 2), () {
        if (_isCompassLoading) {
          setState(() {
            _hasCompass = false;
            _isCompassLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing compass: $e');
      setState(() {
        _hasCompass = false;
        _isCompassLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final qiblaDirection = widget.calculator.getQiblaDirection();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _hasCompass ? Icons.explore : Icons.navigation,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Qibla Direction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_hasCompass) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _hasCompass ? 'Live compass direction' : 'Towards Mecca',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Qibla Compass
          Center(
            child: Column(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass background
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      // Compass markings (N, E, S, W)
                      if (_hasCompass) _buildCompassMarkings(),

                      // Device direction indicator (if compass available)
                      if (_hasCompass && _compassDirection != null)
                        Transform.rotate(
                          angle: (_compassDirection! * (math.pi / 180)),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.phone_android,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        ),

                      // Qibla arrow
                      Transform.rotate(
                        angle: _hasCompass && _compassDirection != null
                            ? ((qiblaDirection - _compassDirection!) * (math.pi / 180))
                            : (qiblaDirection * (math.pi / 180)),
                        child: Icon(
                          Icons.navigation,
                          color: _hasCompass ? Colors.green : colorScheme.primary,
                          size: 40,
                        ),
                      ),

                      // Center dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _hasCompass ? Colors.green : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),

                      // Loading indicator
                      if (_isCompassLoading)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Direction info
                Column(
                  children: [
                    Text(
                      '${qiblaDirection.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _hasCompass ? Colors.green : colorScheme.primary,
                      ),
                    ),
                    Text(
                      'from North',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    if (_hasCompass && _compassDirection != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Device: ${_compassDirection!.toStringAsFixed(1)}°',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hasCompass ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hasCompass ? Colors.green.shade200 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasCompass ? Icons.compass_calibration : Icons.info_outline,
                  color: _hasCompass ? Colors.green.shade600 : Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasCompass
                        ? 'Hold device flat and point green arrow towards Mecca'
                        : 'Point your device towards ${qiblaDirection.toStringAsFixed(1)}° from North to face Qibla',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasCompass ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassMarkings() {
    return Stack(
      children: [
        // North
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'N',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),
        // East
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              'E',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
        // South
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'S',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
        // West
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              'W',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
