import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/views/settings/api_settings.dart';
import 'package:lappy/views/settings/shortcut_settings.dart';
import 'package:lappy/views/settings/data_settings.dart';

/// 设置页面
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // 确保设置已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<AppSettings>(context, listen: false);
      if (!settings.initialized) {
        settings.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(FluentIcons.reset),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ContentDialog(
                  title: const Text('重置设置'),
                  content: const Text('确定要重置所有设置吗？这将删除所有API配置、快捷键设置和数据管理设置。'),
                  actions: [
                    Button(
                      child: const Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    FilledButton(
                      child: const Text('确定'),
                      onPressed: () {
                        Provider.of<AppSettings>(context, listen: false).resetAllSettings();
                        Navigator.of(context).pop();
                        displayInfoBar(
                          context,
                          duration: const Duration(seconds: 2),
                          builder: (context, close) => InfoBar(
                            title: const Text('已重置所有设置'),
                            severity: InfoBarSeverity.info,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.compact,
        size: const NavigationPaneSize(
          openMinWidth: 200,
          openMaxWidth: 250,
          compactWidth: 50,
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.code),
            title: const Text('API配置'),
            body: const ApiSettingsPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.keyboard_classic),
            title: const Text('快捷键'),
            body: const ShortcutSettingsPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.database),
            title: const Text('数据管理'),
            body: const DataSettingsPage(),
          ),
        ],
      ),
    );
  }
}