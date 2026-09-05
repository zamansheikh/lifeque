/// Sensible jamaat (congregation) times for a fresh install, before the user
/// has entered their own mosque's schedule.
///
/// Stored as offsets from the waqt rather than fixed clock times, so they
/// keep tracking the waqt as it drifts through the year.
///
/// The values follow common practice in Bangladesh: Maghrib effectively at
/// the waqt, because that window is short, and a gap for the rest to let the
/// congregation gather. They are a starting point, not an authority —
/// every mosque sets its own schedule, which is why the edit sheet flags them
/// as defaults and invites a correction.
class JamaatDefaults {
  JamaatDefaults._();

  /// Minutes after the waqt starts, per prayer.
  ///
  /// Maghrib is zero: its window is short and in practice the congregation
  /// prays essentially at the waqt, so the default matches it exactly. Any
  /// prayer can be set this way — the edit sheet has a "Same as waqt" action.
  static const offsets = <String, int>{
    'Fajr': 20,
    'Dhuhr': 15,
    'Asr': 15,
    'Maghrib': 0,
    'Isha': 15,
  };

  /// Ramadan mode derives Fajr and Maghrib from the waqt itself, so those two
  /// are handled by the caller and this is only consulted for the rest.
  static const ramadanOffsetMinutes = 15;

  /// The default jamaat for [prayer] on the day of [waqt], or null for an
  /// unknown prayer name.
  static DateTime? forPrayer(String prayer, DateTime waqt) {
    final offset = offsets[prayer];
    if (offset == null) return null;
    return waqt.add(Duration(minutes: offset));
  }
}
