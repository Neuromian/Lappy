import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lappy/models/api_config.dart';
import 'package:lappy/models/app_settings.dart';
import 'package:lappy/services/chat_service.dart';

/// 聊天控制器
class ChatController extends GetxController {
  // 单例模式
  static ChatController get to => Get.find();

  // 会话列表
  final _sessions = <ChatSession>[].obs;
  List<ChatSession> get sessions => _sessions;

  // 当前选中的会话
  final _currentSessionIndex = 0.obs;
  int get currentSessionIndex => _currentSessionIndex.value;
  ChatSession? get currentSession => _sessions.isNotEmpty ? _sessions[_currentSessionIndex.value] : null;

  // 是否正在加载
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // 是否已初始化
  final _initialized = false.obs;
  bool get initialized => _initialized.value;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  // 初始化
  Future<void> init() async {
    if (_initialized.value) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('chat_sessions');

      if (sessionsJson != null) {
        final List<dynamic> sessionsData = jsonDecode(sessionsJson);
        _sessions.clear();
        _sessions.addAll(sessionsData
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList());
      }

      // 如果没有会话，创建一个新会话
      if (_sessions.isEmpty) {
        createNewSession();
      }

      _initialized.value = true;
    } catch (e) {
      debugPrint('初始化聊天控制器失败: $e');
    }
  }

  // 保存会话
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString('chat_sessions', sessionsJson);
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
  }

  // 创建新会话
  ChatSession createNewSession({String? title}) {
    final session = ChatSession.create(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _sessions.insert(0, session);
    _currentSessionIndex.value = 0;
    _saveSessions();
    return session;
  }

  // 切换会话
  void switchSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      _currentSessionIndex.value = index;
    }
  }

  // 删除会话
  void deleteSession(String id) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _sessions.removeAt(index);
      
      // 如果删除的是当前会话，切换到第一个会话
      if (_currentSessionIndex.value == index) {
        _currentSessionIndex.value = _sessions.isEmpty ? -1 : 0;
      } else if (_currentSessionIndex.value > index) {
        // 如果删除的会话在当前会话之前，当前会话索引减1
        _currentSessionIndex.value--;
      }
      
      _saveSessions();
    }
  }

  // 清空当前会话消息
  void clearCurrentSessionMessages() {
    if (currentSession != null) {
      currentSession!.clearMessages();
      _sessions.refresh();
      _saveSessions();
    }
  }

  // 重命名会话
  void renameSession(String id, String newTitle) {
    final session = _sessions.firstWhere((s) => s.id == id, orElse: () => throw Exception('会话不存在'));
    session.title = newTitle;
    _sessions.refresh();
    _saveSessions();
  }

  // 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isLoading.value || currentSession == null) return;

    // 获取API配置
    final apiConfigManager = AppSettings().apiConfigManager;
    final apiConfig = apiConfigManager.selectedConfig;
    
    if (apiConfig == null) {
      // 如果没有配置API，添加错误消息
      currentSession!.addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '错误：请先在设置中配置API',
        time: DateTime.now(),
        isUser: false,
        tokens: 0,
      ));
      _sessions.refresh();
      return;
    }

    // 添加用户消息
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      time: DateTime.now(),
      isUser: true,
      tokens: 0,
    );
    currentSession!.addMessage(userMessage);
    _sessions.refresh();
    await _saveSessions();

    // 设置加载状态
    _isLoading.value = true;

    try {
      // 创建聊天服务
      final chatService = ChatServiceFactory.createService(apiConfig.provider);
      
      // 发送消息
      final response = await chatService.sendMessage(
        currentSession!.messages,
        apiConfig,
      );
      
      // 添加响应消息
      currentSession!.addMessage(response);
      _sessions.refresh();
    } catch (e) {
      // 添加错误消息
      currentSession!.addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '发送消息失败: $e',
        time: DateTime.now(),
        isUser: false,
        tokens: 0,
      ));
      _sessions.refresh();
    } finally {
      // 重置加载状态
      _isLoading.value = false;
      await _saveSessions();
    }
  }

  // 发送流式消息
  Future<void> sendMessageStream(String content) async {
    if (content.trim().isEmpty || _isLoading.value || currentSession == null) return;

    // 获取API配置
    final apiConfigManager = AppSettings().apiConfigManager;
    final apiConfig = apiConfigManager.selectedConfig;
    
    if (apiConfig == null) {
      // 如果没有配置API，添加错误消息
      currentSession!.addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '错误：请先在设置中配置API',
        time: DateTime.now(),
        isUser: false,
        tokens: 0,
      ));
      _sessions.refresh();
      return;
    }

    // 添加用户消息
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      time: DateTime.now(),
      isUser: true,
      tokens: 0,
    );
    currentSession!.addMessage(userMessage);
    _sessions.refresh();
    await _saveSessions();
    
    // 创建一个空的AI响应消息并立即添加到会话中
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final initialAiMessage = ChatMessage(
      id: aiMessageId,
      content: '',
      time: DateTime.now(),
      isUser: false,
      model: apiConfig.modelName,
      tokens: 0,
    );
    currentSession!.addMessage(initialAiMessage);
    _sessions.refresh();
    await _saveSessions();

    // 设置加载状态
    _isLoading.value = true;

    String accumulatedContent = '';
    int estimatedTokens = 0;
    int? messageIndex;

    try {
      // 创建聊天服务
      final chatService = ChatServiceFactory.createService(apiConfig.provider);
      
      // 发送流式消息，排除当前正在生成的AI消息
      final responseStream = await chatService.sendMessageStream(
        currentSession!.messages.where((m) => m.id != aiMessageId).toList(),
        apiConfig,
      );
      
      // 监听流式响应
      await for (final chunk in responseStream) {
        if (chunk.trim().isNotEmpty) {
          // 更新累积内容
          accumulatedContent += chunk;
          estimatedTokens = (accumulatedContent.length / 4).round();
          
          // 查找消息索引（仅在第一次时查找）
          messageIndex ??= currentSession!.messages.indexWhere((m) => m.id == aiMessageId);
          
          if (messageIndex != -1) {
            // 使用不可变的方式更新消息
            final updatedMessage = currentSession!.messages[messageIndex!].copyWith(
              content: accumulatedContent,
              tokens: estimatedTokens,
            );
            
            // 原子性地更新消息
            currentSession!.messages[messageIndex!] = updatedMessage;
            _sessions.refresh();
            
            // 定期保存会话，避免过于频繁的IO操作
            if (estimatedTokens % 100 == 0) {
              await _saveSessions();
            }
          }
        }
      }
    } catch (e) {
      // 更新AI消息为错误消息
      final index = currentSession!.messages.indexWhere((m) => m.id == aiMessageId);
      if (index != -1) {
        currentSession!.messages[index] = ChatMessage(
          id: aiMessageId,
          content: '发送消息失败: $e',
          time: DateTime.now(),
          isUser: false,
          model: apiConfig.modelName,
          tokens: 0,
        );
        _sessions.refresh();
      }
    } finally {
      // 重置加载状态
      _isLoading.value = false;
      await _saveSessions();
    }
  }
}