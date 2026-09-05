import 'package:shared_preferences/shared_preferences.dart';

/// Persists the tasbih counter so a round survives leaving the tab.
///
/// The counter runs 0–32 and rolls over on the 33rd tap, advancing the round
/// and stepping to the next dhikr (SubhanAllah → Alhamdulillah → Allahu Akbar).
class TasbihService {
  static const _countKey = 'tasbih_count_v1';
  static const _roundKey = 'tasbih_round_v1';
  static const _dhikrKey = 'tasbih_dhikr_v1';

  /// Taps that complete one round.
  static const perRound = 33;

  static final TasbihService instance = TasbihService._();
  TasbihService._();

  Future<TasbihState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TasbihState(
      count: prefs.getInt(_countKey) ?? 0,
      round: prefs.getInt(_roundKey) ?? 1,
      dhikrIndex: prefs.getInt(_dhikrKey) ?? 0,
    );
  }

  Future<void> save(TasbihState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, state.count);
    await prefs.setInt(_roundKey, state.round);
    await prefs.setInt(_dhikrKey, state.dhikrIndex);
  }
}

class TasbihState {
  final int count;
  final int round;
  final int dhikrIndex;

  const TasbihState({
    required this.count,
    required this.round,
    required this.dhikrIndex,
  });

  /// Advance one bead, rolling into the next round and dhikr on the 33rd.
  TasbihState increment() => count >= TasbihService.perRound - 1
      ? TasbihState(count: 0, round: round + 1, dhikrIndex: dhikrIndex + 1)
      : TasbihState(count: count + 1, round: round, dhikrIndex: dhikrIndex);

  TasbihState get reset => const TasbihState(count: 0, round: 1, dhikrIndex: 0);

  double get progress => count / TasbihService.perRound;
}

/// The three post-prayer adhkar the counter cycles through.
class Dhikr {
  final String arabic;
  final String english;

  const Dhikr(this.arabic, this.english);

  static const all = <Dhikr>[
    Dhikr('سُبْحَانَ الله', 'SubhanAllah — Glory be to Allah'),
    Dhikr('الْحَمْدُ لِلَّه', 'Alhamdulillah — All praise is due to Allah'),
    Dhikr('اللَّهُ أَكْبَر', 'Allahu Akbar — Allah is the Greatest'),
  ];

  static Dhikr at(int index) => all[index % all.length];
}
