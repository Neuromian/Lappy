import 'package:flutter/material.dart' hide Colors, IconButton, CircularProgressIndicator;
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
    titleBarStyle: TitleBarStyle.normal,
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

class _MainScreenState extends State<MainScreen> with TrayListener, WindowListener {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
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
        key: 'exit_app',
        label: 'Exit',
        onClick: (_) => windowManager.close(),
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

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
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
        title: const Text('Lappy LLM Client'),
        leading: Button(
          child: const Icon(FluentIcons.settings),
          onPressed: () {
            Navigator.of(context).push(
              FluentPageRoute(builder: (context) => const SettingsView()),
            );
          },
        ),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.history),
              onPressed: () {}, // TODO: 实现历史记录
            ),
            IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: _clearMessages,
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: ProgressRing(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _controller,
                    placeholder: 'Type your message...',
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FluentIcons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
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
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time.toLocal().toString().split('.')[0],
                  style: FluentTheme.of(context).typography.caption,
                ),
                if (!isUser && model != null) ...[                  
                  const SizedBox(width: 8),
                  Text(
                    'Model: $model',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tokens: $tokens',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
