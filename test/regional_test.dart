import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/core/regional/country_config.dart';
import 'package:haneen_kids_vod/core/regional/country_detector.dart';
import 'package:haneen_kids_vod/core/regional/dialect_pack.dart';
import 'package:haneen_kids_vod/core/regional/regional_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('country detection order: SIM, device region, network, Play', () {
    expect(CountryDetector.pick(sim: 'sa', deviceRegion: 'EG').code, 'SA');
    expect(CountryDetector.pick(sim: '', deviceRegion: 'KW').code, 'KW');
    expect(CountryDetector.pick(network: 'ae').code, 'AE');
    expect(CountryDetector.pick(deviceRegion: 'FR').code, 'XX');
    expect(CountryDetector.pick().code, 'EG');
  });
  test('every country has a default dialect that is available', () {
    for (final c in Countries.all) {
      expect(c.defaultDialect.available, isTrue, reason: c.code);
      expect(c.currency.length, 3);
    }
  });
  test('dialect pack falls back to Egyptian then to the default', () {
    expect(DialectPacks.t('path.badge', 'x', dialect: DialectId.msaSimple),
        'اضغط هنا، مخصص لك');
    expect(DialectPacks.t('path.badge', 'x', dialect: DialectId.gulf),
        'اضغط هنا، مخصص ليك');
    expect(DialectPacks.t('no.such', 'default'), 'default');
  });
  test('parent override beats detection and persists; gulf is not offered', () async {
    SharedPreferences.setMockInitialValues({});
    final s = RegionalSettings.instance;
    await s.load(deviceRegionForTest: 'SA');
    expect(s.country.code, 'SA');
    expect(s.dialect, DialectId.msaSimple);
    await s.setCountry('EG');
    expect(s.country.code, 'EG');
    expect(s.dialect, DialectId.egyptian);
    await s.setDialect(DialectId.gulf);
    expect(s.dialect, DialectId.egyptian); // gulf not available yet
    await s.setDialect(DialectId.msaSimple);
    await s.load(deviceRegionForTest: 'KW');
    expect(s.country.code, 'EG');
    expect(s.dialect, DialectId.msaSimple);
    await s.setCountry(null);
    await s.setDialect(null);
    expect(s.country.code, 'KW');
  });
}
