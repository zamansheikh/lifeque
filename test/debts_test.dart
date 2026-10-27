import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/debts/data/debt_repository.dart';
import 'package:lifeque/features/debts/domain/debt.dart';
import 'package:lifeque/features/debts/presentation/debt_cubit.dart';
import 'package:lifeque/features/debts/presentation/debts_page.dart';
import 'package:lifeque/injection_container.dart' as di;
import 'package:lifeque/l10n/app_localizations.dart';

class MemoryDebts implements DebtRepository {
  final rows = <String, Debt>{};
  @override
  Future<List<Debt>> all() async => rows.values.toList();
  @override
  Future<Debt?> byId(String id) async => rows[id];
  @override
  Future<void> save(Debt d) async => rows[d.id] = d;
  @override
  Future<void> delete(String id) async => rows.remove(id);
}

class Recorder implements DebtReminders {
  final scheduled = <String>[];
  final cancelled = <String>[];
  @override
  Future<void> schedule(Debt d) async => scheduled.add(d.id);
  @override
  Future<void> cancel(String id) async => cancelled.add(id);
}

Debt debt({
  String id = 'd',
  String person = 'Rahim',
  double amount = 5000,
  bool theyOweMe = true,
  DateTime? due,
}) => Debt(
  id: id,
  person: person,
  amount: amount,
  theyOweMe: theyOweMe,
  date: DateTime(2026, 10, 1),
  dueDate: due,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  group('a debt', () {
    test('partial payments, then the rest settles it', () {
      var d = debt();
      d = d.withPayment(2000, DateTime(2026, 10, 5));
      expect(d.paid, 2000);
      expect(d.remaining, 3000);
      expect(d.progress, closeTo(0.4, 1e-9));
      expect(d.isSettled, isFalse);
      d = d.withPayment(3000, DateTime(2026, 10, 9));
      expect(d.remaining, 0);
      expect(d.isSettled, isTrue);
      expect(d.settledAt, DateTime(2026, 10, 9));
    });

    test('status by due date', () {
      final now = DateTime(2026, 10, 27, 15);
      expect(debt().statusAt(now), DebtStatus.open);
      expect(
        debt(due: DateTime(2026, 10, 20)).statusAt(now),
        DebtStatus.overdue,
      );
      expect(
        debt(due: DateTime(2026, 10, 29)).statusAt(now),
        DebtStatus.dueSoon,
      );
      expect(debt(due: DateTime(2026, 10, 27)).daysUntilDue(now), 0);
    });

    test('survives the database, payments and all', () {
      final d = debt(
        due: DateTime(2026, 11, 1),
      ).withPayment(1500, DateTime(2026, 10, 10)).copyWith(note: 'বাইক ঠিক');
      expect(Debt.fromMap(d.toMap()), d);
    });
  });

  group('the cubit', () {
    test('totals each way; settling stops the reminder', () async {
      final repo = MemoryDebts();
      final rec = Recorder();
      final c = DebtCubit(repo, rec, now: () => DateTime(2026, 10, 27));
      await c.save(debt(id: 'a', amount: 5000));
      await c.save(debt(id: 'b', amount: 1200, theyOweMe: false));
      expect(c.state.toReceive, 5000);
      expect(c.state.toPay, 1200);
      expect(rec.scheduled, ['a', 'b']);

      await c.addPayment(repo.rows['a']!, 5000);
      expect(repo.rows['a']!.isSettled, isTrue);
      expect(rec.cancelled, contains('a'));
      expect(c.state.toReceive, 0);

      await c.reopen(repo.rows['b']!.copyWith(settledAt: DateTime(2026)));
      expect(repo.rows['b']!.isSettled, isFalse);
    });
  });

  testWidgets('the page in Bangla: both totals and the net', (tester) async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'bn';
    addTearDown(() => Intl.defaultLocale = null);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final repo = MemoryDebts();
    await repo.save(debt(id: 'a', amount: 5000));
    await repo.save(
      debt(id: 'b', person: 'করিম', amount: 1200, theyOweMe: false),
    );
    await di.sl.reset();
    di.sl.registerSingleton(DebtCubit(repo, Recorder()));
    addTearDown(di.sl.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: const DebtsPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('৳৫,০০০'), findsWidgets);
    expect(find.text('সব মিলিয়ে আপনি পাবেন ৳৩,৮০০'), findsOneWidget);
    expect(find.byKey(const Key('debt-pay-a')), findsOneWidget);
  });
}
