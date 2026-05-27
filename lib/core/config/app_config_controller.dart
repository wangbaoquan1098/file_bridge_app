import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../storage/config_storage.dart';

final appConfigControllerProvider =
    StateNotifierProvider<AppConfigController, AsyncValue<AppConfig?>>((ref) {
      return AppConfigController(ref.watch(configStorageProvider));
    });

class AppConfigController extends StateNotifier<AsyncValue<AppConfig?>> {
  AppConfigController(this._storage) : super(const AsyncValue.loading()) {
    state = AsyncValue.data(_storage.load());
  }

  final ConfigStorage _storage;

  Future<void> save(AppConfig config) async {
    if (!config.isComplete) {
      throw ArgumentError('请填写服务器地址、访问密钥和设备名称');
    }

    final normalized = config.copyWith(
      serverUrl: normalizeServerUrl(config.serverUrl),
      token: config.token.trim(),
      deviceName: config.deviceName.trim(),
    );

    await _storage.save(normalized);
    state = AsyncValue.data(normalized);
  }

  Future<void> clear() async {
    await _storage.clear();
    state = const AsyncValue.data(null);
  }
}

String normalizeServerUrl(String value) {
  var trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
  trimmed = hasScheme ? trimmed : 'http://$trimmed';

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    return uri.origin;
  }

  return trimmed.replaceAll(RegExp(r'/+$'), '');
}

String defaultDeviceName() {
  final hostname = Platform.localHostname.trim();
  if (hostname.isNotEmpty && hostname != 'localhost') {
    return hostname;
  }

  if (Platform.isIOS) {
    return 'iPhone';
  }
  if (Platform.isAndroid) {
    return 'Android';
  }
  if (Platform.isMacOS) {
    return 'Mac';
  }

  return 'My Device';
}
