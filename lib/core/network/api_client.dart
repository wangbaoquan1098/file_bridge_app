import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

import '../../models/app_config.dart';
import '../../models/file_item.dart';

class ApiClient {
  ApiClient(AppConfig config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.serverUrl.replaceAll(RegExp(r'/+$'), ''),
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(minutes: 30),
          headers: {HttpHeaders.authorizationHeader: 'Bearer ${config.token}'},
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('FileBridge API -> ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              'FileBridge API <- ${response.statusCode} '
              '${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            _debugNetworkError(error);
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio _dio;

  Future<void> testConnection() async {
    try {
      final health = await _dio.get<Map<String, dynamic>>('/api/health');
      if (health.data?['ok'] != true) {
        throw const ApiException('服务器不可用');
      }

      await listFiles();
    } on Object catch (error) {
      throw mapApiError(error);
    }
  }

  Future<List<FileItem>> listFiles() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/files');
      final items = response.data?['items'];
      if (items is! List) {
        throw const ApiException('文件列表格式错误');
      }

      return items
          .map((item) => FileItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on Object catch (error) {
      throw mapApiError(error);
    }
  }

  Future<FileItem> uploadFile({
    required String path,
    required String fileName,
    required String sourceDevice,
    required ProgressCallback onSendProgress,
  }) async {
    try {
      final mimeType = lookupMimeType(
        path,
        headerBytes: _readHeaderBytes(path),
      );
      final formData = FormData.fromMap({
        'sourceDevice': sourceDevice,
        'file': await MultipartFile.fromFile(
          path,
          filename: fileName,
          contentType: mimeType == null ? null : DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/files',
        data: formData,
        onSendProgress: onSendProgress,
      );

      return FileItem.fromJson(Map<String, dynamic>.from(response.data ?? {}));
    } on Object catch (error) {
      throw mapApiError(error);
    }
  }

  Future<void> downloadFile({
    required String fileId,
    required String savePath,
    required ProgressCallback onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        '/api/files/$fileId/download',
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } on Object catch (error) {
      throw mapApiError(error);
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _dio.delete<void>('/api/files/$fileId');
    } on Object catch (error) {
      throw mapApiError(error);
    }
  }

  List<int>? _readHeaderBytes(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }

      final length = file.lengthSync();
      final bytesToRead = length > 16 ? 16 : length;
      return file.openSync().readSync(bytesToRead);
    } on Object {
      return null;
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

ApiException mapApiError(Object error) {
  if (error is ApiException) {
    return error;
  }

  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _serverErrorMessage(error.response?.data);

    if (statusCode == 401) {
      return const ApiException('token 错误');
    }
    if (statusCode == 413) {
      return const ApiException('文件过大');
    }
    if (statusCode == 404) {
      return ApiException(serverMessage ?? '文件不存在');
    }
    if (statusCode != null && statusCode >= 400) {
      return ApiException(serverMessage ?? '请求失败');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(_connectionErrorMessage(error));
    }

    if (error.type == DioExceptionType.unknown) {
      return ApiException(_unknownNetworkErrorMessage(error));
    }
  }

  return ApiException(error.toString());
}

String _connectionErrorMessage(DioException error) {
  final message = '${error.error ?? error.message ?? ''}';
  if (message.contains('No route to host') || message.contains('errno = 65')) {
    return 'iOS 未允许 FileBridge 访问网络，请在系统设置中开启无线局域网与蜂窝数据权限';
  }
  if (message.contains('Operation timed out') ||
      message.contains('Connection timed out')) {
    return '连接超时，请确认手机网络可以访问服务器';
  }
  if (message.contains('Connection refused')) {
    return '服务器端口未开放或服务未启动';
  }

  return '服务器不可用，请检查服务器地址和网络';
}

String _unknownNetworkErrorMessage(DioException error) {
  final errorText = '${error.error ?? error.message ?? ''}';
  if (errorText.contains('Unsupported URL') ||
      errorText.contains('No host specified') ||
      errorText.contains('Invalid argument')) {
    return '服务器地址格式不正确，请填写 http://服务器IP:端口';
  }
  if (errorText.contains('App Transport Security')) {
    return 'iOS 阻止了 HTTP 访问，请重新安装最新版 App 或改用 HTTPS';
  }

  return '服务器不可用，请检查服务器地址和网络';
}

String? _serverErrorMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      return message is String ? message : null;
    }
  }

  return null;
}

void _debugNetworkError(DioException error) {
  final responseData = error.response?.data;
  debugPrint(
    'FileBridge API error: type=${error.type}, '
    'uri=${error.requestOptions.uri}, '
    'status=${error.response?.statusCode}, '
    'message=${error.message}, '
    'error=${error.error}, '
    'response=$responseData',
  );
}
