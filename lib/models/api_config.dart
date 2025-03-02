import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API供应商枚举
enum ApiProvider {
  openAI('OpenAI'),
  anthropic('Anthropic'),
  gemini('Gemini'),
  chatGLM('ChatGLM'),
  custom('自定义');

  final String displayName;
  const ApiProvider(this.displayName);
}

/// API配置模型
class ApiConfig {
  String id;
  String name;
  ApiProvider provider;
  String apiKey;
  String baseUrl;
  String modelName;
  bool isDefault;

  ApiConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiKey,
    required this.baseUrl,
    required this.modelName,
    this.isDefault = false,
  });

  // 从JSON创建ApiConfig
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: ApiProvider.values.firstWhere(
        (e) => e.toString() == 'ApiProvider.${json['provider']}',
        orElse: () => ApiProvider.custom,
      ),
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String,
      modelName: json['modelName'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.toString().split('.').last,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'modelName': modelName,
      'isDefault': isDefault,
    };
  }

  // 创建副本
  ApiConfig copyWith({
    String? id,
    String? name,
    ApiProvider? provider,
    String? apiKey,
    String? baseUrl,
    String? modelName,
    bool? isDefault,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// API配置管理器
class ApiConfigManager extends GetxController {
  final _configs = <ApiConfig>[].obs;
  final _selectedConfig = Rxn<ApiConfig>();

  // 获取所有配置
  List<ApiConfig> get configs => _configs;
  
  // 获取当前选中的配置
  ApiConfig? get selectedConfig => _selectedConfig.value;

  // 从JSON加载配置
  void loadFromJson(List<dynamic> json) {
    _configs.clear();
    for (var item in json) {
      _configs.add(ApiConfig.fromJson(item));
    }
    // 设置默认配置
    final defaultConfig = _configs.firstWhereOrNull((config) => config.isDefault);
    _selectedConfig.value = defaultConfig ?? (_configs.isNotEmpty ? _configs.first : null);
    update();
  }

  // 转换为JSON
  List<Map<String, dynamic>> toJson() {
    return _configs.map((config) => config.toJson()).toList();
  }

  // 添加配置
  void addConfig(ApiConfig config) {
    debugPrint('开始添加配置: ${config.toJson()}');
    debugPrint('当前配置列表: ${_configs.length} 个');
    
    // 如果是第一个配置，设为默认
    if (_configs.isEmpty) {
      config = config.copyWith(isDefault: true);
      debugPrint('首个配置，设置为默认');
    }
    
    // 如果设置为默认，取消其他默认
    if (config.isDefault) {
      debugPrint('新配置设置为默认，重置其他配置的默认状态');
      for (var i = 0; i < _configs.length; i++) {
        _configs[i] = _configs[i].copyWith(isDefault: false);
      }
    }
    
    _configs.add(config);
    debugPrint('配置已添加，当前配置列表: ${_configs.length} 个');
    
    // 如果是默认配置或没有选中配置，选中它
    if (config.isDefault || _selectedConfig.value == null) {
      _selectedConfig.value = config;
      debugPrint('已选中新配置: ${config.name}');
    }
    
    debugPrint('配置添加完成');
    saveToPrefs(); // 保存配置到本地
  }

  // 更新配置
  void updateConfig(ApiConfig config) {
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      // 如果设置为默认，取消其他默认
      if (config.isDefault) {
        for (var i = 0; i < _configs.length; i++) {
          if (_configs[i].id != config.id) {
            _configs[i] = _configs[i].copyWith(isDefault: false);
          }
        }
      }
      
      _configs[index] = config;
      
      // 如果更新的是当前选中的配置，更新选中配置
      if (_selectedConfig.value?.id == config.id) {
        _selectedConfig.value = config;
      }
      
      saveToPrefs(); // 保存配置到本地
    }
  }

  // 删除配置
  void deleteConfig(String id) {
    final wasDefault = _configs.any((c) => c.id == id && c.isDefault);
    _configs.removeWhere((c) => c.id == id);
    
    // 如果删除的是当前选中的配置，重新选择
    if (_selectedConfig.value?.id == id) {
      _selectedConfig.value = _configs.isNotEmpty ? _configs.first : null;
    }
    
    // 如果删除的是默认配置，设置新的默认配置
    if (wasDefault && _configs.isNotEmpty) {
      _configs[0] = _configs[0].copyWith(isDefault: true);
    }
    
    saveToPrefs(); // 保存配置到本地
  }

  // 选择配置
  void selectConfig(String id) {
    final config = _configs.firstWhere((c) => c.id == id, orElse: () => _configs.first);
    _selectedConfig.value = config;
  }

  // 设置默认配置
  void setDefaultConfig(String id) {
    // 将所有配置的isDefault设为false
    _configs.value = _configs.map((c) => c.copyWith(isDefault: false)).toList();
    
    // 将指定ID的配置isDefault设为true
    final index = _configs.indexWhere((c) => c.id == id);
    if (index != -1) {
      _configs[index] = _configs[index].copyWith(isDefault: true);
      
      // 同时将其设为当前选中的配置
      _selectedConfig.value = _configs[index];
      
      saveToPrefs(); // 保存配置到本地
    }
  }

  // 保存配置到本地
  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = jsonEncode(toJson());
      await prefs.setString('api_configs', configsJson);
      debugPrint('API配置已成功保存到本地');
    } catch (e) {
      debugPrint('保存API配置失败: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadFromPrefs(); // 初始化时加载配置
  }

  // 从本地加载配置
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getString('api_configs');
      debugPrint('加载API配置: $configsJson');
      if (configsJson != null) {
        final List<dynamic> configs = jsonDecode(configsJson);
        loadFromJson(configs);
        debugPrint('成功加载API配置，共${_configs.length}个配置');
      } else {
        debugPrint('未找到已保存的API配置');
      }
    } catch (e) {
      debugPrint('加载API配置失败: $e');
    }
  }
}