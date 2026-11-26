/// The parent PIN is asked on every app open: on a cold start, and again when
/// the app comes back after being away for [awayLimit] (short trips such as a
/// permission dialog or the notification shade do not count).
class PinRelockPolicy {
  static const Duration awayLimit = Duration(seconds: 15);

  static bool shouldRelock({
    required DateTime? pausedAt,
    required DateTime now,
    required bool pinRequiredAtAll,
  }) {
    if (!pinRequiredAtAll || pausedAt == null) return false;
    return now.difference(pausedAt) >= awayLimit;
  }
}
