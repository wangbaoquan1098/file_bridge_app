import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_providers.dart';
import '../../core/storage/download_location.dart';
import '../../core/utils/formatters.dart';
import '../../models/download_task.dart';
import '../../models/file_item.dart';

final filesControllerProvider =
    StateNotifierProvider.autoDispose<FilesController, FilesState>((ref) {
      return FilesController(ref)..refresh();
    });

class FilesState {
  const FilesState({
    this.files = const AsyncValue.loading(),
    this.downloads = const {},
  });

  final AsyncValue<List<FileItem>> files;
  final Map<String, DownloadTask> downloads;

  FilesState copyWith({
    AsyncValue<List<FileItem>>? files,
    Map<String, DownloadTask>? downloads,
  }) {
    return FilesState(
      files: files ?? this.files,
      downloads: downloads ?? this.downloads,
    );
  }
}

class FilesController extends StateNotifier<FilesState> {
  FilesController(this._ref) : super(const FilesState());

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(files: const AsyncValue.loading());
    try {
      final items = await _ref.read(apiClientProvider).listFiles();
      state = state.copyWith(files: AsyncValue.data(items));
    } on Object catch (error, stackTrace) {
      state = state.copyWith(files: AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> deleteFile(String fileId) async {
    await _ref.read(apiClientProvider).deleteFile(fileId);
    await refresh();
  }

  Future<void> download(FileItem item) async {
    final directoryPath = await DownloadLocation.stagingDirectoryPath();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}-${safeFileName(item.originalName)}';
    final savePath = joinPath(directoryPath, fileName);

    _putDownload(
      item.id,
      DownloadTask(fileId: item.id, fileName: item.originalName),
    );

    try {
      await _ref
          .read(apiClientProvider)
          .downloadFile(
            fileId: item.id,
            savePath: savePath,
            onReceiveProgress: (received, total) {
              if (total <= 0) {
                return;
              }
              _putDownload(
                item.id,
                state.downloads[item.id]!.copyWith(progress: received / total),
              );
            },
          );

      final published = await DownloadLocation.publishDownloadedFile(
        stagingPath: savePath,
        fileName: fileName,
        mimeType: item.mimeType,
      );

      _putDownload(
        item.id,
        state.downloads[item.id]!.copyWith(
          progress: 1,
          status: DownloadStatus.success,
          localPath: published.path,
          openUri: published.openUri,
        ),
      );
      await refresh();
    } on Object catch (error) {
      _putDownload(
        item.id,
        state.downloads[item.id]!.copyWith(
          status: DownloadStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> openDownloaded(String fileId) async {
    final task = state.downloads[fileId];
    final localPath = task?.localPath;
    if (localPath == null) {
      return;
    }

    await DownloadLocation.openDownloadedFile(
      path: localPath,
      openUri: task?.openUri,
    );
  }

  void _putDownload(String fileId, DownloadTask task) {
    state = state.copyWith(downloads: {...state.downloads, fileId: task});
  }
}
