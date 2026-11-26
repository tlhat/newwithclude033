import 'country_config.dart';

/// Picks the country from hints that stay on the phone: SIM, network and the
/// device language region. No GPS, nothing is sent anywhere.
class CountryDetector {
  static CountryConfig pick({
    String? sim,
    String? network,
    String? deviceRegion,
    String? playCountry,
  }) {
    for (final String? hint in [sim, deviceRegion, network, playCountry]) {
      final String c = (hint ?? '').trim().toUpperCase();
      if (c.length != 2) continue;
      for (final k in Countries.all) {
        if (k.code == c) return k;
      }
    }
    // Known hint for another country: keep "other". No hint at all: Egypt,
    // the app's home market.
    final bool anyHint = [sim, network, deviceRegion, playCountry]
        .any((h) => (h ?? '').trim().length == 2);
    return anyHint ? Countries.other : Countries.egypt;
  }
}
