import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/system_settings.dart';
import '../../models/app_config.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({
    super.key,
    this.isInitialSetup = false,
    this.initialError,
  });

  final bool isInitialSetup;
  final String? initialError;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _serverUrlController;
  late final TextEditingController _tokenController;
  late final TextEditingController _deviceNameController;

  bool _testing = false;
  bool _saving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigControllerProvider).valueOrNull;
    _serverUrlController = TextEditingController(text: config?.serverUrl ?? '');
    _tokenController = TextEditingController(text: config?.token ?? '');
    _deviceNameController = TextEditingController(
      text: config?.deviceName ?? defaultDeviceName(),
    );
    _statusMessage = widget.initialError;
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _tokenController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigControllerProvider).valueOrNull;
    final title = widget.isInitialSetup ? '设置 FileBridge' : '设置';

    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _serverUrlController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'http://39.101.139.208:8787',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: '访问密钥',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: '设备名称',
                  prefixIcon: Icon(Icons.devices_outlined),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: const Text('测试连接'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('保存'),
                  ),
                  OutlinedButton.icon(
                    onPressed: config == null ? null : _clearConfig,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('清除配置'),
                  ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusMessage!),
                        if (_shouldShowOpenSettings(_statusMessage!)) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _openAppSettings,
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('打开系统设置'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppConfig _readConfig() {
    return AppConfig(
      serverUrl: normalizeServerUrl(_serverUrlController.text),
      token: _tokenController.text.trim(),
      deviceName: _deviceNameController.text.trim(),
    );
  }

  Future<void> _testConnection() async {
    final config = _readConfig();
    if (!config.isComplete) {
      _setStatus('请填写服务器地址、访问密钥和设备名称');
      return;
    }

    setState(() => _testing = true);
    try {
      await ApiClient(config).testConnection();
      _setStatus('连接成功');
      if (widget.isInitialSetup) {
        await ref.read(appConfigControllerProvider.notifier).save(config);
      }
    } on Object catch (error) {
      _setStatus(error.toString());
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _save() async {
    final config = _readConfig();
    if (!config.isComplete) {
      _setStatus('请填写服务器地址、访问密钥和设备名称');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(appConfigControllerProvider.notifier).save(config);
      _setStatus('配置已保存');
    } on Object catch (error) {
      _setStatus(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _clearConfig() async {
    await ref.read(appConfigControllerProvider.notifier).clear();
    _setStatus('配置已清除');
  }

  void _setStatus(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _statusMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _shouldShowOpenSettings(String message) {
    return message.contains('系统设置') || message.contains('网络权限');
  }

  Future<void> _openAppSettings() async {
    final opened = await SystemSettings.openAppSettings();
    if (!opened) {
      _setStatus('请手动打开系统设置，找到 FileBridge 后开启网络权限');
    }
  }
}
