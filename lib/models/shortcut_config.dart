import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 快捷键配置模型
class ShortcutConfig {
  // 发送消息快捷键
  LogicalKeyboardKey sendKey;
  bool sendCtrlModifier;
  bool sendAltModifier;
  bool sendShiftModifier;
  
  // 清空消息快捷键
  LogicalKeyboardKey clearKey;
  bool clearCtrlModifier;
  bool clearAltModifier;
  bool clearShiftModifier;
  
  // 显示/隐藏窗口快捷键
  LogicalKeyboardKey toggleWindowKey;
  bool toggleWindowCtrlModifier;
  bool toggleWindowAltModifier;
  bool toggleWindowShiftModifier;
  
  ShortcutConfig({
    this.sendKey = LogicalKeyboardKey.enter,
    this.sendCtrlModifier = false,
    this.sendAltModifier = false,
    this.sendShiftModifier = false,
    
    this.clearKey = LogicalKeyboardKey.escape,
    this.clearCtrlModifier = true,
    this.clearAltModifier = false,
    this.clearShiftModifier = false,
    
    this.toggleWindowKey = LogicalKeyboardKey.space,
    this.toggleWindowCtrlModifier = true,
    this.toggleWindowAltModifier = true,
    this.toggleWindowShiftModifier = false,
  });
  
  // 从JSON创建ShortcutConfig
  factory ShortcutConfig.fromJson(Map<String, dynamic> json) {
    return ShortcutConfig(
      sendKey: LogicalKeyboardKey(json['sendKey'] as int),
      sendCtrlModifier: json['sendCtrlModifier'] as bool,
      sendAltModifier: json['sendAltModifier'] as bool,
      sendShiftModifier: json['sendShiftModifier'] as bool,
      
      clearKey: LogicalKeyboardKey(json['clearKey'] as int),
      clearCtrlModifier: json['clearCtrlModifier'] as bool,
      clearAltModifier: json['clearAltModifier'] as bool,
      clearShiftModifier: json['clearShiftModifier'] as bool,
      
      toggleWindowKey: LogicalKeyboardKey(json['toggleWindowKey'] as int),
      toggleWindowCtrlModifier: json['toggleWindowCtrlModifier'] as bool,
      toggleWindowAltModifier: json['toggleWindowAltModifier'] as bool,
      toggleWindowShiftModifier: json['toggleWindowShiftModifier'] as bool,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'sendKey': sendKey.keyId,
      'sendCtrlModifier': sendCtrlModifier,
      'sendAltModifier': sendAltModifier,
      'sendShiftModifier': sendShiftModifier,
      
      'clearKey': clearKey.keyId,
      'clearCtrlModifier': clearCtrlModifier,
      'clearAltModifier': clearAltModifier,
      'clearShiftModifier': clearShiftModifier,
      
      'toggleWindowKey': toggleWindowKey.keyId,
      'toggleWindowCtrlModifier': toggleWindowCtrlModifier,
      'toggleWindowAltModifier': toggleWindowAltModifier,
      'toggleWindowShiftModifier': toggleWindowShiftModifier,
    };
  }
  
  // 创建副本
  ShortcutConfig copyWith({
    LogicalKeyboardKey? sendKey,
    bool? sendCtrlModifier,
    bool? sendAltModifier,
    bool? sendShiftModifier,
    
    LogicalKeyboardKey? clearKey,
    bool? clearCtrlModifier,
    bool? clearAltModifier,
    bool? clearShiftModifier,
    
    LogicalKeyboardKey? toggleWindowKey,
    bool? toggleWindowCtrlModifier,
    bool? toggleWindowAltModifier,
    bool? toggleWindowShiftModifier,
  }) {
    return ShortcutConfig(
      sendKey: sendKey ?? this.sendKey,
      sendCtrlModifier: sendCtrlModifier ?? this.sendCtrlModifier,
      sendAltModifier: sendAltModifier ?? this.sendAltModifier,
      sendShiftModifier: sendShiftModifier ?? this.sendShiftModifier,
      
      clearKey: clearKey ?? this.clearKey,
      clearCtrlModifier: clearCtrlModifier ?? this.clearCtrlModifier,
      clearAltModifier: clearAltModifier ?? this.clearAltModifier,
      clearShiftModifier: clearShiftModifier ?? this.clearShiftModifier,
      
      toggleWindowKey: toggleWindowKey ?? this.toggleWindowKey,
      toggleWindowCtrlModifier: toggleWindowCtrlModifier ?? this.toggleWindowCtrlModifier,
      toggleWindowAltModifier: toggleWindowAltModifier ?? this.toggleWindowAltModifier,
      toggleWindowShiftModifier: toggleWindowShiftModifier ?? this.toggleWindowShiftModifier,
    );
  }
  
  // 获取快捷键的可读字符串表示
  String getSendKeyString() {
    return _getKeyString(sendKey, sendCtrlModifier, sendAltModifier, sendShiftModifier);
  }
  
  String getClearKeyString() {
    return _getKeyString(clearKey, clearCtrlModifier, clearAltModifier, clearShiftModifier);
  }
  
  String getToggleWindowKeyString() {
    return _getKeyString(toggleWindowKey, toggleWindowCtrlModifier, toggleWindowAltModifier, toggleWindowShiftModifier);
  }
  
  String _getKeyString(LogicalKeyboardKey key, bool ctrl, bool alt, bool shift) {
    final buffer = StringBuffer();
    if (ctrl) buffer.write('Ctrl + ');
    if (alt) buffer.write('Alt + ');
    if (shift) buffer.write('Shift + ');
    
    // 获取键的可读名称
    String keyLabel = key.keyLabel;
    if (keyLabel.isEmpty) {
      // 对于特殊键，提供更友好的名称
      if (key == LogicalKeyboardKey.enter) keyLabel = 'Enter';
      else if (key == LogicalKeyboardKey.escape) keyLabel = 'Esc';
      else if (key == LogicalKeyboardKey.space) keyLabel = 'Space';
      else keyLabel = 'Key ${key.keyId}';
    }
    
    buffer.write(keyLabel);
    return buffer.toString();
  }
}

/// 快捷键配置管理器
class ShortcutConfigManager extends ChangeNotifier {
  ShortcutConfig _config = ShortcutConfig();
  
  // 获取当前配置
  ShortcutConfig get config => _config;
  
  // 更新配置
  void updateConfig(ShortcutConfig config) {
    _config = config;
    notifyListeners();
  }
  
  // 从JSON加载配置
  void loadFromJson(Map<String, dynamic> json) {
    _config = ShortcutConfig.fromJson(json);
    notifyListeners();
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return _config.toJson();
  }
}