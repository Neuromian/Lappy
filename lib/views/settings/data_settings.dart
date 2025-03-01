import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

class DataSettingsPage extends StatefulWidget {
  const DataSettingsPage({super.key});

  @override
  State<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends State<DataSettingsPage> {
  final TextEditingController _cachePathController = TextEditingController();
  bool _autoBackupEnabled = false;
  int _backupInterval = 24; // 默认24小时
  int _maxBackups = 5; // 默认保留5个备份

  @override
  void dispose() {
    _cachePathController.dispose();
    super.dispose();
  }

  void _selectCachePath() {
    // TODO: 实现文件夹选择功能
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('提示'),
        content: const Text('文件夹选择功能将在后续实现'),
        actions: [
          Button(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('确认导出'),
        content: const Text('是否导出所有数据？这可能需要一些时间。'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('导出'),
            onPressed: () {
              // TODO: 实现数据导出功能
              Navigator.pop(context);
              displayInfoBar(
                context,
                duration: const Duration(seconds: 2),
                builder: (context, close) => InfoBar(
                  title: const Text('导出成功'),
                  content: const Text('数据已成功导出到指定位置'),
                  severity: InfoBarSeverity.success,
                  onClose: close,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('警告'),
        content: const Text('确定要清空所有数据吗？此操作不可恢复！'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: ButtonState.all(Colors.red),
            ),
            child: const Text('清空'),
            onPressed: () {
              // TODO: 实现数据清空功能
              Navigator.pop(context);
              displayInfoBar(
                context,
                duration: const Duration(seconds: 2),
                builder: (context, close) => InfoBar(
                  title: const Text('已清空'),
                  content: const Text('所有数据已被清空'),
                  severity: InfoBarSeverity.warning,
                  onClose: close,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('数据管理'),
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('缓存设置', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                InfoLabel(
                  label: '缓存位置',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextBox(
                          controller: _cachePathController,
                          placeholder: '请选择缓存文件夹位置',
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        child: const Text('选择文件夹'),
                        onPressed: _selectCachePath,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ToggleSwitch(
                  checked: _autoBackupEnabled,
                  onChanged: (value) => setState(() => _autoBackupEnabled = value),
                  content: const Text('启用自动备份'),
                ),
                if (_autoBackupEnabled) ...[                  
                  const SizedBox(height: 8),
                  InfoLabel(
                    label: '备份间隔（小时）',
                    child: NumberBox<int>(
                      value: _backupInterval,
                      onChanged: (value) {
                        if (value != null && value > 0) {
                          setState(() => _backupInterval = value);
                        }
                      },
                      min: 1,
                      max: 168,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InfoLabel(
                    label: '最大备份数量',
                    child: NumberBox<int>(
                      value: _maxBackups,
                      onChanged: (value) {
                        if (value != null && value > 0) {
                          setState(() => _maxBackups = value);
                        }
                      },
                      min: 1,
                      max: 50,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('数据操作', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      child: const Text('导出所有数据'),
                      onPressed: _exportData,
                    ),
                    const SizedBox(width: 8),
                    Button(
                      child: const Text('清空所有数据'),
                      onPressed: _clearData,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const InfoBar(
                  title: Text('提示'),
                  content: Text('导出的数据将包含所有配置和聊天记录，可用于备份或迁移'),
                  severity: InfoBarSeverity.info,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}