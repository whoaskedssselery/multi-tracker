import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/dio_provider.dart';
import '../storage/secure_storage.dart';

part 'groq_client.g.dart';

// ─────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────

class GroqException implements Exception {
  const GroqException(this.message, {this.code});
  final String message;
  final int? code;
  @override
  String toString() => 'GroqException($code): $message';
}

class NoApiKeyException extends GroqException {
  const NoApiKeyException() : super('Groq API key not configured');
}

// ─────────────────────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────────────────────

class ChatTurn {
  const ChatTurn({required this.role, required this.text});
  final String role; // 'user' | 'assistant'
  final String text;

  Map<String, dynamic> toJson() => {'role': role, 'content': text};
}

class GroqResponse {
  const GroqResponse({required this.text, this.finishReason = 'stop'});
  final String text;
  final String finishReason;
}

// ─────────────────────────────────────────────────────────────
// Groq client (OpenAI-compatible)
// ─────────────────────────────────────────────────────────────

class GroqClient {
  GroqClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _defaultModel = 'llama-3.3-70b-versatile';

  Future<GroqResponse> generateContent(
    String prompt, {
    List<ChatTurn> history = const [],
    String? systemInstruction,
    String? model,
  }) async {
    final key = await SecureStorageService.instance.groqApiKey;
    if (key == null || key.trim().isEmpty) throw const NoApiKeyException();

    final messages = <Map<String, dynamic>>[];
    if (systemInstruction != null) {
      messages.add({'role': 'system', 'content': systemInstruction});
    }
    messages.addAll(history.map((t) => t.toJson()));
    messages.add({'role': 'user', 'content': prompt});

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _baseUrl,
        options: Options(
          headers: {'Authorization': 'Bearer ${key.trim()}'},
        ),
        data: {
          'model': model ?? _defaultModel,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 1024,
        },
      );
      return _parse(res.data!);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg =
          (e.response?.data as Map?)?['error']?['message'] as String? ??
              e.message ??
              'Unknown error';
      throw GroqException(msg, code: status);
    }
  }

  GroqResponse _parse(Map<String, dynamic> data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const GroqException('No choices in response');
    }
    final choice = choices.first as Map<String, dynamic>;
    final raw    = choice['message']?['content'] as String? ?? '';
    final finish = choice['finish_reason'] as String? ?? 'stop';
    return GroqResponse(text: _clean(raw), finishReason: finish);
  }

  // Strip <think>…</think> blocks emitted by reasoning models (DeepSeek R1).
  static String _clean(String text) =>
      text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

@riverpod
GroqClient groqClient(GroqClientRef ref) {
  return GroqClient(dio: ref.watch(dioProvider));
}
