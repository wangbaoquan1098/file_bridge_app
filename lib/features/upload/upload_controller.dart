import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config_controller.dart';
import '../../core/network/api_providers.dart';
import '../../core/utils/formatters.dart';
import '../../models/upload_task.dart';

final uploadControllerProvider =
    StateNotifierProvider<UploadController, List<UploadTask>>((ref) {
      return UploadController(ref);
    });

class UploadController extends StateNotifier<List<UploadTask>> {
  UploadController(this._ref) : super(const []);

  final Ref _ref;

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null) {
      return;
    }

    final tasks = result.files
        .where((file) => file.path != null)
        .map(
          (file) => UploadTask(
            id: '${file.path}-${DateTime.now().microsecondsSinceEpoch}',
            localPath: file.path!,
            fileName: file.name,
            size: file.size,
          ),
        )
        .toList();

    state = [...state, ...tasks];
  }

  void clear() {
    state = const [];
  }

  Future<void> uploadText({required String text, String? title}) async {
    final trimmedText = text.trimRight();
    if (trimmedText.trim().isEmpty) {
      throw Exception('请输入要发送的文本');
    }

    final config = _ref.read(appConfigControllerProvider).valueOrNull;
    if (config == null) {
      throw Exception('请先完成设置');
    }

    final fileName = _textFileName(title);
    final directory = await getTemporaryDirectory();
    final file = File(
      joinPath(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}-$fileName',
      ),
    );
    await file.writeAsString(trimmedText);

    final task = UploadTask(
      id: '${file.path}-${DateTime.now().microsecondsSinceEpoch}',
      localPath: file.path,
      fileName: fileName,
      size: await file.length(),
      status: UploadStatus.uploading,
    );
    state = [...state, task];

    try {
      await _ref
          .read(apiClientProvider)
          .uploadFile(
            path: task.localPath,
            fileName: task.fileName,
            sourceDevice: config.deviceName,
            onSendProgress: (sent, total) {
              if (total <= 0) {
                return;
              }
              _replaceTask(
                task.id,
                task.copyWith(
                  status: UploadStatus.uploading,
                  progress: sent / total,
                ),
              );
            },
          );

      _replaceTask(
        task.id,
        task.copyWith(status: UploadStatus.success, progress: 1),
      );
    } on Object catch (error) {
      _replaceTask(
        task.id,
        task.copyWith(
          status: UploadStatus.failed,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> uploadAll() async {
    final config = _ref.read(appConfigControllerProvider).valueOrNull;
    if (config == null) {
      throw Exception('请先完成设置');
    }

    final apiClient = _ref.read(apiClientProvider);

    for (final task in state) {
      if (task.status == UploadStatus.success ||
          task.status == UploadStatus.uploading) {
        continue;
      }

      _replaceTask(
        task.id,
        task.copyWith(
          status: UploadStatus.uploading,
          progress: 0,
          errorMessage: null,
        ),
      );

      try {
        await apiClient.uploadFile(
          path: task.localPath,
          fileName: safeFileName(task.fileName),
          sourceDevice: config.deviceName,
          onSendProgress: (sent, total) {
            if (total <= 0) {
              return;
            }
            _replaceTask(
              task.id,
              task.copyWith(
                status: UploadStatus.uploading,
                progress: sent / total,
              ),
            );
          },
        );

        _replaceTask(
          task.id,
          task.copyWith(status: UploadStatus.success, progress: 1),
        );
      } on Object catch (error) {
        _replaceTask(
          task.id,
          task.copyWith(
            status: UploadStatus.failed,
            errorMessage: error.toString(),
          ),
        );
      }
    }
  }

  void _replaceTask(String id, UploadTask nextTask) {
    state = [
      for (final task in state)
        if (task.id == id) nextTask else task,
    ];
  }

  String _textFileName(String? title) {
    final trimmedTitle = title?.trim();
    final baseName = trimmedTitle == null || trimmedTitle.isEmpty
        ? '文本-${_timestamp()}'
        : trimmedTitle;
    final safeName = safeFileName(baseName);
    return safeName.toLowerCase().endsWith('.txt') ? safeName : '$safeName.txt';
  }

  String _timestamp() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return [
      now.year.toString(),
      twoDigits(now.month),
      twoDigits(now.day),
      '-',
      twoDigits(now.hour),
      twoDigits(now.minute),
      twoDigits(now.second),
    ].join();
  }
}
