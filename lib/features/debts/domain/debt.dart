import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Money handed back against a debt.
class DebtPayment extends Equatable {
  final double amount;
  final DateTime at;
  const DebtPayment(this.amount, this.at);

  Map<String, Object> toJson() => {'a': amount, 't': at.millisecondsSinceEpoch};
  static DebtPayment? fromJson(Object? j) {
    if (j is! Map) return null;
    final a = j['a'], t = j['t'];
    if (a is! num || t is! int) return null;
    return DebtPayment(a.toDouble(), DateTime.fromMillisecondsSinceEpoch(t));
  }

  @override
  List<Object?> get props => [amount, at];
}

enum DebtStatus { overdue, dueSoon, open, settled }

/// Money lent or borrowed: who, how much, by when, and what has come back.
class Debt extends Equatable {
  final String id;
  final String person;
  final double amount;

  /// True: lent — they owe me (পাবো). False: borrowed — I owe them (দেবো).
  final bool theyOweMe;
  final DateTime date;
  final DateTime? dueDate;
  final String? note;
  final List<DebtPayment> payments;

  /// Set when written off as settled, even if not every taka came back.
  final DateTime? settledAt;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.person,
    required this.amount,
    this.theyOweMe = true,
    required this.date,
    this.dueDate,
    this.note,
    this.payments = const [],
    this.settledAt,
    required this.createdAt,
  });

  double get paid => payments.fold(0, (s, p) => s + p.amount);
  double get remaining => (amount - paid) < 0.005 ? 0 : amount - paid;
  bool get isSettled => settledAt != null || remaining == 0;
  double get progress => amount <= 0 ? 1 : (paid / amount).clamp(0.0, 1.0);

  int? daysUntilDue(DateTime now) {
    final due = dueDate;
    if (due == null) return null;
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  DebtStatus statusAt(DateTime now) {
    if (isSettled) return DebtStatus.settled;
    final days = daysUntilDue(now);
    if (days == null) return DebtStatus.open;
    if (days < 0) return DebtStatus.overdue;
    return days <= 3 ? DebtStatus.dueSoon : DebtStatus.open;
  }

  /// [amount] paid back at [at]. Paying the rest settles it.
  Debt withPayment(double amount, DateTime at) {
    final next = copyWith(payments: [...payments, DebtPayment(amount, at)]);
    return next.remaining == 0 ? next.copyWith(settledAt: at) : next;
  }

  Debt copyWith({
    String? person,
    double? amount,
    bool? theyOweMe,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
    bool clearNote = false,
    List<DebtPayment>? payments,
    DateTime? settledAt,
    bool clearSettled = false,
  }) => Debt(
    id: id,
    person: person ?? this.person,
    amount: amount ?? this.amount,
    theyOweMe: theyOweMe ?? this.theyOweMe,
    date: date ?? this.date,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    note: clearNote ? null : (note ?? this.note),
    payments: payments ?? this.payments,
    settledAt: clearSettled ? null : (settledAt ?? this.settledAt),
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'person': person,
    'amount': amount,
    'theyOweMe': theyOweMe ? 1 : 0,
    'date': date.millisecondsSinceEpoch,
    'dueDate': dueDate?.millisecondsSinceEpoch,
    'note': note,
    'payments': jsonEncode([for (final p in payments) p.toJson()]),
    'settledAt': settledAt?.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Debt.fromMap(Map<String, Object?> m) {
    DateTime? date(Object? v) =>
        v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    var payments = const <DebtPayment>[];
    try {
      payments = [
        for (final j in jsonDecode(m['payments'] as String? ?? '[]') as List)
          ?DebtPayment.fromJson(j),
      ];
    } catch (_) {}
    return Debt(
      id: m['id']! as String,
      person: m['person']! as String,
      amount: (m['amount']! as num).toDouble(),
      theyOweMe: m['theyOweMe'] != 0,
      date: date(m['date'])!,
      dueDate: date(m['dueDate']),
      note: m['note'] as String?,
      payments: payments,
      settledAt: date(m['settledAt']),
      createdAt: date(m['createdAt'])!,
    );
  }

  @override
  List<Object?> get props => [
    id,
    person,
    amount,
    theyOweMe,
    date,
    dueDate,
    note,
    payments,
    settledAt,
    createdAt,
  ];
}
