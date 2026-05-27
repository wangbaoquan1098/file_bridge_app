enum UploadStatus { pending, uploading, success, failed }

class UploadTask {
  const UploadTask({
    required this.id,
    required this.localPath,
    required this.fileName,
    required this.size,
    this.progress = 0,
    this.status = UploadStatus.pending,
    this.errorMessage,
  });

  final String id;
  final String localPath;
  final String fileName;
  final int size;
  final double progress;
  final UploadStatus status;
  final String? errorMessage;

  UploadTask copyWith({
    double? progress,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return UploadTask(
      id: id,
      localPath: localPath,
      fileName: fileName,
      size: size,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
