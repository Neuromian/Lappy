import 'package:fluent_ui/fluent_ui.dart';
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
      content: TabView(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        tabs: [
          Tab(
            text: const Text('API配置'),
            icon: const Icon(FluentIcons.code),
            body: const ApiSettingsView(),
          ),
          Tab(
            text: const Text('快捷键'),
            icon: const Icon(FluentIcons.keyboard_classic),
            body: const ShortcutSettingsView(),
          ),
          Tab(
            text: const Text('数据管理'),
            icon: Icon(FluentIcons.database),
            body: const DataSettingsView(),
          ),
        ],
        tabWidthBehavior: TabWidthBehavior.equal,
        closeButtonVisibility: CloseButtonVisibilityMode.never,
      ),
    );
  }
}