import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/config_storage.dart';

final darkModeControllerProvider =
    StateNotifierProvider<DarkModeController, bool>((ref) {
      return DarkModeController(ref.watch(sharedPreferencesProvider));
    });

class DarkModeController extends StateNotifier<bool> {
  DarkModeController(this._preferences)
    : super(_preferences.getBool(_darkModeKey) ?? false);

  static const _darkModeKey = 'darkModeEnabled';

  final SharedPreferences _preferences;

  Future<void> setEnabled(bool enabled) async {
    await _preferences.setBool(_darkModeKey, enabled);
    state = enabled;
  }
}
