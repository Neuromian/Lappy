import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/models/api_config.dart';
import 'package:uuid/uuid.dart';

/// API设置视图
class ApiSettingsView extends StatefulWidget {
  const ApiSettingsView({super.key});

  @override
  State<ApiSettingsView> createState() => _ApiSettingsViewState();
}

class _ApiSettingsViewState extends State<ApiSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelNameController = TextEditingController();
  ApiProvider _selectedProvider = ApiProvider.openAI;

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        final apiManager = settings.apiConfigManager;
        final configs = apiManager.configs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('API配置列表',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('添加配置'),
                    onPressed: () {
                      // 显示添加API配置的对话框
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('添加API配置'),
                          content: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                        labelText: '配置名称'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入配置名称';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<ApiProvider>(
                                    value: _selectedProvider,
                                    decoration: const InputDecoration(
                                        labelText: 'API供应商'),
                                    items: ApiProvider.values
                                        .map((provider) => DropdownMenuItem(
                                              value: provider,
                                              child: Text(provider.displayName),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedProvider = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _apiKeyController,
                                    decoration: const InputDecoration(
                                        labelText: 'API密钥'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入API密钥';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _baseUrlController,
                                    decoration: const InputDecoration(
                                        labelText: '基础URL'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入基础URL';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _modelNameController,
                                    decoration: const InputDecoration(
                                        labelText: '模型名称'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入模型名称';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // 创建新的API配置
                                  final newConfig = ApiConfig(
                                    id: const Uuid().v4(),
                                    name: _nameController.text,
                                    provider: _selectedProvider,
                                    apiKey: _apiKeyController.text,
                                    baseUrl: _baseUrlController.text,
                                    modelName: _modelNameController.text,
                                  );

                                  // 添加配置
                                  apiManager.addConfig(newConfig);

                                  // 清空表单
                                  _nameController.clear();
                                  _apiKeyController.clear();
                                  _baseUrlController.clear();
                                  _modelNameController.clear();
                                  _selectedProvider = ApiProvider.openAI;

                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: configs.isEmpty
                    ? const Center(child: Text('暂无API配置，请点击"添加配置"按钮添加'))
                    : ListView.builder(
                        itemCount: configs.length,
                        itemBuilder: (context, index) {
                          final config = configs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                config.isDefault
                                    ? Icons.star
                                    : Icons.star_border,
                                color: config.isDefault
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              title: Text(config.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('供应商: ${config.provider.displayName}'),
                                  Text('模型: ${config.modelName}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: 实现编辑功能
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('删除配置'),
                                          content:
                                              Text('确定要删除配置"${config.name}"吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                apiManager
                                                    .deleteConfig(config.id);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('确定'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                apiManager.setDefaultConfig(config.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
