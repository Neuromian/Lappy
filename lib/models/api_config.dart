import 'package:flutter/foundation.dart';

/// API供应商枚举
enum ApiProvider {
  openAI('OpenAI'),
  anthropic('Anthropic'),
  gemini('Gemini'),
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
class ApiConfigManager extends ChangeNotifier {
  List<ApiConfig> _configs = [];
  ApiConfig? _selectedConfig;

  // 获取所有配置
  List<ApiConfig> get configs => List.unmodifiable(_configs);
  
  // 获取当前选中的配置
  ApiConfig? get selectedConfig => _selectedConfig;

  // 添加配置
  void addConfig(ApiConfig config) {
    // 如果是第一个配置，设为默认
    if (_configs.isEmpty) {
      config = config.copyWith(isDefault: true);
    }
    
    // 如果设置为默认，取消其他默认
    if (config.isDefault) {
      _configs = _configs.map((c) => c.copyWith(isDefault: false)).toList();
    }
    
    _configs.add(config);
    
    // 如果是默认配置或没有选中配置，选中它
    if (config.isDefault || _selectedConfig == null) {
      _selectedConfig = config;
    }
    
    notifyListeners();
  }

  // 更新配置
  void updateConfig(ApiConfig config) {
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      // 如果设置为默认，取消其他默认
      if (config.isDefault) {
        _configs = _configs.map((c) => c.id != config.id ? c.copyWith(isDefault: false) : c).toList();
      }
      
      _configs[index] = config;
      
      // 如果更新的是当前选中的配置，更新选中配置
      if (_selectedConfig?.id == config.id) {
        _selectedConfig = config;
      }
      
      notifyListeners();
    }
  }

  // 删除配置
  void deleteConfig(String id) {
    final wasDefault = _configs.any((c) => c.id == id && c.isDefault);
    _configs.removeWhere((c) => c.id == id);
    
    // 如果删除的是当前选中的配置，重新选择
    if (_selectedConfig?.id == id) {
      _selectedConfig = _configs.isNotEmpty ? _configs.first : null;
    }
    
    // 如果删除的是默认配置，设置新的默认配置
    if (wasDefault && _configs.isNotEmpty) {
      _configs[0] = _configs[0].copyWith(isDefault: true);
    }
    
    notifyListeners();
  }

  // 选择配置
  void selectConfig(String id) {
    final config = _configs.firstWhere((c) => c.id == id, orElse: () => _configs.first);
    _selectedConfig = config;
    notifyListeners();
  }

  // 设置默认配置
  void setDefaultConfig(String id) {
    // 将所有配置的isDefault设为false
    _configs = _configs.map((c) => c.copyWith(isDefault: false)).toList();
    
    // 将指定ID的配置isDefault设为true
    final index = _configs.indexWhere((c) => c.id == id);
    if (index != -1) {
      _configs[index] = _configs[index].copyWith(isDefault: true);
      
      // 同时将其设为当前选中的配置
      _selectedConfig = _configs[index];
      
      notifyListeners();
    }
  }

  // 从JSON加载配置
  void loadFromJson(List<dynamic> jsonList) {
    _configs = jsonList.map((json) => ApiConfig.fromJson(json)).toList();
    
    // 选择默认配置或第一个配置
    _selectedConfig = _configs.firstWhere(
      (c) => c.isDefault,
      orElse: () {
        if (_configs.isEmpty) {
          throw StateError('No API configs found');
        }
        return _configs.first;
      },
    );
    
    notifyListeners();
  }

  // 转换为JSON
  List<Map<String, dynamic>> toJson() {
    return _configs.map((config) => config.toJson()).toList();
  }
}