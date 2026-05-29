import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/upload_task.dart';
import '../../widgets/empty_state.dart';
import 'upload_controller.dart';

class UploadPage extends ConsumerWidget {
  const UploadPage({super.key, bool? galleryPickerSupportedOverride})
    : _galleryPickerSupportedOverride = galleryPickerSupportedOverride;

  final bool? _galleryPickerSupportedOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(uploadControllerProvider);
    final controller = ref.read(uploadControllerProvider.notifier);
    final uploading = tasks.any(
      (task) => task.status == UploadStatus.uploading,
    );
    final canUpload = tasks.any(
      (task) =>
          task.status == UploadStatus.pending ||
          task.status == UploadStatus.failed,
    );
    final canPickFromGallery =
        _galleryPickerSupportedOverride ?? _canPickFromGallery;

    return Scaffold(
      appBar: AppBar(title: const Text('发送')),
      body: tasks.isEmpty
          ? const EmptyState(
              icon: Icons.upload_file,
              title: '还没有选择文件',
              message: '选择图片、视频或文档后，可以一次上传到中转服务器。',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _UploadTaskTile(task: tasks[index]),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: uploading ? null : controller.pickFiles,
                icon: const Icon(Icons.add),
                label: const Text('选择文件'),
              ),
              if (canPickFromGallery)
                OutlinedButton.icon(
                  onPressed: uploading ? null : controller.pickGalleryMedia,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('从相册选择'),
                ),
              OutlinedButton.icon(
                onPressed: uploading
                    ? null
                    : () => _showTextUploadSheet(context),
                icon: const Icon(Icons.notes_outlined),
                label: const Text('发送文本'),
              ),
              OutlinedButton.icon(
                onPressed: uploading || tasks.isEmpty ? null : controller.clear,
                icon: const Icon(Icons.clear_all),
                label: const Text('清空列表'),
              ),
              FilledButton.icon(
                onPressed: uploading || !canUpload
                    ? null
                    : () async {
                        await controller.uploadAll();
                        if (!context.mounted) {
                          return;
                        }
                        final latest = ref.read(uploadControllerProvider);
                        final failed = latest
                            .where((task) => task.status == UploadStatus.failed)
                            .length;
                        final message = failed == 0
                            ? '上传完成'
                            : '$failed 个文件上传失败';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      },
                icon: uploading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('开始上传'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canPickFromGallery {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> _showTextUploadSheet(BuildContext context) async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _TextUploadSheet(),
    );

    if (uploaded == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文本已上传')));
    }
  }
}

class _TextUploadSheet extends ConsumerStatefulWidget {
  const _TextUploadSheet();

  @override
  ConsumerState<_TextUploadSheet> createState() => _TextUploadSheetState();
}

class _TextUploadSheetState extends ConsumerState<_TextUploadSheet> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          children: [
            AppBar(
              title: const Text('发送文本'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  tooltip: '关闭',
                  onPressed: _sending ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  TextField(
                    controller: _titleController,
                    enabled: !_sending,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '可选，默认使用发送时间',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    enabled: !_sending,
                    keyboardType: TextInputType.multiline,
                    minLines: 14,
                    maxLines: 18,
                    decoration: const InputDecoration(
                      labelText: '文本内容',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_textController.text.characters.length} 字',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sending
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _sending ? null : _sendText,
                        icon: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: const Text('发送'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入要发送的文本')));
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(uploadControllerProvider.notifier)
          .uploadText(text: text, title: _titleController.text);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _UploadTaskTile extends StatelessWidget {
  const _UploadTaskTile({required this.task});

  final UploadTask task;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Text(formatBytes(task.size)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: task.status == UploadStatus.pending ? 0 : task.progress,
            ),
            const SizedBox(height: 8),
            Text(
              _statusText(task),
              style: TextStyle(
                color: task.status == UploadStatus.failed
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(UploadTask task) {
    return switch (task.status) {
      UploadStatus.pending => '等待上传',
      UploadStatus.uploading =>
        '上传中 ${(task.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
      UploadStatus.success => '上传成功',
      UploadStatus.failed => task.errorMessage ?? '上传失败',
    };
  }
}
