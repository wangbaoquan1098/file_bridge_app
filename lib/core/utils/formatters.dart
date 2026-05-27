import 'package:intl/intl.dart';

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex += 1;
  }

  if (unitIndex == 0) {
    return '${size.toStringAsFixed(0)} ${units[unitIndex]}';
  }

  return '${size.toStringAsFixed(size >= 10 ? 1 : 2)} ${units[unitIndex]}';
}

String formatDateTime(DateTime value) {
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}

String safeFileName(String fileName) {
  final cleaned = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return cleaned.isEmpty ? 'file' : cleaned;
}

String joinPath(String directory, String fileName) {
  final separator = directory.contains(r'\') ? r'\' : '/';
  if (directory.endsWith(separator)) {
    return '$directory$fileName';
  }
  return '$directory$separator$fileName';
}
