import 'dart:async';
import 'package:lappy/models/api_config.dart';
import 'package:lappy/services/chatglm_service.dart';
import 'package:lappy/services/deepseek_service.dart';

/// 消息模型
class ChatMessage {
  final String id;
  String content;
  int tokens;
  final DateTime time;
  final bool isUser;
  final String? model;

  ChatMessage({
    required this.id,
    required this.content,
    required this.time,
    required this.isUser,
    this.model,
    this.tokens = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'time': time.toIso8601String(),
    'isUser': isUser,
    'model': model,
    'tokens': tokens,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      time: DateTime.parse(json['time'] as String),
      isUser: json['isUser'] as bool,
      model: json['model'] as String?,
      tokens: json['tokens'] as int? ?? 0,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? time,
    bool? isUser,
    String? model,
    int? tokens,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      time: time ?? this.time,
      isUser: isUser ?? this.isUser,
      model: model ?? this.model,
      tokens: tokens ?? this.tokens,
    );
  }
}

/// 聊天会话模型
class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory ChatSession.create({
    required String id,
    String? title,
  }) {
    final now = DateTime.now();
    return ChatSession(
      id: id,
      title: title ?? '新会话 ${now.hour}:${now.minute}',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  void addMessage(ChatMessage message) {
    messages.add(message);
    updatedAt = DateTime.now();
  }

  void clearMessages() {
    messages.clear();
    updatedAt = DateTime.now();
  }
}

/// 聊天服务接口
abstract class ChatService {
  /// 发送消息并获取响应
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config);

  /// 发送消息并获取流式响应
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config);
}

/// 聊天服务工厂
class ChatServiceFactory {
  static ChatService createService(ApiProvider provider) {
    switch (provider) {
      case ApiProvider.chatGLM:
        return ChatGLMServiceAdapter();
      case ApiProvider.openAI:
        return OpenAIServiceAdapter();
      case ApiProvider.deepseek:
        return DeepseekServiceAdapter();
      case ApiProvider.custom:
      default:
        return CustomServiceAdapter();
    }
  }
}

/// ChatGLM服务适配器
class ChatGLMServiceAdapter implements ChatService {
  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config) async {
    final service = ChatGLMService(config);
    final chatGLMMessages = messages.map((m) => ChatGLMMessage(
      role: m.isUser ? 'user' : 'assistant',
      content: m.content,
    )).toList();
    
    try {
      final response = await service.sendMessage(chatGLMMessages);
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        time: DateTime.now(),
        isUser: false,
        model: config.modelName,
        tokens: response.split(' ').length, // 简单估算token数
      );
    } catch (e) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '发送消息失败: $e',
        time: DateTime.now(),
        isUser: false,
        model: config.modelName,
        tokens: 0,
      );
    }
  }

  @override
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config) async {
    final service = ChatGLMService(config);
    final chatGLMMessages = messages.map((m) => ChatGLMMessage(
      role: m.isUser ? 'user' : 'assistant',
      content: m.content,
    )).toList();
    
    try {
      return await service.sendMessageStream(chatGLMMessages);
    } catch (e) {
      return Stream.value('发送消息失败: $e');
    }
  }
}

/// OpenAI服务适配器 (待实现)
class OpenAIServiceAdapter implements ChatService {
  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现OpenAI API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '这是OpenAI的模拟响应',
      time: DateTime.now(),
      isUser: false,
      model: config.modelName,
      tokens: 42,
    );
  }

  @override
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现OpenAI流式API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return Stream.fromIterable(['这是', 'OpenAI', '的', '模拟', '流式', '响应']);
  }
}

/// Anthropic服务适配器 (待实现)
class AnthropicServiceAdapter implements ChatService {
  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现Anthropic API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '这是Anthropic的模拟响应',
      time: DateTime.now(),
      isUser: false,
      model: config.modelName,
      tokens: 42,
    );
  }

  @override
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现Anthropic流式API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return Stream.fromIterable(['这是', 'Anthropic', '的', '模拟', '流式', '响应']);
  }
}

/// Gemini服务适配器 (待实现)
class GeminiServiceAdapter implements ChatService {
  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现Gemini API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '这是Gemini的模拟响应',
      time: DateTime.now(),
      isUser: false,
      model: config.modelName,
      tokens: 42,
    );
  }

  @override
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现Gemini流式API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return Stream.fromIterable(['这是', 'Gemini', '的', '模拟', '流式', '响应']);
  }
}

/// 自定义服务适配器 (待实现)
class CustomServiceAdapter implements ChatService {
  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现自定义API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '这是自定义API的模拟响应',
      time: DateTime.now(),
      isUser: false,
      model: config.modelName,
      tokens: 42,
    );
  }

  @override
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config) async {
    // TODO: 实现自定义流式API调用
    await Future.delayed(const Duration(seconds: 1)); // 模拟API调用
    
    return Stream.fromIterable(['这是', '自定义API', '的', '模拟', '流式', '响应']);
  }
}

/// Deepseek服务适配器
class DeepseekServiceAdapter implements ChatService {
  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages, ApiConfig config) async {
    // 需要先导入 DeepseekService
    final service = DeepseekService(config);
    final deepseekMessages = messages.map((m) => DeepseekMessage(
      role: m.isUser ? 'user' : 'assistant',
      content: m.content,
    )).toList();
    
    try {
      final response = await service.sendMessage(deepseekMessages);
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        time: DateTime.now(),
        isUser: false,
        model: config.modelName,
        tokens: response.split(' ').length, // 简单估算token数
      );
    } catch (e) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '发送消息失败: $e',
        time: DateTime.now(),
        isUser: false,
        model: config.modelName,
        tokens: 0,
      );
    }
  }

  @override
  Future<Stream<String>> sendMessageStream(List<ChatMessage> messages, ApiConfig config) async {
    final service = DeepseekService(config);
    final deepseekMessages = messages.map((m) => DeepseekMessage(
      role: m.isUser ? 'user' : 'assistant',
      content: m.content,
    )).toList();
    
    try {
      return await service.sendMessageStream(deepseekMessages);
    } catch (e) {
      return Stream.value('发送消息失败: $e');
    }
  }
}