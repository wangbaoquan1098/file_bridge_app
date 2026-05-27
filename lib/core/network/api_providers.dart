import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config_controller.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigControllerProvider).valueOrNull;
  if (config == null) {
    throw const ApiException('请先完成设置');
  }

  return ApiClient(config);
});
