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

  // 添加配置
  void addConfig(ApiConfig config) {
    // 如果是第一个配置，设为默认
    if (_configs.isEmpty) {
      config = config.copyWith(isDefault: true);
    }
    
    // 如果设置为默认，取消其他默认
    if (config.isDefault) {
      _configs.value = _configs.map((c) => c.copyWith(isDefault: false)).toList();
    }
    
    _configs.add(config);
    
    // 如果是默认配置或没有选中配置，选中它
    if (config.isDefault || _selectedConfig.value == null) {
      _selectedConfig.value = config;
    }
  }

  // 更新配置
  void updateConfig(ApiConfig config) {
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      // 如果设置为默认，取消其他默认
      if (config.isDefault) {
        _configs.value = _configs.map((c) => c.id != config.id ? c.copyWith(isDefault: false) : c).toList();
      }
      
      _configs[index] = config;
      
      // 如果更新的是当前选中的配置，更新选中配置
      if (_selectedConfig.value?.id == config.id) {
        _selectedConfig.value = config;
      }
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
    }
  }

  // 从JSON加载配置
  void loadFromJson(List<dynamic> json) {
    _configs.value = json.map((item) => ApiConfig.fromJson(item)).toList();
    // 设置默认选中配置
    _selectedConfig.value = _configs.firstWhereOrNull((c) => c.isDefault) ?? _configs.firstOrNull;
  }

  // 保存配置到本地
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = _configs.map((c) => c.toJson()).toList();
    await prefs.setString('api_configs', jsonEncode(configsJson));
  }

  @override
  void onInit() {
    super.onInit();
    // 监听配置变化并保存
    ever(_configs, (_) => saveToPrefs());
  }

  // 转换为JSON
  List<Map<String, dynamic>> toJson() {
    return _configs.map((config) => config.toJson()).toList();
  }
}