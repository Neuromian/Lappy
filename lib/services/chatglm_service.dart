import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:lappy/models/api_config.dart';
import 'package:rxdart/rxdart.dart';

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

  final Dio _dio = Dio();

  Future<String> sendMessage(List<ChatGLMMessage> messages) async {
    try {
      final response = await _dio.post(
        config.baseUrl,
        data: {
          'model': config.modelName,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': false,
          'temperature': 0.7,
          'top_p': 0.7,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      } else {
        throw Exception('API调用失败: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('发送消息失败: ${e.message}\n${e.response?.data ?? ""}');
    }
  }

  Future<Stream<String>> sendMessageStream(List<ChatGLMMessage> messages) async {
    try {
      final response = await _dio.post<ResponseBody>(
        config.baseUrl,
        data: {
          'model': config.modelName,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
          'temperature': 0.7,
          'top_p': 0.7,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
          responseType: ResponseType.stream,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final controller = StreamController<String>();
        final StringBuffer buffer = StringBuffer();

        response.data!.stream
            .transform(StreamTransformer<Uint8List, String>.fromHandlers(
              handleData: (data, sink) {
                try {
                  final decoded = utf8.decode(data, allowMalformed: true);
                  sink.add(decoded);
                } catch (e) {
                  print('解码错误: $e');
                  sink.addError(e);
                }
              },
            ))
            .listen(
              (chunk) {
                buffer.write(chunk);
                String currentBuffer = buffer.toString();
                final lines = currentBuffer.split('\n');
                
                if (lines.length > 1) {
                  buffer.clear();
                  buffer.write(lines.last); // 保留最后一个可能不完整的行
                  
                  for (var i = 0; i < lines.length - 1; i++) {
                    final line = lines[i];
                    if (line.trim().isEmpty) continue;
                    if (line.startsWith('data: ')) {
                      final jsonStr = line.substring(6).trim();
                      if (jsonStr == '[DONE]') {
                        controller.close();
                        return;
                      }

                      try {
                        final data = jsonDecode(jsonStr);
                        final delta = data['choices'][0]['delta'];
                        final content = (delta['content'] ?? '').toString();
                        if (content.isNotEmpty) {
                          controller.add(content);
                        }
                      } catch (e) {
                        print('JSON解析错误: $e\nJSON数据: $jsonStr');
                      }
                    }
                  }
                }
              },
              onError: (error) {
                print('流处理错误: $error');
                controller.addError(error);
              },
              onDone: () {
                controller.close();
              },
            );

        return controller.stream;
      } else {
        throw Exception('API调用失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('发送消息失败: ${e.message}\n${e.response?.data ?? ""}');
    }
  }
}