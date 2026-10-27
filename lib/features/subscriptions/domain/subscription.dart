import 'package:equatable/equatable.dart';

/// How often a subscription renews. Stored by index — append only.
enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  halfYearly,
  yearly;

  /// Months per cycle; weekly is handled in days.
  int get months => switch (this) {
    BillingCycle.weekly => 0,
    BillingCycle.monthly => 1,
    BillingCycle.quarterly => 3,
    BillingCycle.halfYearly => 6,
    BillingCycle.yearly => 12,
  };

  /// What one cycle costs per month, for comparing and totalling.
  double monthlyShare(double amount) => switch (this) {
    BillingCycle.weekly => amount * 52 / 12,
    _ => amount / months,
  };
}

/// What a subscription is for. Stored by index — append only.
enum SubscriptionCategory {
  streaming,
  music,
  cloud,
  software,
  internet,
  education,
  fitness,
  news,
  gaming,
  other,
}

/// Where a renewal stands, for colour and grouping.
enum RenewalStatus { overdue, dueSoon, upcoming, cancelled }

/// Something paid for on a schedule — Netflix, the internet bill, iCloud.
///
/// [nextRenewal] is the date the next payment is due. Marking it paid moves
/// it one cycle on (see [afterPayment]). [billingDay] remembers the day of
/// the month it started on, so a subscription begun on the 31st comes back
/// to the 31st after passing through a shorter month.
class Subscription extends Equatable {
  final String id;
  final String name;
  final double amount;

  /// ISO code: BDT, USD, EUR, INR, GBP.
  final String currency;
  final BillingCycle cycle;
  final DateTime nextRenewal;
  final int billingDay;

  /// Days before [nextRenewal] to send a reminder; 0 means on the day only.
  final int remindDaysBefore;
  final SubscriptionCategory category;

  /// A free trial: the reminder is the chance to cancel before paying.
  final bool isTrial;

  /// False once cancelled; kept for the record but not counted or reminded.
  final bool isActive;
  final String? note;
  final DateTime? lastPaidAt;

