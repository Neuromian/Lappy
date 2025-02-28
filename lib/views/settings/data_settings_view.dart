import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/models/data_config.dart';

/// 数据管理设置视图
class DataSettingsView extends StatefulWidget {
  const DataSettingsView({super.key});

  @override
  State<DataSettingsView> createState() => _DataSettingsViewState();
}

class _DataSettingsViewState extends State<DataSettingsView> {
  bool _isExporting = false;
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        final dataManager = settings.dataManager;
        final config = dataManager.config;

        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('数据管理',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('缓存目录',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(config.cachePath,
                                    style: const TextStyle(
                                        fontFamily: 'monospace')),
                              ),
                              IconButton(
                                icon: const Icon(Icons.folder_open),
                                onPressed: () async {
                                  final path = await FilePicker.platform
                                      .getDirectoryPath();
                                  if (path != null) {
                                    dataManager.updateConfig(
                                        config.copyWith(cachePath: path));
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('自动备份',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('启用自动备份'),
                            value: config.autoBackup,
                            onChanged: (value) {
                              dataManager.updateConfig(
                                  config.copyWith(autoBackup: value));
                            },
                          ),
                          if (config.autoBackup) ...[
                            ListTile(
                              title: const Text('备份间隔（天）'),
                              trailing: DropdownButton<int>(
                                value: config.backupInterval,
                                items: [1, 3, 7, 14, 30]
                                    .map((days) => DropdownMenuItem(
                                          value: days,
                                          child: Text(days.toString()),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    dataManager.updateConfig(
                                        config.copyWith(backupInterval: value));
                                  }
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('最大备份数量'),
                              trailing: DropdownButton<int>(
                                value: config.maxBackupCount,
                                items: [3, 5, 10, 20, 30]
                                    .map((count) => DropdownMenuItem(
                                          value: count,
                                          child: Text(count.toString()),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    dataManager.updateConfig(
                                        config.copyWith(maxBackupCount: value));
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('数据操作',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.backup),
                            title: const Text('导出数据'),
                            subtitle: const Text('将所有数据导出到指定目录'),
                            trailing: _isExporting
                                ? const CircularProgressIndicator()
                                : null,
                            onTap: _isExporting
                                ? null
                                : () async {
                                    setState(() => _isExporting = true);
                                    try {
                                      final path = await FilePicker.platform
                                          .getDirectoryPath();
                                      if (path != null) {
                                        final result = await dataManager.exportAllData(path);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(result == null || result.startsWith('导出数据失败') 
                                                    ? '导出数据失败' 
                                                    : '数据已导出到: $result')),
                                          );
                                        }
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isExporting = false);
                                      }
                                    }
                                  },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_forever),
                            title: const Text('清空数据'),
                            subtitle: const Text('删除所有本地数据（此操作不可恢复）'),
                            trailing: _isClearing
                                ? const CircularProgressIndicator()
                                : null,
                            onTap: _isClearing
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('清空数据'),
                                        content:
                                            const Text('确定要删除所有本地数据吗？此操作不可恢复！'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('确定'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      setState(() => _isClearing = true);
                                      try {
                                        final success = await dataManager.clearCache();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(success ? '数据已清空' : '清空数据失败')),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isClearing = false);
                                        }
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }
}
