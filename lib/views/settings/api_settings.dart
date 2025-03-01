import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:lappy/models/api_config.dart';
import 'package:lappy/models/app_settings.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  late ApiConfigManager _apiConfigManager;
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelNameController;
  late TextEditingController _configNameController;
  ApiProvider _selectedProvider = ApiProvider.openAI;

  @override
  void initState() {
    super.initState();
    _apiConfigManager = AppSettings().apiConfigManager;
    _nameController = TextEditingController();
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController();
    _modelNameController = TextEditingController();
    _configNameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelNameController.dispose();
    _configNameController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    if (_nameController.text.isEmpty ||
        _apiKeyController.text.isEmpty ||
        _baseUrlController.text.isEmpty ||
        _modelNameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('提示'),
          content: const Text('请填写完整的配置信息'),
          actions: [
            Button(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final newConfig = ApiConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      provider: _selectedProvider,
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      modelName: _modelNameController.text,
    );

    _apiConfigManager.addConfig(newConfig);

    _nameController.clear();
    _apiKeyController.clear();
    _baseUrlController.clear();
    _modelNameController.clear();
  }

  void _deleteConfig(String id) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个配置吗？'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('删除'),
            onPressed: () {
              _apiConfigManager.deleteConfig(id);
              Navigator.pop(context);
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
        title: Text('API 配置'),
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧配置列表
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('已保存的配置', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: _apiConfigManager,
                        builder: (context, _) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: _apiConfigManager.configs.length,
                            itemBuilder: (context, index) {
                              final config = _apiConfigManager.configs[index];
                              return Card(
                                child: ListTile(
                                  title: Text(config.name),
                                  subtitle: Text('${config.provider.displayName} - ${config.modelName}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ToggleButton(
                                        checked: config.isDefault,
                                        onChanged: (_) => _apiConfigManager.setDefaultConfig(config.id),
                                        child: const Text('默认'),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(FluentIcons.delete),
                                        onPressed: () => _deleteConfig(config.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 右侧配置编辑
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('新建配置', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'API 供应方',
                        child: ComboBox<ApiProvider>(
                          value: _selectedProvider,
                          items: ApiProvider.values
                              .map((e) => ComboBoxItem<ApiProvider>(
                                    value: e,
                                    child: Text(e.displayName),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedProvider = value;
                                if (value == ApiProvider.openAI) {
                                  _baseUrlController.text = 'https://api.openai.com/v1';
                                } else if (value == ApiProvider.chatGLM) {
                                  _baseUrlController.text = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: '配置名称',
                        child: TextBox(
                          controller: _nameController,
                          placeholder: '请输入配置名称',
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: 'API Key',
                        child: TextBox(
                          controller: _apiKeyController,
                          placeholder: '请输入 API Key',
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: 'API 端点',
                        child: TextBox(
                          controller: _baseUrlController,
                          placeholder: '请输入自定义 API 端点',
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: '模型名称',
                        child: TextBox(
                          controller: _modelNameController,
                          placeholder: '请输入模型名称',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saveConfig,
                        child: const Text('保存配置'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}