  /// What the last renewal cost in taka, for subscriptions billed in
  /// another currency: the card statement amount, remembered for next time.
  final double? lastPaidLocal;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    this.currency = 'BDT',
    this.cycle = BillingCycle.monthly,
    required this.nextRenewal,
    int? billingDay,
    this.remindDaysBefore = 3,
    this.category = SubscriptionCategory.other,
    this.isTrial = false,
    this.isActive = true,
    this.note,
    this.lastPaidAt,
    this.lastPaidLocal,
    required this.createdAt,
  }) : billingDay = billingDay ?? 0;

  /// The day of the month renewals land on.
  int get anchorDay => billingDay > 0 ? billingDay : nextRenewal.day;

  bool get isLocalCurrency => currency == 'BDT';

  double get monthlyCost => cycle.monthlyShare(amount);

  /// The monthly cost in taka: the amount itself for taka, else scaled by
  /// what the last renewal actually cost. Null when that is not known yet.
  double? get monthlyCostLocal {
    if (isLocalCurrency) return monthlyCost;
    final paid = lastPaidLocal;
    if (paid == null || amount <= 0) return null;
    return cycle.monthlyShare(paid);
  }

  /// The renewal after [from], keeping to [anchorDay].
  static DateTime advance(DateTime from, BillingCycle cycle, int anchorDay) {
    if (cycle == BillingCycle.weekly) {
      return DateTime(from.year, from.month, from.day + 7);
    }
    final firstOfTarget = DateTime(from.year, from.month + cycle.months);
    final lastDay = DateTime(
      firstOfTarget.year,
      firstOfTarget.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfTarget.year,
      firstOfTarget.month,
      anchorDay > lastDay ? lastDay : anchorDay,
    );
  }

  /// The renewal before [nextRenewal] — the start of the current cycle.
  DateTime get previousRenewal {
    if (cycle == BillingCycle.weekly) {
      return DateTime(nextRenewal.year, nextRenewal.month, nextRenewal.day - 7);
    }
    final firstOfTarget = DateTime(
      nextRenewal.year,
      nextRenewal.month - cycle.months,
    );
    final lastDay = DateTime(
      firstOfTarget.year,
      firstOfTarget.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfTarget.year,
      firstOfTarget.month,
      anchorDay > lastDay ? lastDay : anchorDay,
    );
  }

  /// Whole days from [now]'s date to the renewal date. Negative when late.
  int daysUntil(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextRenewal.year, nextRenewal.month, nextRenewal.day);
    return due.difference(today).inDays;
  }

  RenewalStatus statusAt(DateTime now) {
    if (!isActive) return RenewalStatus.cancelled;
    final days = daysUntil(now);
    if (days < 0) return RenewalStatus.overdue;
    final window = remindDaysBefore < 3 ? 3 : remindDaysBefore;
    return days <= window ? RenewalStatus.dueSoon : RenewalStatus.upcoming;
  }

  /// How far through the current cycle [now] is, 0 to 1.
  double progressAt(DateTime now) {
    final start = previousRenewal;
    final total = nextRenewal.difference(start).inMinutes;
    if (total <= 0) return 1;
    final gone = now.difference(start).inMinutes;
    return (gone / total).clamp(0.0, 1.0);
  }

  /// This subscription once the current renewal is paid: due one cycle
  /// later, no longer a trial, with the payment remembered.
  Subscription afterPayment({required DateTime paidAt, double? paidLocal}) {
    return copyWith(
      nextRenewal: advance(nextRenewal, cycle, anchorDay),
      billingDay: anchorDay,
      isTrial: false,
      lastPaidAt: paidAt,
      lastPaidLocal: paidLocal ?? lastPaidLocal,
    );
  }

  Subscription copyWith({
    String? name,
    double? amount,
    String? currency,
    BillingCycle? cycle,
    DateTime? nextRenewal,
    int? billingDay,
    int? remindDaysBefore,
    SubscriptionCategory? category,
    bool? isTrial,
    bool? isActive,
    String? note,
    bool clearNote = false,
    DateTime? lastPaidAt,
    double? lastPaidLocal,
  }) => Subscription(
    id: id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    cycle: cycle ?? this.cycle,
    nextRenewal: nextRenewal ?? this.nextRenewal,
    billingDay: billingDay ?? this.billingDay,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    category: category ?? this.category,
    isTrial: isTrial ?? this.isTrial,
    isActive: isActive ?? this.isActive,
    note: clearNote ? null : (note ?? this.note),
    lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    lastPaidLocal: lastPaidLocal ?? this.lastPaidLocal,
    createdAt: createdAt,
  );

  // ── Storage ─────────────────────────────────────────────────────────────

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'currency': currency,
    'cycle': cycle.index,
    'nextRenewal': nextRenewal.millisecondsSinceEpoch,
    'billingDay': anchorDay,
    'remindDaysBefore': remindDaysBefore,
    'category': category.index,
    'isTrial': isTrial ? 1 : 0,
    'isActive': isActive ? 1 : 0,
    'note': note,
    'lastPaidAt': lastPaidAt?.millisecondsSinceEpoch,
    'lastPaidLocal': lastPaidLocal,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Subscription.fromMap(Map<String, Object?> m) {
    T at<T extends Enum>(List<T> values, Object? i, T fallback) =>
        i is int && i >= 0 && i < values.length ? values[i] : fallback;
    DateTime? date(Object? v) =>
        v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    return Subscription(
      id: m['id']! as String,
      name: m['name']! as String,
      amount: (m['amount']! as num).toDouble(),
      currency: m['currency'] as String? ?? 'BDT',
      cycle: at(BillingCycle.values, m['cycle'], BillingCycle.monthly),
      nextRenewal: date(m['nextRenewal'])!,
      billingDay: m['billingDay'] as int?,
      remindDaysBefore: m['remindDaysBefore'] as int? ?? 3,
      category: at(
        SubscriptionCategory.values,
        m['category'],
        SubscriptionCategory.other,
      ),
      isTrial: m['isTrial'] == 1,
      isActive: m['isActive'] != 0,
      note: m['note'] as String?,
      lastPaidAt: date(m['lastPaidAt']),
      lastPaidLocal: (m['lastPaidLocal'] as num?)?.toDouble(),
      createdAt: date(m['createdAt'])!,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    currency,
    cycle,
    nextRenewal,
    billingDay,
    remindDaysBefore,
    category,
    isTrial,
    isActive,
    note,
    lastPaidAt,
    lastPaidLocal,
    createdAt,
  ];
}
