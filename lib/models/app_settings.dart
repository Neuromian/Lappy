import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:lappy/models/api_config.dart';
import 'package:lappy/models/shortcut_config.dart';
import 'package:lappy/models/data_config.dart';

/// 应用设置管理器
class AppSettings extends GetxController {
  // 单例模式
  static AppSettings get to => Get.find();
  
  // 子设置管理器
  final apiConfigManager = ApiConfigManager();
  final shortcutConfigManager = ShortcutConfigManager();
  final dataManager = DataManager();

  // 是否已初始化
  final _initialized = false.obs;
  bool get initialized => _initialized.value;

  // 初始化设置
  Future<void> init() async {
    if (_initialized.value) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载API配置
      final apiConfigsJson = prefs.getString('api_configs');
      if (apiConfigsJson != null) {
        final List<dynamic> apiConfigs = jsonDecode(apiConfigsJson);
        apiConfigManager.loadFromJson(apiConfigs);
      }
      
      // 加载快捷键配置
      final shortcutConfigJson = prefs.getString('shortcut_config');
      if (shortcutConfigJson != null) {
        final Map<String, dynamic> shortcutConfig = jsonDecode(shortcutConfigJson);
        shortcutConfigManager.loadFromJson(shortcutConfig);
      }
      
      // 加载数据配置
      final dataConfigJson = prefs.getString('data_config');
      if (dataConfigJson != null) {
        final Map<String, dynamic> dataConfig = jsonDecode(dataConfigJson);
        dataManager.loadFromJson(dataConfig);
      }
      
      // 监听子设置变化
      apiConfigManager.addListener(_saveSettings);
      shortcutConfigManager.addListener(_saveSettings);
      dataManager.addListener(_saveSettings);
      
      _initialized.value = true;
      update();
    } catch (e) {
      debugPrint('初始化设置失败: $e');
    }
  }

  // 保存设置到SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存API配置
      final apiConfigsJson = jsonEncode(apiConfigManager.toJson());
      await prefs.setString('api_configs', apiConfigsJson);
      
      // 保存快捷键配置
      final shortcutConfigJson = jsonEncode(shortcutConfigManager.toJson());
      await prefs.setString('shortcut_config', shortcutConfigJson);
      
      // 保存数据配置
      final dataConfigJson = jsonEncode(dataManager.toJson());
      await prefs.setString('data_config', dataConfigJson);
      
      update();
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  // 重置所有设置
  Future<void> resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 清除所有设置
      await prefs.remove('api_configs');
      await prefs.remove('shortcut_config');
      await prefs.remove('data_config');
      
      // 重新初始化子设置管理器
      apiConfigManager.loadFromJson([]);
      shortcutConfigManager.updateConfig(ShortcutConfig());
      await dataManager.resetToDefault();
      
      update();
    } catch (e) {
      debugPrint('重置设置失败: $e');
    }
  }
}