import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/medicines/domain/entities/medicine_dose.dart';

MedicineDose doseAt(DateTime when, {DoseStatus status = DoseStatus.pending}) =>
    MedicineDose(
      id: 'd',
      medicineId: 'm',
      scheduledTime: when,
      status: status,
      createdAt: when,
      updatedAt: when,
    );

void main() {
  // 1:08 in the morning — the case that prompted this: a midday dose from the
  // day before is still sitting unanswered.
  final now = DateTime(2026, 9, 7, 1, 8);

  group('a dose is unresolved when', () {
    test('its time went by longer ago than the grace period', () {
      expect(isDoseUnresolved(doseAt(DateTime(2026, 9, 6, 14, 0)), now), isTrue);
    });

    test('it is from days back and was never answered', () {
      expect(isDoseUnresolved(doseAt(DateTime(2026, 9, 3, 8, 0)), now), isTrue);
    });
  });

  group('a dose is left alone when', () {
    test('it is still to come', () {
      expect(
        isDoseUnresolved(doseAt(DateTime(2026, 9, 7, 8, 0)), now),
        isFalse,
      );
    });

    test('it only just passed — taking it late is still normal', () {
      // 08 minutes ago, well inside the hour of grace.
      expect(
        isDoseUnresolved(doseAt(DateTime(2026, 9, 7, 1, 0)), now),
        isFalse,
      );
    });

    test('it sits exactly on the edge of the grace period', () {
      expect(
        isDoseUnresolved(doseAt(DateTime(2026, 9, 7, 0, 8)), now),
        isFalse,
      );
      // One minute past the edge, and it counts.
      expect(
        isDoseUnresolved(doseAt(DateTime(2026, 9, 7, 0, 7)), now),
        isTrue,
      );
    });

    test('it has already been answered', () {
      final past = DateTime(2026, 9, 6, 14, 0);
      for (final status in [
        DoseStatus.taken,
        DoseStatus.skipped,
        DoseStatus.missed,
      ]) {
        expect(
          isDoseUnresolved(doseAt(past, status: status), now),
          isFalse,
          reason: '$status should not be asked about again',
        );
      }
    });
  });

  test('the grace period can be widened', () {
    final dose = doseAt(DateTime(2026, 9, 6, 23, 0)); // 2h 8m ago
    expect(isDoseUnresolved(dose, now), isTrue);
    expect(
      isDoseUnresolved(dose, now, grace: const Duration(hours: 3)),
      isFalse,
    );
  });
}
