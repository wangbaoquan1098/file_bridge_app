import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/formatters.dart';

class DownloadLocation {
  DownloadLocation._();

  static const _channel = MethodChannel('file_bridge/downloads');
  static const folderName = 'FileBridge';

  static Future<String> stagingDirectoryPath() async {
    if (Platform.isAndroid) {
      final path = await _channel.invokeMethod<String>('getStagingDirectory');
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }

    final baseDirectory = Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
    final directory = Directory(joinPath(baseDirectory.path, folderName));
    await directory.create(recursive: true);
    return directory.path;
  }

  static Future<PublishedDownload> publishDownloadedFile({
    required String stagingPath,
    required String fileName,
    required String? mimeType,
  }) async {
    if (!Platform.isAndroid) {
      return PublishedDownload(path: stagingPath);
    }

    final response = await _channel
        .invokeMapMethod<String, Object?>('publishDownload', {
          'sourcePath': stagingPath,
          'fileName': fileName,
          'mimeType': mimeType ?? 'application/octet-stream',
        });

    final publishedPath = response?['path'];
    final openUri = response?['openUri'];

    return PublishedDownload(
      path: publishedPath is String && publishedPath.isNotEmpty
          ? publishedPath
          : stagingPath,
      openUri: openUri is String && openUri.isNotEmpty ? openUri : null,
    );
  }

  static Future<void> openDownloadedFile({
    required String path,
    String? openUri,
  }) async {
    if (Platform.isAndroid && openUri != null && openUri.isNotEmpty) {
      await _channel.invokeMethod<void>('openFile', {'uri': openUri});
      return;
    }

    await OpenFilex.open(path);
  }
}

class PublishedDownload {
  const PublishedDownload({required this.path, this.openUri});

  final String path;
  final String? openUri;
}
