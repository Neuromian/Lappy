import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ShortcutSettingsPage extends StatefulWidget {
  const ShortcutSettingsPage({super.key});

  @override
  State<ShortcutSettingsPage> createState() => _ShortcutSettingsPageState();
}

class _ShortcutSettingsPageState extends State<ShortcutSettingsPage> {
  bool _isRecording = false;
  String _currentShortcut = 'Ctrl + Enter';
  final FocusNode _focusNode = FocusNode();
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    _focusNode.requestFocus();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!_isRecording || event is! RawKeyDownEvent) return;

    final Set<LogicalKeyboardKey> pressedKeys = RawKeyboard.instance.keysPressed;
    if (pressedKeys.isEmpty) return;

    final List<String> keyNames = [];
    
    if (pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight)) {
      keyNames.add('Ctrl');
    }
    if (pressedKeys.contains(LogicalKeyboardKey.altLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.altRight)) {
      keyNames.add('Alt');
    }
    if (pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.shiftRight)) {
      keyNames.add('Shift');
    }

    // 添加非修饰键
    for (final key in pressedKeys) {
      if (![LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight,
           LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight,
           LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight]
          .contains(key)) {
        String keyLabel = key.keyLabel;
        if (keyLabel.length == 1) {
          keyLabel = keyLabel.toUpperCase();
        }
        keyNames.add(keyLabel);
      }
    }

    if (keyNames.isNotEmpty) {
      setState(() {
        _currentShortcut = keyNames.join(' + ');
        _isRecording = false;
      });
    }
  }

  void _resetShortcut() {
    setState(() {
      _currentShortcut = 'Ctrl + Enter';
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('快捷键设置'),
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('消息发送快捷键', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: _handleKeyEvent,
                  child: InfoLabel(
                    label: '当前快捷键',
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? Colors.yellow.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _isRecording ? '请按下新的快捷键组合...' : _currentShortcut,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: _isRecording ? null : _startRecording,
                          child: const Text('修改'),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: _resetShortcut,
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const InfoBar(
                  title: Text('提示'),
                  content: Text('按下想要设置的快捷键组合，支持 Ctrl、Alt、Shift 等组合键'),
                  severity: InfoBarSeverity.info,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}