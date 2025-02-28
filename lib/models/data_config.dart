import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// 数据管理配置模型
class DataConfig {
  // 缓存目录路径
  String cachePath;
  
  // 是否自动备份
  bool autoBackup;
  
  // 自动备份间隔（天）
  int backupInterval;
  
  // 最大备份数量
  int maxBackupCount;
  
  DataConfig({
    required this.cachePath,
    this.autoBackup = false,
    this.backupInterval = 7,
    this.maxBackupCount = 5,
  });
  
  // 从JSON创建DataConfig
  factory DataConfig.fromJson(Map<String, dynamic> json) {
    return DataConfig(
      cachePath: json['cachePath'] as String,
      autoBackup: json['autoBackup'] as bool? ?? false,
      backupInterval: json['backupInterval'] as int? ?? 7,
      maxBackupCount: json['maxBackupCount'] as int? ?? 5,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'cachePath': cachePath,
      'autoBackup': autoBackup,
      'backupInterval': backupInterval,
      'maxBackupCount': maxBackupCount,
    };
  }
  
  // 创建副本
  DataConfig copyWith({
    String? cachePath,
    bool? autoBackup,
    int? backupInterval,
    int? maxBackupCount,
  }) {
    return DataConfig(
      cachePath: cachePath ?? this.cachePath,
      autoBackup: autoBackup ?? this.autoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      maxBackupCount: maxBackupCount ?? this.maxBackupCount,
    );
  }
}

/// 数据管理器
class DataManager extends ChangeNotifier {
  DataConfig _config;
  
  // 构造函数
  DataManager() : _config = DataConfig(cachePath: '') {
    _initDefaultPath();
  }
  
  // 统一处理路径分隔符
  String normalizePath(String path) {
    // 根据不同操作系统使用不同的路径分隔符
    final separator = Platform.pathSeparator;
    // 将路径中的正斜杠和反斜杠都替换为当前系统的分隔符
    return path.replaceAll('\\', separator).replaceAll('/', separator);
  }

  // 初始化默认路径
  Future<void> _initDefaultPath() async {
    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final defaultPath = normalizePath('${appDir.path}${Platform.pathSeparator}lappy_data');
      
      // 确保目录存在
      final dir = Directory(defaultPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      _config = _config.copyWith(cachePath: defaultPath);
      notifyListeners();
    } catch (e) {
      debugPrint('初始化数据目录失败: $e');
    }
  }
  
  // 获取当前配置
  DataConfig get config => _config;
  
  // 更新配置
  void updateConfig(DataConfig config) {
    // 确保路径使用正确的分隔符
    final normalizedConfig = config.copyWith(
      cachePath: config.cachePath.isNotEmpty ? normalizePath(config.cachePath) : config.cachePath
    );
    _config = normalizedConfig;
    notifyListeners();
  }
  
  // 从JSON加载配置
  void loadFromJson(Map<String, dynamic> json) {
    _config = DataConfig.fromJson(json);
    notifyListeners();
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return _config.toJson();
  }
  
  // 重置为默认设置
  Future<void> resetToDefault() async {
    _config = DataConfig(
      cachePath: '',
      autoBackup: false,
      backupInterval: 7,
      maxBackupCount: 5
    );
    await _initDefaultPath();
    notifyListeners();
  }
  
  // 导出所有数据
  Future<String?> exportAllData(String targetPath) async {
    try {
      final normalizedTargetPath = normalizePath(targetPath);
      final sourceDir = Directory(_config.cachePath);
      final targetDir = Directory(normalizedTargetPath);
      
      if (!await sourceDir.exists()) {
        return '源目录不存在';
      }
      
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // 复制所有文件
      await for (final entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = entity.path.substring(_config.cachePath.length);
          final normalizedRelativePath = normalizePath(relativePath);
          final targetFile = File(normalizePath('${targetDir.path}$normalizedRelativePath'));
          
          // 确保目标文件的目录存在
          await targetFile.parent.create(recursive: true);
          
          // 复制文件
          await entity.copy(targetFile.path);
        }
      }
      
      return targetDir.path;
    } catch (e) {
      return '导出数据失败: $e';
    }
  }
  
  // 清空缓存
  Future<bool> clearCache() async {
    try {
      final normalizedPath = normalizePath(_config.cachePath);
      final dir = Directory(normalizedPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('清空缓存失败: $e');
      return false;
    }
  }
}