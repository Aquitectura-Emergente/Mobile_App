import 'package:shared_preferences/shared_preferences.dart';

/// Local (device-only) app preferences. Persisted with shared_preferences —
/// the team decided settings do not sync to the backend for now.
class AppSettingsStore {
  static const _kPushAlerts = 'settings.pushAlerts';
  static const _kAutoCalibrate = 'settings.autoCalibrate';
  static const _kCloudSync = 'settings.cloudSync';
  static const _kLanguage = 'settings.language';

  static SharedPreferences? _prefs;

  /// Must be awaited once before runApp (see main.dart).
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool get pushAlerts => _prefs?.getBool(_kPushAlerts) ?? true;
  static set pushAlerts(bool v) => _prefs?.setBool(_kPushAlerts, v);

  static bool get autoCalibrate => _prefs?.getBool(_kAutoCalibrate) ?? true;
  static set autoCalibrate(bool v) => _prefs?.setBool(_kAutoCalibrate, v);

  static bool get cloudSync => _prefs?.getBool(_kCloudSync) ?? false;
  static set cloudSync(bool v) => _prefs?.setBool(_kCloudSync, v);

  /// UI language: 'en' | 'es'.
  static String get language => _prefs?.getString(_kLanguage) ?? 'en';
  static set language(String v) => _prefs?.setString(_kLanguage, v);
}
