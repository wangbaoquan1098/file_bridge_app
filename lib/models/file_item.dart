class FileItem {
  const FileItem({
    required this.id,
    required this.originalName,
    required this.size,
    required this.mimeType,
    required this.sourceDevice,
    required this.createdAt,
    required this.downloadedCount,
  });

  final String id;
  final String originalName;
  final int size;
  final String? mimeType;
  final String? sourceDevice;
  final DateTime createdAt;
  final int downloadedCount;

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as String,
      originalName: json['originalName'] as String,
      size: (json['size'] as num).toInt(),
      mimeType: json['mimeType'] as String?,
      sourceDevice: json['sourceDevice'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      downloadedCount: (json['downloadedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
