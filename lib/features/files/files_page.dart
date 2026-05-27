import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/download_task.dart';
import '../../models/file_item.dart';
import '../../widgets/empty_state.dart';
import 'files_controller.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filesControllerProvider);
    final controller = ref.read(filesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('接收'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: state.files.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              EmptyState(
                icon: Icons.cloud_off_outlined,
                title: '无法获取文件列表',
                message: error.toString(),
              ),
            ],
          ),
          data: (files) {
            if (files.isEmpty) {
              return const CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.folder_open,
                      title: '暂无文件',
                      message: '其他设备上传后会出现在这里。',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: files.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = files[index];
                return _FileTile(
                  item: item,
                  downloadTask: state.downloads[item.id],
                  onDownload: () async {
                    await controller.download(item);
                    if (!context.mounted) {
                      return;
                    }
                    final task = ref
                        .read(filesControllerProvider)
                        .downloads[item.id];
                    final message = task?.status == DownloadStatus.success
                        ? '下载完成'
                        : task?.errorMessage ?? '下载失败';
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  },
                  onOpen: () => controller.openDownloaded(item.id),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('删除文件'),
                        content: Text('确定删除 ${item.originalName} 吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) {
                      return;
                    }

                    try {
                      await controller.deleteFile(item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('已删除')));
                      }
                    } on Object catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.item,
    required this.downloadTask,
    required this.onDownload,
    required this.onOpen,
    required this.onDelete,
  });

  final FileItem item;
  final DownloadTask? downloadTask;
  final VoidCallback onDownload;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final downloading = downloadTask?.status == DownloadStatus.downloading;
    final downloaded = downloadTask?.status == DownloadStatus.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insert_drive_file_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.originalName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          formatBytes(item.size),
                          item.mimeType ?? 'application/octet-stream',
                          item.sourceDevice ?? '未知设备',
                        ].join(' · '),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDateTime(item.createdAt)} · 下载 ${item.downloadedCount} 次',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (downloadTask != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: downloadTask!.status == DownloadStatus.failed
                    ? 0
                    : downloadTask!.progress.clamp(0, 1),
              ),
              const SizedBox(height: 8),
              Text(
                _downloadText(downloadTask!),
                style: TextStyle(
                  color: downloadTask!.status == DownloadStatus.failed
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: downloading ? null : onDownload,
                  icon: downloading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('下载'),
                ),
                OutlinedButton.icon(
                  onPressed: downloaded ? onOpen : null,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('打开文件'),
                ),
                OutlinedButton.icon(
                  onPressed: downloading ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _downloadText(DownloadTask task) {
    return switch (task.status) {
      DownloadStatus.downloading =>
        '下载中 ${(task.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
      DownloadStatus.success => '下载成功：${task.localPath}',
      DownloadStatus.failed => task.errorMessage ?? '下载失败',
    };
  }
}
