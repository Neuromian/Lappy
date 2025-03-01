import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  String selectedProvider = 'OpenAI';
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _configNameController = TextEditingController();
  
  final List<String> providers = ['OpenAI', '自定义'];
  final List<Map<String, dynamic>> savedConfigs = [];

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _configNameController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    if (_configNameController.text.isEmpty ||
        _apiKeyController.text.isEmpty ||
        _endpointController.text.isEmpty) {
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

    setState(() {
      savedConfigs.add({
        'name': _configNameController.text,
        'provider': selectedProvider,
        'apiKey': _apiKeyController.text,
        'endpoint': _endpointController.text,
      });
    });

    _configNameController.clear();
    _apiKeyController.clear();
    _endpointController.clear();
  }

  void _deleteConfig(int index) {
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
              setState(() {
                savedConfigs.removeAt(index);
              });
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('新建配置', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                InfoLabel(
                  label: '配置名称',
                  child: TextBox(
                    controller: _configNameController,
                    placeholder: '请输入配置名称',
                  ),
                ),
                const SizedBox(height: 8),
                InfoLabel(
                  label: 'API 供应方',
                  child: ComboBox<String>(
                    value: selectedProvider,
                    items: providers
                        .map((e) => ComboBoxItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedProvider = value;
                        });
                      }
                    },
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
                    controller: _endpointController,
                    placeholder: selectedProvider == 'OpenAI'
                        ? 'https://api.openai.com/v1'
                        : '请输入自定义 API 端点',
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
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('已保存的配置', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ...savedConfigs.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          child: ListTile(
                            title: Text(entry.value['name']),
                            subtitle: Text(entry.value['provider']),
                            trailing: IconButton(
                              icon: const Icon(FluentIcons.delete),
                              onPressed: () => _deleteConfig(entry.key),
                            ),
                          ),
                        ),
                      ),
                    ),
                if (savedConfigs.isEmpty)
                  const Center(
                    child: Text('暂无保存的配置'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}