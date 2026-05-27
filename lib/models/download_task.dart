enum DownloadStatus { downloading, success, failed }

class DownloadTask {
  const DownloadTask({
    required this.fileId,
    required this.fileName,
    this.progress = 0,
    this.status = DownloadStatus.downloading,
    this.localPath,
    this.openUri,
    this.errorMessage,
  });

  final String fileId;
  final String fileName;
  final double progress;
  final DownloadStatus status;
  final String? localPath;
  final String? openUri;
  final String? errorMessage;

  DownloadTask copyWith({
    double? progress,
    DownloadStatus? status,
    String? localPath,
    String? openUri,
    String? errorMessage,
  }) {
    return DownloadTask(
      fileId: fileId,
      fileName: fileName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      openUri: openUri ?? this.openUri,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
