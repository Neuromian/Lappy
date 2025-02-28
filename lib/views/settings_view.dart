import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/views/settings/api_settings_view.dart';
import 'package:lappy/views/settings/shortcut_settings_view.dart';
import 'package:lappy/views/settings/data_settings_view.dart';

/// 设置页面
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 确保设置已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<AppSettings>(context, listen: false);
      if (!settings.initialized) {
        settings.init();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'API配置', icon: Icon(Icons.api)),
            Tab(text: '快捷键', icon: Icon(Icons.keyboard)),
            Tab(text: '数据管理', icon: Icon(Icons.storage)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ApiSettingsView(),
          ShortcutSettingsView(),
          DataSettingsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 重置所有设置
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('重置设置'),
              content: const Text('确定要重置所有设置吗？这将删除所有API配置、快捷键设置和数据管理设置。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Provider.of<AppSettings>(context, listen: false).resetAllSettings();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已重置所有设置')),
                    );
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
        tooltip: '重置所有设置',
        child: const Icon(Icons.restore),
      ),
    );
  }
}