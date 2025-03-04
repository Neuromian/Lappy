import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:lappy/controllers/chat_controller.dart';
import 'package:lappy/services/chat_service.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/views/settings_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// 聊天视图组件
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late ChatController _chatController;
  final Map<String, FlyoutController> _flyoutControllers = {};

  @override
  void initState() {
    super.initState();
    _chatController = Get.put(ChatController());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _flyoutControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 发送消息
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatController.isLoading) return;

    // 使用流式响应
    _chatController.sendMessageStream(text);
    _messageController.clear();
    _messageFocusNode.requestFocus();
  }

  // 创建新会话
  void _createNewSession() {
    _chatController.createNewSession();
  }

  // 清空当前会话消息
  void _clearCurrentSessionMessages() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空当前会话的所有消息吗？此操作无法撤销。'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('确认'),
            onPressed: () {
              _chatController.clearCurrentSessionMessages();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // 删除会话
  void _deleteSession(String id) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个会话吗？此操作无法撤销。'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('确认'),
            onPressed: () {
              _chatController.deleteSession(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // 重命名会话
  void _renameSession(String id, String currentTitle) {
    final TextEditingController titleController = TextEditingController(text: currentTitle);
    
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('重命名会话'),
        content: SizedBox(
          height: 40,
          child: TextBox(
            controller: titleController,
            placeholder: '请输入新的会话名称',
            autofocus: true,
          ),
        ),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('确认'),
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                _chatController.renameSession(id, newTitle);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ).then((_) => titleController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentSession = _chatController.currentSession;
      final sessions = _chatController.sessions;
      
      final navigationPane = NavigationPane(
        selected: _chatController.sessions.isEmpty ? 0 : _chatController.currentSessionIndex,
        displayMode: PaneDisplayMode.compact,
        size: const NavigationPaneSize(
          openMinWidth: 200,
          openMaxWidth: 250,
          compactWidth: 50,
        ),
        items: [
          PaneItemHeader(header: const Text('会话历史')),
          ...sessions.asMap().entries.map((entry) => PaneItem(
            icon: const Icon(FluentIcons.chat),
            title: Text(entry.value.title),
            body: const SizedBox.shrink(),
            onTap: () => _chatController.switchSession(entry.key),
            trailing: FlyoutTarget(
              controller: _flyoutControllers.putIfAbsent(entry.value.id, () => FlyoutController()),
              child: IconButton(
                icon: const Icon(FluentIcons.more),
                onPressed: () {
                  _flyoutControllers[entry.value.id]?.showFlyout(
                    barrierDismissible: true,
                    dismissOnPointerMoveAway: false,
                    dismissWithEsc: true,
                    builder: (context) {
                      return MenuFlyout(items: [
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.rename),
                          text: const Text('重命名'),
                          onPressed: () {
                            Flyout.of(context).close();
                            _renameSession(entry.value.id, entry.value.title);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.delete),
                          text: const Text('删除'),
                          onPressed: () {
                            Flyout.of(context).close();
                            _deleteSession(entry.value.id);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.download),
                          text: const Text('导出'),
                          onPressed: () {
                            Flyout.of(context).close();
                            showDialog(
                              context: context,
                              builder: (context) => ContentDialog(
                                title: const Text('导出会话'),
                                content: const Text('确定要导出当前会话吗？将会打开文件保存对话框。'),
                                actions: [
                                  Button(
                                    child: const Text('取消'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  FilledButton(
                                    child: const Text('确认'),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final session = _chatController.sessions.firstWhere((s) => s.id == entry.value.id);
                                      final messages = session.messages.map((m) => m.toJson()).toList();
                                      final data = {
                                        'id': session.id,
                                        'title': session.title,
                                        'messages': messages,
                                      };
                                      final jsonString = jsonEncode(data);
                                      // 清理文件名，移除Windows不允许的特殊字符
                                      final cleanTitle = session.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
                                      final result = await FilePicker.platform.saveFile(
                                        fileName: '${cleanTitle}.json',
                                        type: FileType.custom,
                                        allowedExtensions: ['json'],
                                      );
                                      if (result != null) {
                                        await File(result).writeAsString(jsonString);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]);
                    },
                  );
                },
              ),
            ),
          )),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.add),
            title: const Text('新的会话'),
            body: const SizedBox.shrink(),
            onTap: _createNewSession,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.delete),
            title: const Text('清空对话'),
            body: const SizedBox.shrink(),
            onTap: _clearCurrentSessionMessages,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('设置'),
            body: const SizedBox.shrink(),
            onTap: () => Navigator.push(
              context,
              FluentPageRoute(
                builder: (context) => const SettingsView(),
              ),
            ),
          ),
        ],
      );

      return NavigationView(
        paneBodyBuilder: (item, _) {
          return ScaffoldPage(
            content: currentSession == null
                ? const Center(child: Text('没有会话，请创建一个新会话'))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: currentSession.messages.length,
                          itemBuilder: (context, index) {
                            final message = currentSession.messages[index];
                            if (index == currentSession.messages.length - 1 && message.isUser) {
                              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                            }
                            return MessageBubble(
                              message: message,
                            );
                          },
                        ),
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
                                    controller: _messageController,
                                    focusNode: _messageFocusNode,
                                    placeholder: '输入消息...',
                                    onSubmitted: (_) => _sendMessage(),
                                    style: const TextStyle(fontSize: 16),
                                    maxLines: 5,
                                    minLines: 1,
                                    decoration: ButtonState.all(BoxDecoration(
                                      color: FluentTheme.of(context).micaBackgroundColor.withOpacity(0.7),
                                      border: null,
                                      borderRadius: BorderRadius.circular(16),
                                    )),
                                    suffix: IconButton(
                                      icon: const Icon(FluentIcons.send),
                                      onPressed: _sendMessage,
                                      style: ButtonStyle(
                                        padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
                                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.isHovering) {
                                            return Colors.green.withAlpha(40);
                                          }
                                          return Colors.transparent;
                                        }),
                                        shape: ButtonState.all(const CircleBorder()),
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
        pane: navigationPane,
      );
    });
  }
}

/// 消息气泡组件
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  Widget _buildLoadingEffect() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.white.withOpacity(0.1),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: ProgressRing(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: !message.isUser && message.content.isEmpty
          ? _buildLoadingEffect()
          : Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: message.isUser
                ? [Colors.blue.withAlpha(25), Colors.blue.withAlpha(50)]
                : [Colors.grey.withAlpha(25), Colors.grey.withAlpha(50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(message.isUser ? 16 : 4),
            topRight: Radius.circular(message.isUser ? 4 : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: (message.isUser ? Colors.blue : Colors.grey).withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 6),
            DefaultTextStyle(
              style: FluentTheme.of(context).typography.caption!.copyWith(
                    color: (message.isUser ? Colors.blue : Colors.grey).withAlpha(200),
                  ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.time.toLocal().toString().split('.')[0]),
                  if (!message.isUser && message.model != null) ...[                    
                    const SizedBox(width: 8),
                    Text('Model: ${message.model}'),
                    const SizedBox(width: 8),
                    Text('Tokens: ${message.tokens}'),
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