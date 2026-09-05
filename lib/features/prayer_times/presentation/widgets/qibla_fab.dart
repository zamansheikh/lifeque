import 'package:flutter/material.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import 'qibla_card.dart';

/// Floating action button that surfaces Qibla without taking permanent
/// space on the page. Tapping opens a full-screen sheet with the live
/// compass.
class QiblaFab extends StatelessWidget {
  final SalahTimeCalculator? calculator;
  const QiblaFab({super.key, required this.calculator});

  void _open(BuildContext context) {
    final calc = calculator;
    if (calc == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QiblaSheet(calculator: calc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: calculator == null ? null : () => _open(context),
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      foregroundColor: Colors.black87,
      elevation: 6,
      icon: const Icon(Icons.explore_rounded),
      label: const Text('Qibla', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _QiblaSheet extends StatelessWidget {
  final SalahTimeCalculator calculator;
  const _QiblaSheet({required this.calculator});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore_rounded),
                  const SizedBox(width: 8),
                  const Text(
                    'Qibla Compass',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: QiblaCard(calculator: calculator),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
