import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lappy/models/api_config.dart';

class ChatGLMMessage {
  final String role;
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  ChatGLMMessage({
    required this.role,
    required this.content,
    this.toolCalls,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (toolCalls != null) 'tool_calls': toolCalls,
  };

  factory ChatGLMMessage.fromJson(Map<String, dynamic> json) {
    return ChatGLMMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class ChatGLMService {
  final ApiConfig config;

  ChatGLMService(this.config);

  Future<String> sendMessage(List<ChatGLMMessage> messages) async {
    final url = Uri.parse('${config.baseUrl}/api/paas/v4/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };

    final body = jsonEncode({
      'model': config.modelName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': false,
      'temperature': 0.7,
      'top_p': 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        throw Exception('API调用失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
  }

  Future<Stream<String>> sendMessageStream(List<ChatGLMMessage> messages) async {
    final url = Uri.parse('${config.baseUrl}/api/paas/v4/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };

    final body = jsonEncode({
      'model': config.modelName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': true,
      'temperature': 0.7,
      'top_p': 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return Stream.fromIterable(response.body.split('\n')
            .where((line) => line.startsWith('data: ') && line != 'data: [DONE]')
            .map((line) => line.substring(6))
            .map((jsonStr) => (jsonDecode(jsonStr)['choices'][0]['delta']['content'] ?? '').toString())
            .where((content) => content.isNotEmpty));
      } else {
        throw Exception('API调用失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
  }
}