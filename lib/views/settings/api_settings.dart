import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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
  ApiProvider _selectedProvider = ApiProvider.openAI;
  ApiConfig? _editingConfig;

  @override
  void initState() {
    super.initState();
    _apiConfigManager = AppSettings.to.apiConfigManager;
    _nameController = TextEditingController();
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController();
    _modelNameController = TextEditingController();
    
    // 从本地加载配置
    _apiConfigManager.loadFromPrefs().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _editingConfig = null;
    _nameController.clear();
    _apiKeyController.clear();
    _baseUrlController.clear();
    _modelNameController.clear();
    _selectedProvider = ApiProvider.openAI;
    setState(() {});
  }

  void _loadConfigForEdit(ApiConfig config) {
    _editingConfig = config;
    _nameController.text = config.name;
    _apiKeyController.text = config.apiKey;
    _baseUrlController.text = config.baseUrl;
    _modelNameController.text = config.modelName;
    _selectedProvider = config.provider;
    setState(() {});
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

    final config = ApiConfig(
      id: _editingConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      provider: _selectedProvider,
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      modelName: _modelNameController.text,
      isDefault: _editingConfig?.isDefault ?? false,
    );

    if (_editingConfig != null) {
      _apiConfigManager.updateConfig(config);
    } else {
      _apiConfigManager.addConfig(config);
    }

    _clearForm();
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
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('API配置'),
      ),
      content: Row(
        children: [
          // 左侧配置列表
          Expanded(
            flex: 1,
            child: Card(
              child: Obx(() {
                final configs = _apiConfigManager.configs;
                return ListView.builder(
                  itemCount: configs.length,
                  itemBuilder: (context, index) {
                    final config = configs[index];
                    return ListTile(
                      title: Text(config.name),
                      subtitle: Text(config.provider.displayName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (config.isDefault)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(FluentIcons.check_mark, size: 16),
                            ),
                          IconButton(
                            icon: const Icon(FluentIcons.edit),
                            onPressed: () => _loadConfigForEdit(config),
                          ),
                          IconButton(
                            icon: const Icon(FluentIcons.delete),
                            onPressed: () => _deleteConfig(config.id),
                          ),
                        ],
                      ),
                      onPressed: () {
                        _apiConfigManager.selectConfig(config.id);
                        _loadConfigForEdit(config);
                      },
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(width: 16),
          // 右侧表单
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingConfig == null ? '新建配置' : '编辑配置',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: '配置名称',
                        child: TextBox(
                          controller: _nameController,
                          placeholder: '请输入配置名称',
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: 'API提供商',
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
                                // 如果选择了 ChatGLM，自动填入默认的基础 URL
                                if (value == ApiProvider.chatGLM) {
                                  _baseUrlController.text = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
                                } else if (value == ApiProvider.deepseek) {
                                  _baseUrlController.text = 'https://api.deepseek.com/v1/chat/completions';
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: 'API密钥',
                        child: TextBox(
                          controller: _apiKeyController,
                          placeholder: '请输入API密钥',
                        ),
                      ),
                      const SizedBox(height: 8),
                      InfoLabel(
                        label: '基础URL',
                        child: TextBox(
                          controller: _baseUrlController,
                          placeholder: '请输入基础URL',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_editingConfig != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Button(
                                child: const Text('取消'),
                                onPressed: _clearForm,
                              ),
                            ),
                          FilledButton(
                            child: Text(_editingConfig == null ? '添加' : '保存'),
                            onPressed: _saveConfig,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}