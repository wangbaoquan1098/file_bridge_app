import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_config.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final configStorageProvider = Provider<ConfigStorage>((ref) {
  return ConfigStorage(ref.watch(sharedPreferencesProvider));
});

class ConfigStorage {
  ConfigStorage(this._preferences);

  static const _serverUrlKey = 'serverUrl';
  static const _tokenKey = 'token';
  static const _deviceNameKey = 'deviceName';

  final SharedPreferences _preferences;

  AppConfig? load() {
    final serverUrl = _preferences.getString(_serverUrlKey);
    final token = _preferences.getString(_tokenKey);
    final deviceName = _preferences.getString(_deviceNameKey);

    if (serverUrl == null || token == null || deviceName == null) {
      return null;
    }

    final config = AppConfig(
      serverUrl: serverUrl,
      token: token,
      deviceName: deviceName,
    );

    return config.isComplete ? config : null;
  }

  Future<void> save(AppConfig config) async {
    await _preferences.setString(_serverUrlKey, config.serverUrl.trim());
    await _preferences.setString(_tokenKey, config.token.trim());
    await _preferences.setString(_deviceNameKey, config.deviceName.trim());
  }

  Future<void> clear() async {
    await _preferences.remove(_serverUrlKey);
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_deviceNameKey);
  }
}
