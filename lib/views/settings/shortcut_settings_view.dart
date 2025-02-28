import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/models/shortcut_config.dart';

/// 快捷键设置视图
class ShortcutSettingsView extends StatefulWidget {
  const ShortcutSettingsView({super.key});

  @override
  State<ShortcutSettingsView> createState() => _ShortcutSettingsViewState();
}

class _ShortcutSettingsViewState extends State<ShortcutSettingsView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        final shortcutManager = settings.shortcutConfigManager;
        final config = shortcutManager.config;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('快捷键设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildShortcutCard(
                      context,
                      title: '发送消息',
                      description: '按下此快捷键发送消息',
                      shortcutText: config.getSendKeyString(),
                      onTap: () => _showShortcutDialog(
                        context,
                        title: '设置发送消息快捷键',
                        onSave: (key, ctrl, alt, shift) {
                          final newConfig = config.copyWith(
                            sendKey: key,
                            sendCtrlModifier: ctrl,
                            sendAltModifier: alt,
                            sendShiftModifier: shift,
                          );
                          shortcutManager.updateConfig(newConfig);
                        },
                      ),
                    ),
                    _buildShortcutCard(
                      context,
                      title: '清空消息',
                      description: '按下此快捷键清空当前消息',
                      shortcutText: config.getClearKeyString(),
                      onTap: () => _showShortcutDialog(
                        context,
                        title: '设置清空消息快捷键',
                        onSave: (key, ctrl, alt, shift) {
                          final newConfig = config.copyWith(
                            clearKey: key,
                            clearCtrlModifier: ctrl,
                            clearAltModifier: alt,
                            clearShiftModifier: shift,
                          );
                          shortcutManager.updateConfig(newConfig);
                        },
                      ),
                    ),
                    _buildShortcutCard(
                      context,
                      title: '显示/隐藏窗口',
                      description: '按下此快捷键显示或隐藏应用窗口',
                      shortcutText: config.getToggleWindowKeyString(),
                      onTap: () => _showShortcutDialog(
                        context,
                        title: '设置显示/隐藏窗口快捷键',
                        onSave: (key, ctrl, alt, shift) {
                          final newConfig = config.copyWith(
                            toggleWindowKey: key,
                            toggleWindowCtrlModifier: ctrl,
                            toggleWindowAltModifier: alt,
                            toggleWindowShiftModifier: shift,
                          );
                          shortcutManager.updateConfig(newConfig);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortcutCard(BuildContext context, {
    required String title,
    required String description,
    required String shortcutText,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: Chip(
          label: Text(shortcutText),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showShortcutDialog(BuildContext context, {
    required String title,
    required Function(LogicalKeyboardKey, bool, bool, bool) onSave,
  }) {
    bool isListening = false;
    bool ctrlModifier = false;
    bool altModifier = false;
    bool shiftModifier = false;
    LogicalKeyboardKey? selectedKey;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请按下您想要设置的按键组合'),
              const SizedBox(height: 16),
              if (isListening)
                const Text('正在监听按键...', style: TextStyle(color: Colors.blue))
              else
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      isListening = true;
                    });
                  },
                  child: const Text('点击开始监听'),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text(ctrlModifier ? 'Ctrl' : 'Ctrl', style: TextStyle(color: ctrlModifier ? Colors.white : Colors.grey)),
                    backgroundColor: ctrlModifier ? Colors.blue : Colors.grey.shade200,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(altModifier ? 'Alt' : 'Alt', style: TextStyle(color: altModifier ? Colors.white : Colors.grey)),
                    backgroundColor: altModifier ? Colors.blue : Colors.grey.shade200,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(shiftModifier ? 'Shift' : 'Shift', style: TextStyle(color: shiftModifier ? Colors.white : Colors.grey)),
                    backgroundColor: shiftModifier ? Colors.blue : Colors.grey.shade200,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedKey != null)
                Text('已选择按键: ${_getKeyName(selectedKey!)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: selectedKey == null ? null : () {
                onSave(selectedKey!, ctrlModifier, altModifier, shiftModifier);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    // 键盘事件处理函数
    bool _handleKeyEvent(KeyEvent event) {
      if (!isListening) return false;
      
      if (event is KeyDownEvent) {
        setState(() {
          ctrlModifier = HardwareKeyboard.instance.isControlPressed;
          altModifier = HardwareKeyboard.instance.isAltPressed;
          shiftModifier = HardwareKeyboard.instance.isShiftPressed;
          
          // 忽略修饰键本身
          if (event.logicalKey != LogicalKeyboardKey.control &&
              event.logicalKey != LogicalKeyboardKey.controlLeft &&
              event.logicalKey != LogicalKeyboardKey.controlRight &&
              event.logicalKey != LogicalKeyboardKey.alt &&
              event.logicalKey != LogicalKeyboardKey.altLeft &&
              event.logicalKey != LogicalKeyboardKey.altRight &&
              event.logicalKey != LogicalKeyboardKey.shift &&
              event.logicalKey != LogicalKeyboardKey.shiftLeft &&
              event.logicalKey != LogicalKeyboardKey.shiftRight) {
            selectedKey = event.logicalKey;
            isListening = false;
          }
        });
        return true;
      }
      return false;
    }
    
    // 添加键盘监听器
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    
    // 确保对话框关闭时移除监听器
    Future.delayed(Duration.zero, () {
      final NavigatorState navigator = Navigator.of(context);
      navigator.popUntil((route) {
        if (route is DialogRoute) {
          route.completed.then((_) {
            HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
          });
        }
        return true;
      });
    });
  }
  }

  String _getKeyName(LogicalKeyboardKey key) {
    String keyLabel = key.keyLabel;
    if (keyLabel.isEmpty) {
      // 对于特殊键，提供更友好的名称
      if (key == LogicalKeyboardKey.enter) keyLabel = 'Enter';
      else if (key == LogicalKeyboardKey.escape) keyLabel = 'Esc';
      else if (key == LogicalKeyboardKey.space) keyLabel = 'Space';
      else keyLabel = 'Key ${key.keyId}';
    }
    return keyLabel;
  }
  