import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'country_config.dart';
import 'country_detector.dart';
import 'dialect_pack.dart';

/// Country and dialect for this phone: auto-detected, parent can override.
/// Stored only on the phone.
class RegionalSettings extends ChangeNotifier {
  static final RegionalSettings instance = RegionalSettings._();
  RegionalSettings._();

  static const MethodChannel _ch = MethodChannel('haneen/region');
  static const String _kCountry = 'region_country_override';
  static const String _kDialect = 'region_dialect_override';

  CountryConfig _detected = Countries.egypt;
  String? _countryOverride;
  DialectId? _dialectOverride;

  CountryConfig get country =>
      _countryOverride != null ? Countries.byCode(_countryOverride) : _detected;
  DialectId get dialect {
    final o = _dialectOverride;
    if (o != null && o.available) return o;
    return country.defaultDialect.available
        ? country.defaultDialect
        : DialectId.msaSimple;
  }

  bool get countryIsAuto => _countryOverride == null;
  bool get dialectIsAuto => _dialectOverride == null;
  CountryConfig get detectedCountry => _detected;

  Future<void> load({String? deviceRegionForTest}) async {
    final prefs = await SharedPreferences.getInstance();
    _countryOverride = prefs.getString(_kCountry);
    _dialectOverride = DialectIdInfo.fromKey(prefs.getString(_kDialect));
    String? sim, net;
    if (!kIsWeb && deviceRegionForTest == null) {
      try {
        final r = await _ch.invokeMapMethod<String, String>('countryHints');
        sim = r?['sim'];
        net = r?['network'];
      } catch (_) {}
    }
    String? region = deviceRegionForTest;
    if (region == null && !kIsWeb) {
      try {
        final parts = Platform.localeName.split(RegExp('[_-]'));
        if (parts.length > 1) region = parts.last;
      } catch (_) {}
    }
    await DialectPacks.loadAssets(rootBundle);
    _detected = CountryDetector.pick(
        sim: sim, network: net, deviceRegion: region);
    DialectPacks.setActive(dialect);
  }

  Future<void> setCountry(String? code) async {
    _countryOverride = code;
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_kCountry);
    } else {
      await prefs.setString(_kCountry, code);
    }
    DialectPacks.setActive(dialect);
    notifyListeners();
  }

  Future<void> setDialect(DialectId? d) async {
    _dialectOverride = d;
    final prefs = await SharedPreferences.getInstance();
    if (d == null) {
      await prefs.remove(_kDialect);
    } else {
      await prefs.setString(_kDialect, d.key);
    }
    DialectPacks.setActive(dialect);
    notifyListeners();
  }
}
