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
import 'package:lappy/views/chat_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';

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

  // 初始化 AppSettings 并注入到 GetX
  final appSettings = AppSettings();
  Get.put(appSettings);
  await appSettings.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
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

  void _clearMessages() async {
    // 此方法保留但不再使用，功能已移至ChatView
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
      appBar: const NavigationAppBar(
        title: Text('Lappy LLM Client'),
      ),
      content: const ChatView(),
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
                ? [Colors.blue.withAlpha(25), Colors.blue.withAlpha(50)]
                : [Colors.grey.withAlpha(25), Colors.grey.withAlpha(50)],
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
              color: (isUser ? Colors.blue : Colors.grey).withAlpha(15),
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
