import '../../../../core/utils/local_numbers.dart';

/// `৳20,000` / `৳২০,০০০` — whole taka, grouped, in the reader's digits.
/// Budgets are set in whole taka, so paisa never appear here.
String taka(double value) => '৳${N.of(value.round())}';
