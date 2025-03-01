import 'package:flutter/material.dart'
    hide
        Colors,
        IconButton,
        CircularProgressIndicator,
        ButtonStyle,
        showDialog,
        FilledButton;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/views/settings_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: Colors.transparent,
  );

  const windowOptions = WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(400, 300),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Lappy LLM Client',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppSettings(),
      child: FluentApp(
        title: 'Lappy LLM Client',
        themeMode: ThemeMode.light,
        color: Colors.green,
        darkTheme: FluentThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.green,
          visualDensity: VisualDensity.standard,
          fontFamily: 'MiSans',
        ),
        theme: FluentThemeData(
          brightness: Brightness.light,
          accentColor: Colors.green,
          visualDensity: VisualDensity.standard,
          fontFamily: 'MiSans',
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TrayListener, WindowListener {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '0',
      'title': '新会话 1',
      'messages': [],
      'focusNode': FocusNode(),
    }
  ];
  int _selectedChatIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
    _init();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _controller.dispose();
    for (var chat in _chats) {
      chat['focusNode'].dispose();
    }
    super.dispose();
  }

  void _init() async {
    await trayManager.setIcon('assets/images/tray_icon.png');
    await trayManager.setToolTip('Lappy LLM Client');

    final menu = Menu(items: [
      MenuItem(
        key: 'show_hide',
        label: 'Show/Hide',
        onClick: (_) => _toggleWindow(),
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'clear_messages',
        label: 'Clear Messages',
        onClick: (_) => _clearMessages(),
      ),
    ]);
    await trayManager.setContextMenu(menu);
  }

  Future<void> _toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'text': text,
        'time': DateTime.now(),
        'isUser': true,
        'model': null,
        'tokens': 0,
      });
      _controller.clear();
      _isLoading = true;
    });

    // TODO: 实现LLM API调用
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.add({
        'text': '这是一个模拟的LLM响应',
        'time': DateTime.now(),
        'isUser': false,
        'model': 'GPT-3.5',
        'tokens': 10,
      });
      _isLoading = false;
    });
  }

  void _clearMessages() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有消息吗？此操作无法撤销。'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: const Text('确认'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _messages.clear();
      });
    }
  }

  @override
  void onTrayIconMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayDoubleClick() => _toggleWindow();

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text(''),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.history),
              onPressed: () {}, // TODO: 实现历史记录
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _selectedChatIndex,
        displayMode: PaneDisplayMode.compact,
        size: const NavigationPaneSize(
          openMinWidth: 200,
          openMaxWidth: 250,
          compactWidth: 50,
        ),
        items: [
          PaneItemHeader(header: const Text('会话历史')),
          ..._chats
              .asMap()
              .entries
              .map((entry) => PaneItem(
                    icon: const Icon(FluentIcons.chat),
                    title: Text(entry.value['title']),
                    selectedTileColor: entry.key == _selectedChatIndex
                        ? ButtonState.all(Colors.green.withAlpha(25))
                        : null,
                    body: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: (entry.value['messages'] as List).length,
                            itemBuilder: (context, index) {
                              final message =
                                  (entry.value['messages'] as List)[index];
                              return MessageBubble(
                                text: message['text'],
                                time: message['time'],
                                isUser: message['isUser'],
                                model: message['model'],
                                tokens: message['tokens'],
                              );
                            },
                          ),
                        ),
                        if (_isLoading && entry.key == _selectedChatIndex)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ProgressRing(),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: FluentTheme.of(context)
                                    .micaBackgroundColor
                                    .withOpacity(0.7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextBox(
                                      controller: _controller,
                                      placeholder: 'Type your message...',
                                      onSubmitted: (_) => _sendMessage(),
                                      style: const TextStyle(fontSize: 16),
                                      decoration: ButtonState.all(BoxDecoration(
                                        border: null,
                                        borderRadius: BorderRadius.circular(16),
                                      )),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: IconButton(
                                      icon: const Icon(FluentIcons.send),
                                      onPressed: _sendMessage,
                                      style: ButtonStyle(
                                        padding: WidgetStateProperty.all(
                                            const EdgeInsets.all(12)),
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                                Colors.green.withAlpha(25)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedChatIndex = entry.key;
                        _messages.clear();
                        _messages.addAll(List<Map<String, dynamic>>.from(
                            entry.value['messages']));
                        // 移除旧会话的焦点
                        if (_selectedChatIndex != entry.key) {
                          _chats[_selectedChatIndex]['focusNode'].unfocus();
                        }
                        // 请求新会话的焦点
                        entry.value['focusNode'].requestFocus();
                      });
                    },
                  ))
              ,
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.add),
            title: const Text('新的会话'),
            body: const SizedBox.shrink(),
            selectedTileColor: ButtonState.all(Colors.transparent),
            onTap: () {
              setState(() {
                _chats.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': '新会话 ${_chats.length + 1}',
                  'messages': [],
                  'focusNode': FocusNode(),
                });
                _selectedChatIndex = 0;
                _messages.clear();
                _chats[0]['focusNode'].requestFocus();
              });
            },
          ),
          PaneItem(
            icon: const Icon(FluentIcons.delete),
            title: const Text('清空对话'),
            body: const SizedBox.shrink(),
            onTap: _clearMessages,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('设置'),
            body: const SettingsView(),
            onTap: () {
              Navigator.push(
                context,
                FluentPageRoute(
                  builder: (context) => const SettingsView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isUser;
  final String? model;
  final int tokens;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isUser,
    this.model,
    this.tokens = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser
                ? [Colors.blue.withAlpha(76), Colors.blue.withAlpha(127)]
                : [Colors.grey.withAlpha(76), Colors.grey.withAlpha(127)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 16 : 4),
            topRight: Radius.circular(isUser ? 4 : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? Colors.blue : Colors.grey).withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 6),
            DefaultTextStyle(
              style: FluentTheme.of(context).typography.caption!.copyWith(
                    color: (isUser ? Colors.blue : Colors.grey).withAlpha(200),
                  ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time.toLocal().toString().split('.')[0]),
                  if (!isUser && model != null) ...[
                    const SizedBox(width: 8),
                    Text('Model: $model'),
                    const SizedBox(width: 8),
                    Text('Tokens: $tokens'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
