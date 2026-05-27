import 'dart:io';

import 'package:flutter/services.dart';

class SystemSettings {
  const SystemSettings._();

  static const _channel = MethodChannel('file_bridge/system_settings');

  static Future<bool> openAppSettings() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('openAppSettings');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
